# 08 — Jenis Transaksi (`JTransaksi_ID`)

> Master `mJenisTransaksi` di-extend, **bukan** bikin tabel baru. Kita reuse ID range 700+ supaya gak nabrak existing Simpus.

## Existing Simpus (Referensi, jangan diubah)

| ID | Nama | Modul |
|---|---|---|
| 201 | Piutang | Keuangan |
| 205 | Nota Debit | - |
| 206 | Nota Kredit | - |
| 402 | Penyesuaian Tambah | Inventory |
| 403 | Penyesuaian Kurang | Inventory |
| 405 | Retur Pembelian | Pembelian |
| 406 | Nota Debit | - |
| 500 | Beginning Stock | Inventory |
| 501 | Penerimaan | Pembelian |
| 502 | Penyesuaian Kurang (deprecated) | - |
| 512 | Hasil Perakitan (deprecated) | - |
| 520 | Mutation In | Mutasi |
| 521 | Mutation Out | Mutasi |
| 530 | Pos Kerugian (deprecated) | - |
| 540 | Request Delivery | Distribusi |
| 550 | Portioning | Inventory |
| 562 | Retur | - |
| 563 | Pemakaian | - |
| 564 | Penjualan | Penjualan |
| 566 | Retur Mutasi | Mutasi |

## Range Bank Sampah (700–799)

| ID | Nama | Trigger Pengaruh |
|---|---|---|
| **700** | Setoran Sampah Pegawai | + KartuGudang Masuk; +Saldo Pending |
| **701** | Penjualan Sampah ke Vendor | – KartuGudang Keluar; –Pending, +Tersedia (FIFO) |
| **702** | Penarikan Saldo Pegawai | –Saldo Tersedia |
| **703** | Realisasi Saldo Pegawai | (sub-event 701, optional dipisah) |
| **704** | Adjustment Saldo Pegawai | ±Pending atau ±Tersedia (manual) |
| **705** | Pembatalan Setoran | Reversal 700 |
| **706** | Pembatalan Penjualan | Reversal 701 |
| **707** | Mutasi Antar Lokasi (Masuk) | + KartuGudang Masuk |
| **708** | Mutasi Antar Lokasi (Keluar) | – KartuGudang Keluar |
| **709** | Stock Opname Plus | + KartuGudang (penyesuaian +) |
| **710** | Stock Opname Minus | – KartuGudang (penyesuaian –) |
| **711** | Spoil/Rusak | – KartuGudang Keluar |
| **712** | Setoran Awal Saldo (manual) | +Saldo Tersedia (utk migrasi data lama) |

## Seed Data

```sql
INSERT INTO "mJenisTransaksi"("JTransaksi_ID","Nama_Transaksi") VALUES
  (700, 'Setoran Sampah Pegawai'),
  (701, 'Penjualan Sampah ke Vendor'),
  (702, 'Penarikan Saldo Pegawai'),
  (703, 'Realisasi Saldo Pegawai'),
  (704, 'Adjustment Saldo Pegawai'),
  (705, 'Pembatalan Setoran'),
  (706, 'Pembatalan Penjualan'),
  (707, 'Mutasi Antar Lokasi - Masuk'),
  (708, 'Mutasi Antar Lokasi - Keluar'),
  (709, 'Stock Opname Plus'),
  (710, 'Stock Opname Minus'),
  (711, 'Spoil/Rusak'),
  (712, 'Setoran Awal Saldo')
ON CONFLICT ("JTransaksi_ID") DO NOTHING;
```

## Effect Matrix

Tabel referensi untuk implementasi function posting.

| `JTransaksi_ID` | Kartu Gudang | Saldo Pending | Saldo Tersedia |
|---|---|---|---|
| 700 (Setoran) | Qty_Masuk + | + (kredit) | – |
| 701 (Penjualan) | Qty_Keluar + | – (debit) | + (kredit, sebesar nilai aktual) |
| 702 (Penarikan) | – | – | – (debit) |
| 704 (Adjustment) | – | + atau – | + atau – |
| 705 (Batal Setoran) | Qty_Keluar + (reversal) | – (reversal) | – |
| 706 (Batal Penjualan) | Qty_Masuk + (reversal) | + (reversal) | – (reversal) |
| 707 (Mutasi Masuk) | Qty_Masuk + | – | – |
| 708 (Mutasi Keluar) | Qty_Keluar + | – | – |
| 709 (Opname +) | Qty_Masuk + | – | – |
| 710 (Opname –) | Qty_Keluar + | – | – |
| 711 (Spoil) | Qty_Keluar + | – | – |
| 712 (Setoran Awal) | – | – | + (kredit) |

## Aturan Implementasi

1. **Tiap insert ke `BS_trKartuGudang` HARUS punya `JTransaksi_ID`** dari list di atas.
2. **Tiap insert ke `BS_trMutasiSaldo` HARUS punya `JTransaksi_ID`** dari list di atas.
3. **Reversal pakai ID khusus** (705, 706), jangan UPDATE/DELETE record asli.
4. **Adjustment manual (704)** wajib isi `Keterangan` (NOT NULL constraint di app layer).
5. Kalau perlu jenis transaksi baru, **alokasi di range 720–799** dan update file ini + seed migration.
