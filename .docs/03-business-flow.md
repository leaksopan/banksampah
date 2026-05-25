# 03 â€” Business Flow

> Alur bisnis end-to-end dari setoran hingga penarikan saldo.

## High-Level Flow

1. Pegawai setor sampah ke admin/operator.
2. Admin mencatat setoran dan saldo user masuk ke `Pending`.
3. Admin kumpulkan stok lalu jual ke vendor.
4. Saat penjualan diposting, saldo `Pending` pindah ke `Tersedia` (FIFO).
5. Pegawai ajukan penarikan dari saldo `Tersedia`.
6. Admin approve dan bayar penarikan.

## Flow 0: Approval User (Pre-Transaksi)

**Trigger**: User baru login Google dan status masih `PENDING`.

**Aktor**: Admin OPD.

1. Admin buka menu Approval User.
2. Sistem tampilkan daftar user dengan `Status_Approval='PENDING'`.
3. Admin buka detail user.
4. Admin pilih role target: `NASABAH` atau `ADMIN`.
5. Admin lengkapi profil pegawai minimal (Nama Pegawai, NIP opsional, No Telepon opsional).
6. Admin klik Approve.
7. Sistem jalankan RPC `approve_user`:
   a. Update `mUser.Status_Approval='APPROVED'`.
   b. Isi `Approved_Tgl` dan `Approved_User_ID`.
   c. Assign role di `mUserGroup`.
   d. Upsert `mPegawai`.
   e. Ensure saldo baseline di `BS_tSaldoPegawai`.
8. User dapat login ke dashboard sesuai role.

## Persona

| Aktor | Role |
|---|---|
| **Pegawai** | Setor sampah, lihat saldo, ajukan tarik. Tidak input data sendiri (cuma view). |
| **Operator** | Petugas yang catat setoran di kantor (timbang + input). |
| **Admin OPD** | Kelola master OPD-nya, jual ke vendor, approve penarikan. |
| **Approver** | Pejabat yang approve penjualan & penarikan (jika butuh). |
| **Super Admin** | Lintas OPD, biasanya level pemda/Diskominfo. |

## Flow 1: Setoran Sampah

**Trigger**: Pegawai datang ke kantor bawa sampah.

**Aktor**: Operator (yang input), Pegawai (yang setor).

```
1. Pegawai datang dengan sampah (sudah dipisah per jenis)
2. Operator buka aplikasi â†’ menu Setoran Baru
3. Operator pilih Pegawai (search by NIP/nama)
4. Operator pilih Lokasi/TPS
5. Operator timbang sampah jenis pertama (misal Botol PET = 10kg)
6. Operator input: pilih jenis sampah â†’ input qty â†’ harga otomatis terisi dari mSampah.Harga_Beli
7. Subtotal auto-calc (qty Ã— harga)
8. Operator ulangi untuk jenis sampah lainnya
9. Operator klik SIMPAN
10. Sistem:
    a. Generate No_Bukti (BSP)
    b. INSERT BS_trSetoran + BS_trSetoranDetail
    c. Buat BS_trStockLayer per detail
    d. INSERT BS_trKartuGudang (Qty_Masuk per detail)
    e. INSERT BS_trMutasiSaldo (Pending_Kredit)
    f. Update BS_tSaldoPegawai (auto via trigger)
11. Cetak/tampilkan bukti setoran (No_Bukti, total berat, total nilai estimasi)
12. Pegawai lihat saldo Pending bertambah
```

**Field input**:
- Pegawai (required, dropdown searchable)
- Lokasi (required, dropdown)
- Tanggal (default now, editable)
- Detail: Sampah, Qty, Harga (auto-fill, editable jika ada otorisasi)
- Keterangan (optional)

**Validasi**:
- Qty > 0
- Pegawai aktif
- Lokasi aktif
- Sampah aktif & punya harga berlaku

**Hasil**:
- `Posted=TRUE`, `Posting_KG=TRUE`, `Posting_Saldo=TRUE`
- Saldo Pending pegawai bertambah sebesar `Total_Nilai`

### VOID Setoran MVP

Setoran hanya boleh di-VOID oleh admin/operator OPD jika belum pernah masuk proses FIFO penjualan:

- `Status_Batal=FALSE`.
- Semua layer dari setoran masih utuh (`BS_trStockLayer.Qty_Sisa = Qty_Awal`).
- Belum ada baris `BS_trKartuFIFO_Keluar` yang memakai layer setoran tersebut.

Efek VOID memakai reversal, bukan hard delete:

