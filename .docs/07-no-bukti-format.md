# 07 — Format No Bukti

> Mirror pattern Simpus Kuta 1.

## Format

```
YYMMDD + KodeModul + # + KodeUnitBisnis + - + RunningNumber
```

## Komponen

| Bagian | Panjang | Sumber | Contoh |
|---|---|---|---|
| `YYMMDD` | 6 | tanggal transaksi | `260523` (2026-05-23) |
| `KodeModul` | 3 | hardcoded per jenis transaksi | `BSP`, `BSJ`, `BST` |
| `#` | 1 | separator | `#` |
| `KodeUnitBisnis` | 4–10 | `mUnitBisnis.NomorBukti` | `BKPSDM`, `DLH` |
| `-` | 1 | separator | `-` |
| `RunningNumber` | 6 | counter per (UnitBisnis, Modul, Tanggal) | `000001` |

## Kode Modul Bank Sampah

| Kode | Modul | Tabel Target |
|---|---|---|
| `BSP` | Bank Sampah Penerimaan (Setoran) | `BS_trSetoran` |
| `BSJ` | Bank Sampah Jual (Penjualan ke Vendor) | `BS_trPenjualan` |
| `BST` | Bank Sampah Tarik (Penarikan Saldo) | `BS_trPenarikan` |
| `BSM` | Bank Sampah Mutasi (Antar Lokasi) | (future) |
| `BSO` | Bank Sampah Opname (Stock Opname) | (future) |
| `BSA` | Bank Sampah Adjustment | (future) |

## Contoh Lengkap

```
260523BSP#BKPSDM-000001   ← setoran pertama BKPSDM tanggal 23 Mei 2026
260523BSP#BKPSDM-000002   ← setoran kedua
260523BSJ#BKPSDM-000001   ← penjualan pertama
260524BSP#BKPSDM-000001   ← reset counter ke 1 di tanggal baru
260523BSP#DLH-000001      ← setoran pertama DLH (counter beda dengan BKPSDM)
```

## Reset Counter

Counter di-reset setiap **tanggal baru per (UnitBisnis, Modul)**.

## Kenapa Format Ini?

1. **Sortable**: prefix tanggal di depan → ORDER BY string = ORDER BY tanggal.
2. **Self-explaining**: dari nomor doang udah tau OPD mana, jenis apa, tanggal kapan.
3. **Audit-friendly**: gak perlu join untuk identifikasi sumber.
4. **Pattern Simpus**: contoh existing `260108FAR#PKSA-000760` (FAR=Farmasi, PKSA=Puskesmas Kuta Satu).

## Implementasi PostgreSQL

```sql
-- Tabel counter (mirip approach Simpus tapi explicit di Postgres)
CREATE TABLE "BS_SequenceCounter" (
  "UnitBisnisID"  INT NOT NULL,
  "Kode_Modul"    VARCHAR(5) NOT NULL,
  "Tanggal"       VARCHAR(6) NOT NULL,         -- YYMMDD
  "Counter"       INT NOT NULL DEFAULT 0,
  PRIMARY KEY ("UnitBisnisID","Kode_Modul","Tanggal")
);

CREATE OR REPLACE FUNCTION "BS_GenerateNoBukti"(
  p_UnitBisnisID INT,
  p_Kode_Modul   VARCHAR
) RETURNS VARCHAR AS $$
DECLARE
  v_Tgl         VARCHAR := TO_CHAR(NOW() AT TIME ZONE 'Asia/Makassar','YYMMDD');
  v_KodeUB      VARCHAR;
  v_Counter     INT;
BEGIN
  SELECT "NomorBukti" INTO v_KodeUB
  FROM "mUnitBisnis"
  WHERE "UnitBisnisID" = p_UnitBisnisID;

  IF v_KodeUB IS NULL THEN
    RAISE EXCEPTION 'NomorBukti tidak ditemukan untuk UnitBisnisID %', p_UnitBisnisID;
  END IF;

  -- Atomic increment counter
  INSERT INTO "BS_SequenceCounter"("UnitBisnisID","Kode_Modul","Tanggal","Counter")
  VALUES (p_UnitBisnisID, p_Kode_Modul, v_Tgl, 1)
  ON CONFLICT ("UnitBisnisID","Kode_Modul","Tanggal")
  DO UPDATE SET "Counter" = "BS_SequenceCounter"."Counter" + 1
  RETURNING "Counter" INTO v_Counter;

  RETURN v_Tgl || p_Kode_Modul || '#' || v_KodeUB || '-' || LPAD(v_Counter::TEXT,6,'0');
END;
$$ LANGUAGE plpgsql;

-- Penggunaan:
-- SELECT "BS_GenerateNoBukti"(2,'BSP');  → '260523BSP#PKSA-000001'
```

## Race Condition

Function di atas atomic karena:
1. `INSERT ... ON CONFLICT DO UPDATE ... RETURNING` — single statement, atomic di Postgres.
2. Row-level lock saat update.

Aman untuk concurrent insert tanpa duplicate counter.

## Validasi Format (Regex)

```
^\d{6}(BSP|BSJ|BST|BSM|BSO|BSA)#[A-Z0-9]{2,10}-\d{6}$
```

Untuk validasi di app layer atau DB constraint:

```sql
ALTER TABLE "BS_trSetoran" ADD CONSTRAINT "chk_NoBukti_format"
CHECK ("No_Bukti" ~ '^\d{6}(BSP|BSJ|BST|BSM|BSO|BSA)#[A-Z0-9]{2,10}-\d{6}$');
```
