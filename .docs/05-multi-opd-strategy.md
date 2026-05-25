# 05 — Multi-OPD Strategy

## Prinsip

**1 deployment = 1 pemda. Banyak OPD jadi data, bukan tenant.**

Pemisahan antar OPD via kolom `UnitBisnisID` di tabel transaksi & sebagian master, plus RLS Postgres untuk enforcement.

## Mengapa Bukan Tenant Pattern?

User explicit reject istilah "tenant". Selain itu:

| Aspek | Tenant Multi-DB | UnitBisnis Pattern (kita) |
|---|---|---|
| Cross-OPD report | Susah (perlu federation) | Trivial (filter `UnitBisnisID`) |
| Onboard OPD baru | Provision DB, deploy, migrate | INSERT 1 row di `mUnitBisnis` |
| Maintain | Sangat berat | Ringan |
| Data leak risk | Rendah (isolated) | Mitigated via RLS |
| Cost | Tinggi | Rendah |

Pattern ini juga sama persis dengan Simpus Kuta 1 (1 DB melayani Puskesmas + multi PUSTU via `UnitBisnisID`).

## Struktur Isolasi

### Level 1: Master Shared (TANPA `UnitBisnisID`)

Master yang berlaku universal di seluruh pemda:

- `mKategori` (kategori sampah: organik/anorganik/B3)
- `mSubKategori`
- `mSatuan` (kg, pcs, dll)
- `mJenisTransaksi`
- `mGroup` (role definitions)

> Boleh dianggap "kebijakan pemda level".

### Level 2: Master Per OPD (`UnitBisnisID NOT NULL`)

Master yang spesifik per OPD:

- `mPegawai` — pegawai BKPSDM beda dengan pegawai DLH
- `mSampah` — meskipun jenis sampah universal, harga & toggle aktif per OPD
- `mVendor` — pengepul mungkin beda per OPD
- `mLokasi` — TPS BKPSDM bukan TPS DLH

**Catatan**: `mSampah` punya 2 strategi:
- **Strategi A** (current): `mSampah.UnitBisnisID NOT NULL` — tiap OPD punya master sampah sendiri.
- **Strategi B** (alternatif): `mSampah.UnitBisnisID NULLABLE` — NULL = global, non-NULL = OPD-specific override.

> MVP pakai Strategi A. Migrasi ke B mudah jika perlu.

### Level 3: Transaksi (`UnitBisnisID NOT NULL`)

Wajib di semua tabel transaksi:

- `BS_trSetoran`, `BS_trSetoranDetail`
- `BS_trPenjualan`, `BS_trPenjualanDetail`
- `BS_trPenarikan`
- `BS_trKartuGudang`
- `BS_trStockLayer`
- `BS_trMutasiSaldo`
- `BS_trKartuFIFO_Keluar`

## RLS Implementation

### Helper Functions

```sql
-- Dapet UnitBisnisID dari user yang login
CREATE OR REPLACE FUNCTION "currentUserUnitBisnis"() RETURNS INT AS $$
  SELECT mp."UnitBisnisID"
  FROM "mPegawai" mp
  JOIN "mUser" mu ON mu."User_ID" = mp."User_ID"
  WHERE mu."Email" = (SELECT email FROM auth.users WHERE id = auth.uid())
  LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- Cek super admin (lintas OPD)
CREATE OR REPLACE FUNCTION "isSuperAdmin"() RETURNS BOOLEAN AS $$
  SELECT EXISTS(
    SELECT 1
    FROM "mUserGroup" ug
    JOIN "mUser" mu ON mu."User_ID" = ug."User_ID"
    JOIN "mGroup" g ON g."Group_ID" = ug."Group_ID"
    WHERE mu."Email" = (SELECT email FROM auth.users WHERE id = auth.uid())
      AND g."Kode_Group" = 'SUPER_ADMIN'
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- User punya akses ke OPD tertentu (bisa multi via mUserUnitBisnis)
CREATE OR REPLACE FUNCTION "userHasAccessToUnit"(p_UnitBisnisID INT) RETURNS BOOLEAN AS $$
  SELECT EXISTS(
    SELECT 1
    FROM "mUserUnitBisnis" uub
    JOIN "mUser" mu ON mu."User_ID" = uub."User_ID"
    WHERE mu."Email" = (SELECT email FROM auth.users WHERE id = auth.uid())
      AND uub."UnitBisnisID" = p_UnitBisnisID
  ) OR "isSuperAdmin"();
$$ LANGUAGE sql STABLE SECURITY DEFINER;
```

### Generic Policy (Pattern untuk Semua Tabel Transaksi)

```sql
ALTER TABLE "BS_trSetoran" ENABLE ROW LEVEL SECURITY;

-- SELECT: hanya OPD sendiri (atau super admin)
CREATE POLICY "BS_trSetoran_select" ON "BS_trSetoran" FOR SELECT
USING ("userHasAccessToUnit"("UnitBisnisID"));

-- INSERT: hanya boleh insert ke OPD yang user punya akses
CREATE POLICY "BS_trSetoran_insert" ON "BS_trSetoran" FOR INSERT
WITH CHECK ("userHasAccessToUnit"("UnitBisnisID"));

-- UPDATE: hanya OPD sendiri + belum Posted
CREATE POLICY "BS_trSetoran_update" ON "BS_trSetoran" FOR UPDATE
USING ("userHasAccessToUnit"("UnitBisnisID") AND "Posted" = FALSE)
WITH CHECK ("userHasAccessToUnit"("UnitBisnisID"));

-- DELETE: di-block total (pakai Status_Batal)
-- (no DELETE policy = no DELETE allowed)
```