- Header `BS_trSetoran.Status_Batal` diset `TRUE` dengan audit `User_ID`, `Tgl_Update`, dan `HostName`.
- Insert `BS_trKartuGudang` dengan `JTransaksi_ID=705` dan `Qty_Keluar` sebesar qty detail.
- Insert `BS_trMutasiSaldo` dengan `JTransaksi_ID=705` dan `Pending_Debit=Total_Nilai`.
- Layer setoran ditutup (`Status='EXHAUSTED'`, `Qty_Sisa=0`) supaya tidak bisa dipakai FIFO berikutnya.

## Flow 2: Penjualan ke Vendor (Realisasi)

**Trigger**: Stok di TPS sudah cukup banyak, admin OPD jual ke pengepul.

**Aktor**: Admin OPD (input), Approver (approve jika required).

```
1. Admin OPD buka menu Penjualan Baru
2. Pilih Vendor (search by kode/nama)
3. Pilih Lokasi/TPS
4. Tampilkan stok current per jenis sampah di lokasi tsb
5. Admin pilih jenis sampah yang dijual + input qty + input harga jual aktual
6. Subtotal & total auto-calc
7. Admin klik SIMPAN sebagai DRAFT (Posted=FALSE, Disetujui=FALSE)
8. Approver review â†’ klik APPROVE
9. Sistem (saat APPROVE & POSTING):
    a. Validasi stok cukup per jenis
    b. UNTUK setiap detail:
       - Call BS_AlokasiPenjualanFifo()
       - Loop layer ACTIVE FIFO â†’ potong sesuai qty
       - INSERT BS_trKartuFIFO_Keluar per layer
       - INSERT BS_trMutasiSaldo (Pending_Debit, Tersedia_Kredit) per layer ke owner pegawai
       - UPDATE Layer status
    c. INSERT BS_trKartuGudang (Qty_Keluar per detail)
    d. UPDATE header (Total_HPP, Total_Selisih)
    e. SET Posted=TRUE, Posting_KG=TRUE, Posting_Saldo=TRUE
10. Cetak bukti penjualan
11. Pegawai owner layer otomatis terima realisasi:
    - Saldo Pending turun
    - Saldo Tersedia naik (sebesar nilai aktual jual, bisa < estimasi)
12. (Optional) Notifikasi push ke pegawai: "Sampah lo terjual, saldo bertambah X"
```

**Field input**:
- Vendor (required)
- Lokasi (required)
- Tanggal
- Detail: Sampah, Qty, Harga Jual aktual
- Type Pembayaran (Cash/Transfer)
- Keterangan

**Validasi**:
- Stok cukup per jenis sampah
- Vendor aktif
- Approval (jika diaktifkan di config OPD)

**Keputusan MVP (2026-05-23)**:
- Penjualan vendor Phase 3 awal memakai alur admin langsung `Disetujui=TRUE` dan
  `Posted=TRUE` saat simpan.
- RPC `bs_create_penjualan` menjalankan posting atomik: generate `BSJ`, insert header
  dan detail, potong layer FIFO, insert kartu gudang keluar, insert mutasi saldo, lalu
  update total nilai/HPP/selisih.
- Approval formal `DRAFT -> PENDING_APPROVAL -> APPROVED -> POSTED` tetap target
  lanjutan dan belum menjadi blocking untuk realisasi saldo MVP.

**Edge case**:
- Stok kurang â†’ reject dengan pesan "Stok X kg, butuh Y kg"
- Multiple owner di stok â†’ FIFO otomatis distribusi selisih

## Flow 3: Penarikan Saldo

**Trigger**: Pegawai mau cairin saldo Tersedia.

**Aktor**: Pegawai (ajukan), Admin OPD (approve & bayar).

```
1. Pegawai buka aplikasi â†’ menu Saldo Saya
2. Lihat Saldo Pending & Tersedia
3. Klik "Tarik Saldo"
4. Input jumlah (validasi: â‰¤ Saldo Tersedia, â‰¥ minimal config OPD)
5. Pilih metode (Cash/Transfer)
6. Jika Transfer: pilih rekening (default dari mPegawai, atau input baru)
7. Submit (Status=PENDING)
8. Notifikasi ke Admin OPD
9. Admin OPD review:
    - Klik APPROVE (Status=APPROVED, Disetujui=TRUE)
    - Atau REJECT dengan keterangan (Status=REJECTED, Posting_Saldo gak berubah)
10. Admin OPD bayar (Cash di kantor / Transfer manual)
11. Admin OPD klik MARK AS PAID:
    - Input Tgl_Bayar, Bukti_Transfer_URL (upload screenshot)
    - INSERT BS_trMutasiSaldo (Tersedia_Debit, JTransaksi_ID=702)
    - UPDATE Status=PAID, Posting_Saldo=TRUE
12. Pegawai lihat saldo Tersedia berkurang, history penarikan ter-update
```

