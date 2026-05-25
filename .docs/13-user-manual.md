# 13 — Panduan Pengguna (User Manual)

Dokumen ini menjelaskan alur operasional, antarmuka, dan instruksi penggunaan aplikasi **Bank Sampah Pegawai Pemerintah Daerah Kabupaten Badung**.

---

## 1. Peran Pengguna (User Roles)
Aplikasi ini memiliki 3 level otorisasi:
1.  **Pegawai (Nasabah):** Pegawai Pemda yang menyetor sampah, memantau riwayat saldo (Pending vs Tersedia), memantau realisasi penjualan FIFO, dan mengajukan penarikan dana.
2.  **Admin OPD (Admin Kantor/Dinas):** Staff operasional di tiap dinas/dinas yang mendaftarkan sampah, melayani setoran pegawai, melakukan penjualan ke vendor (realisasi FIFO), dan menyetujui/membayar penarikan dana staff.
3.  **Super Admin (Pemda Level):** Kepala bagian / dinas lingkungan hidup tingkat kabupaten yang dapat memantau pelaporan stok dan kinerja tabungan lintas OPD secara terpusat.

---

## 2. Alur Nasabah (Pegawai)

### 2.1 Memantau Saldo & Mutasi
*   **Menu Beranda:** Dashboard dinamis menampilkan ringkasan **Saldo Tersedia** (realized - siap ditarik) dan **Saldo Pending** (unrealized - masih ditimbun di TPS dan belum dijual ke vendor).
*   **Riwayat Setoran:** Menampilkan daftar 5 setoran sampah terakhir Anda, lengkap dengan rincian berat dan perkiraan nilai rupiah.

### 2.2 Transparansi Realisasi (Audit FIFO)
*   **Menu Laporan -> Riwayat FIFO:** Nasabah dapat melihat secara langsung kapan sampah yang mereka setorkan dijual oleh Admin ke vendor, dijual dengan harga berapa, berapa HPP-nya, dan berapa selisih margin realisasi yang menjadi hak nasabah. Ini menjamin akuntabilitas 100% bebas manipulasi.

### 2.3 Mengajukan Penarikan Saldo
1.  Buka menu **Penarikan** (klik tombol dompet di Dashboard).
2.  Pilih **Ajukan Penarikan**.
3.  Masukkan nominal yang diinginkan (tidak boleh melebihi Saldo Tersedia Anda dan harus mematuhi minimal penarikan per OPD, misal Rp 50.000).
4.  Pilih metode pembayaran: **Tunai** atau **Transfer Bank** (isi nama bank, nomor rekening, dan atas nama rekening secara valid).
5.  Klik **Kirim Pengajuan**. Status pengajuan Anda akan menjadi `PENDING`.

---

## 3. Alur Admin OPD

### 3.1 Mencatat Setoran Sampah Baru
1.  Buka menu **Setoran** (tombol plus di bilah navigasi).
2.  Pilih nama pegawai (nasabah) penyetor.
3.  Pilih lokasi TPS tempat penyimpanan sampah.
4.  Masukkan rincian jenis sampah dan beratnya (KG). Sistem akan otomatis menghitung subtotal menggunakan Master Harga Beli OPD Anda.
5.  Klik **Simpan Setoran**. Nomor bukti otomatis `YYMMDDBST#OPD-000000` akan diterbitkan, dan Saldo Pending pegawai akan bertambah seketika.

### 3.2 Melakukan Penjualan ke Vendor (Realisasi FIFO)
1.  Buka menu **Penjualan** (tombol truk di bilah navigasi).
2.  Pilih Vendor penerima dan lokasi TPS asal pengambilan sampah.
3.  Masukkan jenis sampah dan berat (KG) yang dijual. Sistem akan menampilkan sisa stok terkini di gudang Anda.
4.  Klik **Simpan Penjualan**.
5.  **Realisasi FIFO Otomatis:** Sistem database Postgres akan otomatis memecah antrean setoran tertua nasabah secara urut (FIFO), mengonversikan saldo pegawai terkait dari **Pending** menjadi **Tersedia** (realized) secara transaksional, mencatat selisih harga jual-beli, dan memperbarui buku besar kartu gudang secara instan.

### 3.3 Persetujuan & Pembayaran Penarikan
1.  Buka menu **Penarikan** (tombol dompet).
2.  Admin akan melihat daftar antrean pengajuan berstatus `PENDING`.
3.  Buka pengajuan detail, lalu klik **Setujui** (`APPROVED`) atau **Tolak** dengan menuliskan catatan alasan penolakan.
4.  Setelah disetujui, admin mentransfer dana ke rekening nasabah, lalu membuka kembali detail penarikan dan klik **Selesaikan Pembayaran** (`PAID`) dengan menyertakan tautan/foto bukti transfer.
5.  Dana didebit secara riil dari saldo nasabah saat status berubah menjadi `PAID`.

---

## 4. Fitur Multi-OPD & Super Admin

### 4.1 Branding Dinamis
*   Aplikasi mendeteksi OPD tempat pegawai login. Palet warna UI (misal: BKPSDM hijau muda, DLH hijau tua) dan logo instansi di Dashboard akan menyesuaikan identitas OPD secara otomatis tanpa perlu deployment terpisah.

### 4.2 Bulk Import Pegawai
1.  Buka menu **Master** -> tab **Pegawai**.
2.  Sebagai Admin, klik tombol **Bulk Import** di kanan atas.
3.  Tempelkan format JSON daftar pegawai yang ingin di-import:
    ```json
    [
      {
        "nama_pegawai": "Nama Pegawai",
        "nip": "199012122018041001",
        "email": "pegawai.email@badung.go.id",
        "no_telepon": "081234567890"
      }
    ]
    ```
4.  Pilih OPD tujuan, lalu klik **Import Sekarang**.
5.  Sistem akan meng-import pegawai, menginisialisasi saldo nihil, dan mengaktifkan integrasi Google OAuth secara otomatis saat pegawai login menggunakan email tersebut pertama kali.