Pasang policy serupa untuk semua tabel `BS_*`.

### Policy Khusus: Pegawai Lihat Saldo Sendiri

```sql
-- Pegawai cuma bisa lihat saldo & history transaksi miliknya
CREATE POLICY "BS_tSaldoPegawai_self" ON "BS_tSaldoPegawai" FOR SELECT
USING (
  "Pegawai_ID" IN (
    SELECT mp."Pegawai_ID" FROM "mPegawai" mp
    JOIN "mUser" mu ON mu."User_ID" = mp."User_ID"
    WHERE mu."Email" = (SELECT email FROM auth.users WHERE id = auth.uid())
  )
  OR "isSuperAdmin"()
  OR EXISTS (  -- atau dia admin OPD pegawai itu
    SELECT 1 FROM "mPegawai" mp
    WHERE mp."Pegawai_ID" = "BS_tSaldoPegawai"."Pegawai_ID"
      AND "userHasAccessToUnit"(mp."UnitBisnisID")
  )
);
```

## Onboarding OPD Baru (Step-by-Step)

```sql
-- 1. Insert OPD baru
INSERT INTO "mUnitBisnis" ("UnitBisnisID","UnitBisnisName","NomorBukti")
VALUES (DEFAULT, 'Dinas Lingkungan Hidup', 'DLH')
RETURNING "UnitBisnisID";  -- misal hasilnya 5

-- 2. Insert lokasi DLH
INSERT INTO "mLokasi" ("Kode_Lokasi","Nama_Lokasi","UnitBisnisID")
VALUES ('TPS-DLH-01','TPS DLH Pusat',5);

-- 3. Insert section DLH (struktur internal)
-- (sesuai struktur DLH)

-- 4. Master sampah (bisa copy dari OPD existing)
INSERT INTO "mSampah" ("Kode_Sampah","Nama_Sampah","Kategori_ID","Kode_Satuan","Harga_Beli","Harga_Jual","UnitBisnisID")
SELECT "Kode_Sampah","Nama_Sampah","Kategori_ID","Kode_Satuan","Harga_Beli","Harga_Jual",5
FROM "mSampah" WHERE "UnitBisnisID" = 2;  -- copy dari BKPSDM

-- 5. Vendor (kalau pakai vendor sama, copy juga)
-- 6. Buat akun admin DLH
-- 7. Mapping user → OPD via mUserUnitBisnis
INSERT INTO "mUserUnitBisnis" ("User_ID","UnitBisnisID") VALUES (...,5);

-- 8. Assign role
INSERT INTO "mUserGroup" ("User_ID","Group_ID") VALUES (...,?);
```

**Zero code change.** Semua via data manipulation.

## Cross-OPD Report (Super Admin)

```sql
-- Super admin bisa query lintas OPD karena RLS mereka bypass
SELECT
  ub."UnitBisnisName",
  COUNT(DISTINCT s."No_Bukti") AS jumlah_setoran,
  SUM(s."Total_Berat") AS total_berat,
  SUM(s."Total_Nilai") AS total_nilai
FROM "BS_trSetoran" s
JOIN "mUnitBisnis" ub ON ub."UnitBisnisID" = s."UnitBisnisID"
WHERE s."Tgl_Setoran" >= '2026-01-01'
  AND s."Status_Batal" = FALSE
GROUP BY ub."UnitBisnisName";
```

## Konfigurasi Per OPD

`mUnitBisnis` perlu kolom tambahan untuk konfigurasi dinamis:

```sql
ALTER TABLE "mUnitBisnis" ADD COLUMN IF NOT EXISTS "Logo_URL" TEXT;
ALTER TABLE "mUnitBisnis" ADD COLUMN IF NOT EXISTS "Warna_Primary" VARCHAR(7);
ALTER TABLE "mUnitBisnis" ADD COLUMN IF NOT EXISTS "Config" JSONB DEFAULT '{}'::jsonb;
```

Contoh `Config`:

```json
{
  "fitur": {
    "approvalPenarikan": true,
    "approvalPenjualan": true,
    "izinkanLintasLokasi": false
  },
  "kebijakan": {
    "minimalPenarikan": 50000,
    "maxPenarikanPerHari": 1000000
  },
  "branding": {
    "tagline": "Sampahmu, Tabunganmu"
  }
}
```

App layer baca `Config` saat startup dan render UI sesuai.

## Hal Penting

1. **Trigger `Status_Batal` immutable**: pasang trigger BEFORE UPDATE yang reject perubahan `UnitBisnisID` di tabel transaksi (record udah dibuat di OPD A gak boleh pindah ke B).
2. **Index `UnitBisnisID`** di setiap tabel transaksi — wajib karena hampir semua query bakal filter ini.
3. **Migration aware**: setiap kali ada DDL baru, pastikan tetap kompatibel dengan multi-OPD pattern. Tabel transaksi BARU? Wajib `UnitBisnisID NOT NULL`.
