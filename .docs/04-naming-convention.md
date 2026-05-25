# 04 — Naming Convention

> Konvensi ini **mirror Simpus Kuta 1**, bukan camelCase JS-style. Wajib diikuti di SQL & nama kolom.

## Filosofi

Kita ngikutin pattern enterprise yang battle-tested di Simpus. Tradeoff: deviasi dari user rule global "camelCase". Justifikasi: konsistensi dengan ekosistem klien & pattern SQL Server enterprise.

## Tabel

### Prefix Tabel

| Prefix | Arti | Contoh |
|---|---|---|
| `m` | Master (data referensi, jarang berubah) | `mPegawai`, `mSampah` |
| `t` / `tr` | Transaksi (data harian, append-heavy) | `tSaldoPegawai` |
| `BS_` | Module Bank Sampah | `BS_trSetoran` |
| `BS_m` | Master khusus modul Bank Sampah | (jika ada, currently belum perlu) |
| `BS_tr` | Transaksi khusus modul Bank Sampah | `BS_trPenjualan` |

### Pola Lengkap

```
[ModulPrefix]_[m|tr][Entitas]
```

Contoh:
- `mUnitBisnis` — master OPD (shared, reuse Simpus).
- `mSampah` — master jenis sampah.
- `BS_trSetoran` — transaksi setoran (header).
- `BS_trSetoranDetail` — transaksi setoran (detail).
- `BS_trKartuGudang` — kartu stock module bank sampah.

### Tabel History

Suffix `_h` atau `_History`:
- `mPegawai_h` (jika perlu track perubahan master)
- `BS_trSetoran_History`

## Kolom

### Format

**PascalCase + underscore antar kata**.

Contoh:
```
Pegawai_ID, Tgl_Setoran, No_Bukti, Total_Berat,
Harga_Beli, UnitBisnisID, Status_Batal
```

### Suffix Standar

| Suffix | Arti |
|---|---|
| `_ID` | Primary/Foreign key | `Pegawai_ID`, `Sampah_ID` |
| `_Name` / `Nama_X` | Nama deskriptif | `Nama_Sampah`, `UnitBisnisName` |
| `Tgl_X` | Tanggal | `Tgl_Setoran`, `Tgl_Update` |
| `Jam_X` | Timestamp dengan jam | `Jam_Posting` |
| `No_X` / `Nomor_X` | Nomor dokumen | `No_Bukti`, `No_Rek` |
| `Status_X` | Flag status | `Status_Batal`, `Status_Aktif` |
| `Qty_X` | Kuantitas | `Qty_Masuk`, `Qty_Keluar` |
| `Harga_X` | Nominal harga | `Harga_Beli`, `Harga_Jual` |
| `Total_X` | Akumulasi | `Total_Berat`, `Total_Nilai` |

### Audit Columns (Wajib di Tabel Transaksi)

```sql
"User_ID"        INT REFERENCES "mUser",
"Tgl_Update"     TIMESTAMPTZ DEFAULT NOW(),
"HostName"       VARCHAR(50),
"Status_Batal"   BOOLEAN DEFAULT FALSE,
"UnitBisnisID"   INT REFERENCES "mUnitBisnis"
```

### Posting Flags (Pattern Simpus)

```sql
"Posting_KG"     BOOLEAN DEFAULT FALSE,   -- Posted to Kartu Gudang
"Posting_Saldo"  BOOLEAN DEFAULT FALSE,   -- Posted to Saldo Pegawai
"Posted"         BOOLEAN DEFAULT FALSE,   -- Final posting
"Disetujui"      BOOLEAN DEFAULT FALSE,
"DisetujuiTgl"   TIMESTAMPTZ,
"DisetujuiUserID" INT REFERENCES "mUser"
```

## Tipe Data Mapping (SQL Server → Postgres)

| SQL Server (Simpus) | Postgres (kita) |
|---|---|
| `MONEY` | `NUMERIC(14,2)` |
| `BIT` | `BOOLEAN` |
| `SMALLDATETIME`, `DATETIME` | `TIMESTAMPTZ` |
| `VARCHAR(N)` | `VARCHAR(N)` (sama) |
| `IDENTITY` | `SERIAL` / `BIGSERIAL` / `GENERATED ALWAYS AS IDENTITY` |
| `NUMERIC(18,0)` (untuk ID besar) | `BIGINT` |
| `FLOAT` (untuk qty) | `NUMERIC(14,3)` (jangan FLOAT untuk presisi) |

## Naming di Flutter (Dart)

> Di Flutter pakai konvensi Dart resmi (camelCase / PascalCase Class), **bukan** ngikutin SQL.

```dart
// Class — PascalCase
class SetoranSampah { ... }

// Property — camelCase, SAMA persis dengan kolom DB tapi camelCase
class SetoranSampah {
  final String noBukti;          // No_Bukti
  final DateTime tglSetoran;     // Tgl_Setoran
  final int pegawaiId;           // Pegawai_ID
  final double totalBerat;       // Total_Berat
  final num totalNilai;          // Total_Nilai
}
```

Mapping di repository layer:
```dart
factory SetoranSampah.fromMap(Map<String, dynamic> m) => SetoranSampah(
  noBukti: m['No_Bukti'],
  tglSetoran: DateTime.parse(m['Tgl_Setoran']),
  pegawaiId: m['Pegawai_ID'],
  totalBerat: (m['Total_Berat'] as num).toDouble(),
  totalNilai: m['Total_Nilai'],
);
```

## Naming Function PostgreSQL

```
[ModulPrefix]_[VerbObject]
```

Contoh:
- `BS_GenerateNoBukti`
- `BS_PostingSetoran`
- `BS_AlokasiPenjualanFifo`
- `BS_SyncSaldoPegawai` (trigger function)

## Naming Index

```
idx_[Tabel]_[Kolom1]_[Kolom2]
```

Contoh:
- `idx_BS_Setoran_Pegawai_Tgl`
- `idx_BS_Layer_Active` (partial index)

## Naming Constraint

```
[Tabel]_[Tipe]_[Kolom]
```

| Tipe | Contoh |
|---|---|
| Primary Key | `BS_trSetoran_pkey` (auto Postgres) |
| Foreign Key | `BS_trSetoran_Pegawai_ID_fkey` (auto) |
| Unique | `BS_trSetoran_NoBukti_unique` |
| Check | `BS_trPenarikan_Jumlah_check` |

## Aturan Quoting di SQL

Karena kita pakai mixed-case + underscore, **WAJIB** quote semua identifier di Postgres:

```sql
-- ✅ BENAR
SELECT "No_Bukti", "Tgl_Setoran" FROM "BS_trSetoran"
WHERE "Pegawai_ID" = 1;

-- ❌ SALAH (Postgres bakal lowercase)
SELECT No_Bukti, Tgl_Setoran FROM BS_trSetoran
WHERE Pegawai_ID = 1;
```

> **Catatan**: ini pattern Postgres yang case-sensitive saat di-quote. Konsekuensinya tiap query di Flutter Dart harus pakai literal string ber-quote. Repository layer yang handle ini.