**Field input**:
- Jumlah (required, > 0, â‰¤ saldo, â‰¥ min config)
- Type Pembayaran
- No_Rek, Nama_Bank, Atas_Nama (jika Transfer)
- Keterangan (optional)

**Validasi**:
- Saldo cukup
- Tidak ada penarikan PENDING lain (configurable: boleh 1 PENDING saja)
- Minimal sesuai config OPD

**Status Lifecycle**:
```
PENDING â†’ APPROVED â†’ PAID
   â”‚         â”‚
   â””â”€â†’ REJECTED
```

## Flow 4: Master Data CRUD

### Sampah
- Admin OPD CRUD `mSampah` per OPD-nya.
- Update harga â†’ otomatis log ke `mSampah_ChangePrice` (via trigger).
- Harga update gak ngaruh ke layer existing (snapshot di Layer.Harga_Beli).

### Vendor
- Admin OPD CRUD `mVendor` per OPD-nya.
- Bisa duplicate vendor antar OPD (gpp).

### Lokasi
- Admin OPD CRUD `mLokasi` per OPD-nya.
- TPS, gudang, kantor.

### Pegawai
- Admin OPD CRUD `mPegawai` per OPD-nya.
- Bulk import (Excel) â€” Phase 6.
- Pegawai baru otomatis dibuatkan row `BS_tSaldoPegawai` (Pending=0, Tersedia=0).

## Flow 5: Reporting

### Dashboard Pegawai (per individu)
- Card: Saldo Pending, Saldo Tersedia, Total Setoran (kg), Total Ditarik
- Chart: Setoran per bulan (3 bulan terakhir)
- List: 5 setoran terakhir
- List: Realisasi terakhir (kapan setoran X dijual, jadi berapa)

### Dashboard Admin OPD
- Card: Stok per jenis sampah (top 5 by berat)
- Card: Setoran hari ini, minggu ini, bulan ini
- Card: Penjualan terakhir + total margin
- Card: Penarikan PENDING approval

### Laporan
- Kartu Gudang per Sampah per Lokasi (range tanggal)
- Setoran per Pegawai (range tanggal)
- Penjualan per Vendor (range tanggal)
- Selisih Realisasi per Pegawai (transparansi)
- Saldo Per Pegawai (snapshot)

### Cross-OPD (Super Admin)
- Total setoran agregat per OPD
- Top 10 pegawai paling rajin setor (lintas OPD)
- Total nilai realisasi per OPD

## State Diagram: Setoran

```
[NEW] â”€â”€saveâ”€â”€> [POSTED]
                  â”‚
                  â”œâ”€ada penjualan FIFOâ”€â”€> [PARTIAL_REALIZED] â”€â”€semua terjualâ”€â”€> [FULL_REALIZED]
                  â”‚
                  â””â”€void(blm jual)â”€â”€> [VOIDED]
```

## State Diagram: Penjualan

```
[DRAFT] â”€â”€submitâ”€â”€> [PENDING_APPROVAL] â”€â”€approveâ”€â”€> [APPROVED] â”€â”€postingâ”€â”€> [POSTED]
   â”‚                                                                          â”‚
   â””â”€â”€cancelâ”€â”€â”€â”€â”€> [CANCELED]                                                 â””â”€â”€voidâ”€â”€> [VOIDED]
```

## State Diagram: Penarikan

```
[PENDING] â”€â”€approveâ”€â”€> [APPROVED] â”€â”€payâ”€â”€> [PAID]
    â”‚                       â”‚
    â””â”€â”€rejectâ”€â”€> [REJECTED] â””â”€â”€rejectâ”€â”€> [REJECTED]
```

## Hal Penting

1. **Pegawai gak bisa input setoran sendiri** di MVP. Harus via Operator. Mencegah fraud (pegawai input qty besar palsu).
2. **Pengakuan saldo Tersedia hanya saat Penjualan APPROVED & POSTED.** Penjualan DRAFT gak ngaruh ke saldo.
3. **Setoran lama yang ke-realisasi sebagian** gak bisa di-VOID â€” harus pakai Adjustment manual.
4. **Penarikan gak bisa di-VOID** kalau Status=PAID. Kalau salah bayar, pakai Adjustment (704).
5. **Approval workflow** opsional per OPD (config). Default: ON untuk Penjualan & Penarikan.

