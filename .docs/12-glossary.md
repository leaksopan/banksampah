# 12 — Glossary

> Istilah domain & teknis yang dipakai di proyek ini.

## Pemerintahan & Organisasi

| Istilah | Arti |
|---|---|
| **Pemda** | Pemerintah Daerah (provinsi/kabupaten/kota) |
| **Pemkab** | Pemerintah Kabupaten |
| **OPD** | Organisasi Perangkat Daerah (Dinas, Badan, Kantor, Sekretariat, Kecamatan) |
| **Dinas** | OPD level besar yang nge-handle urusan teknis (DLH, Dinkes, Disdik) |
| **Badan** | OPD level besar untuk fungsi penunjang (BKPSDM, Bappeda, BPKAD) |
| **Kantor** | OPD level kecil (Kesbangpol, dll) |
| **UPT** | Unit Pelaksana Teknis — cabang operasional dinas |
| **Bidang** | Unit di bawah Dinas/Badan, di-handle Kepala Bidang (Eselon III) |
| **Seksi** | Unit di bawah Bidang, di-handle Kepala Seksi (Eselon IV) |
| **Sub Bagian** | Unit di Sekretariat |
| **Eselon** | Tingkatan jabatan struktural (II = Kadis, III = Kabid, IV = Kasi) |

## Singkatan OPD Umum di Pemda

| Singkatan | Kepanjangan |
|---|---|
| **BKPSDM** | Badan Kepegawaian dan Pengembangan SDM |
| **DLH** | Dinas Lingkungan Hidup |
| **Dinkes** | Dinas Kesehatan |
| **Disdik** | Dinas Pendidikan |
| **Dishub** | Dinas Perhubungan |
| **Bappeda** | Badan Perencanaan Pembangunan Daerah |
| **BPKAD** | Badan Pengelola Keuangan dan Aset Daerah |
| **Setda** | Sekretariat Daerah |
| **Inspektorat** | Pengawas internal pemda |

## Bank Sampah

| Istilah | Arti |
|---|---|
| **Bank Sampah** | Sistem pengumpulan sampah dengan mekanisme tabungan |
| **Nasabah** | Penyetor sampah (di proyek ini = pegawai) |
| **TPS** | Tempat Pembuangan Sementara |
| **TPS3R** | TPS dengan Reduce, Reuse, Recycle |
| **Pengepul** | Pembeli sampah dari bank sampah (di kita = `mVendor`) |
| **Setor** | Aksi nasabah memberi sampah ke admin |
| **Setoran** | Record transaksi setor |
| **Penjualan** | Transaksi bank sampah → vendor/pengepul |
| **Penarikan** | Pegawai cair-in saldo |
| **Saldo Pending** | Estimasi saldo dari sampah yang belum dijual |
| **Saldo Tersedia** | Saldo sudah realized (sampah sudah dijual), bisa ditarik |
| **Realisasi** | Proses konversi pending → tersedia saat sampah terjual |
| **Selisih Realisasi** | Beda nilai estimasi vs harga jual aktual (bisa + atau –) |

## Inventory & Akuntansi

| Istilah | Arti |
|---|---|
| **Kartu Gudang** | Buku besar stok per jenis × per lokasi (Qty masuk, keluar, saldo, harga) |
| **Kartu Stok** | Sinonim Kartu Gudang |
| **WAC** | Weighted Average Cost (harga rata-rata tertimbang) |
| **HPP** | Harga Pokok Penjualan |
| **HRataRata** | Kolom WAC di Simpus (`mBarang.HRataRata`) |
| **FIFO** | First In First Out — sampah yang masuk duluan, dijual duluan |
| **Layer** | Per record stok masuk yang belum habis terjual (di kita: `BS_trStockLayer`) |
| **Posting** | Aksi finalisasi transaksi → ngaruh ke buku besar |
| **Journal** | Catatan akuntansi |
| **Reversal** | Membatalkan transaksi dengan record terbalik (bukan delete) |
| **Stock Opname** | Hitung fisik stok aktual vs sistem |
| **Mutasi** | Perpindahan stok antar lokasi |

## Teknis

| Istilah | Arti |
|---|---|
| **RLS** | Row Level Security (Postgres feature, isolasi data per user) |
| **JSONB** | Tipe data Postgres untuk JSON binary (cepat, indexable) |
| **Trigger** | Function yang auto-jalan saat ada DML di tabel |
| **Stored Procedure** | Function PL/pgSQL custom |
| **Migration** | File DDL versioned untuk evolve schema |
| **Seed** | Data master awal yang di-load saat setup |
| **MCP** | Model Context Protocol (interface tool untuk AI agent) |
| **PWA** | Progressive Web App (Flutter Web bisa di-install seperti app) |
| **OAuth** | Open Authentication (Google login) |
| **JWT** | JSON Web Token (Supabase auth) |

## Konvensi Internal Proyek

| Istilah | Arti |
|---|---|
| **`UnitBisnisID`** | ID OPD di tabel master `mUnitBisnis` (reuse pattern Simpus) |
| **`Pegawai_ID`** | ID di tabel `mPegawai` (≠ `User_ID` Supabase auth) |
| **No Bukti** | Format `YYMMDDXXX#KODE-NNNNNN` (lihat `07-no-bukti-format.md`) |
| **2-stage transaction** | Pattern: Input → Posting (`Posting_KG`, `Posting_Saldo`, `Posted`) |
| **`Status_Batal`** | Soft cancel flag, transaksi tetap ada di DB tapi dianggap tidak valid |
| **Module prefix `BS_`** | Prefix tabel khusus modul Bank Sampah |
