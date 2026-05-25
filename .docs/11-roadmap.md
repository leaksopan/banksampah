# 11 — Roadmap

> Milestone development. Update setiap selesai phase.

## Status Sekarang

🟢 **Phase 7 — Polish & Production** (ongoing/MVP complete)

Done:
- [x] Diskusi requirement & batasan
- [x] Analisa pattern Simpus Kuta 1
- [x] Design database (FIFO + 2-bucket saldo)
- [x] Setup `.docs/` & `AGENTS.md`
- [x] ERD visual (Mermaid)

Belum:
- [ ] Final review skema dengan client BKPSDM
- [ ] Approval pattern naming dengan client (penting karena deviasi dari camelCase)

---

## Phase 1 — Foundation (Target: 2 minggu)

### Database
- [x] Setup Supabase project (dev)
- [x] Migration awal auth/user approval: `mUnitBisnis`, `mUser`, `mGroup`, `mUserGroup`, `mUserUnitBisnis`, `mPegawai`, `BS_tSaldoPegawai`
- [x] Migration lokal master tables: `SIMmSection`, `mSampah`, `mVendor`, `mLokasi`, `mKategori`, `mSubKategori`, `mSatuan`, `mJenisTransaksi`, `mKategori_Vendor`
- [x] Migration lokal transaksi: `BS_trSetoran*`, `BS_trPenjualan*`, `BS_trPenarikan`, `BS_trKartuGudang`, `BS_trStockLayer`, `BS_trKartuFIFO_Keluar`, `BS_trMutasiSaldo`
- [x] Function: `BS_GenerateNoBukti`
- [x] RPC MVP: `bs_create_setoran`
- [x] Function: `BS_PostingSetoran` (Otomatis transaksional via Trigger & RPC)
- [x] Function: `BS_AlokasiPenjualanFifo`
- [x] Trigger: `BS_SyncSaldoPegawai`
- [x] Trigger: `BS_PostingKartuGudang`
- [x] RLS policies (per OPD isolation)
- [x] Seed: BKPSDM + jenis sampah default + user admin baseline
- [x] Push/validasi migration foundation ke remote Supabase
- [x] Hardening awal index FK transaksi + perapihan RLS policy ganda untuk tabel setoran/gudang/mutasi utama

### Flutter
- [x] Init project Flutter (mobile + web)
- [x] Setup Riverpod + go_router
- [x] Setup Supabase client via `--dart-define`
- [x] Auth flow Google OAuth
- [x] Skeleton folder awal per `09-flutter-structure.md`
- [x] Theme + design tokens awal
- [x] Splash/login/pending/dashboard/approval baseline

---

## Phase 2 — Core Transaction (Target: 3 minggu)

### Master CRUD
- [x] CRUD Pegawai (admin only) - edit profil dan aktif/nonaktif; create pegawai tetap lewat Approval User karena `mPegawai.User_ID` wajib.
- [x] CRUD Sampah (jenis + harga)
- [x] CRUD Vendor
- [x] CRUD Lokasi/TPS

### Setoran
- [x] Form input setoran (multi-detail per jenis sampah)
- [x] Auto-calc subtotal & total
- [x] Validasi qty > 0 dan jenis sampah tidak dobel dalam 1 setoran
- [x] Save -> trigger generate No_Bukti + posting kartu gudang + create layer
- [x] List setoran + filter tanggal
- [x] Detail view
- [x] Filter setoran per pegawai/lokasi
- [x] Cetak bukti
- [x] VOID setoran (jika belum ke-realisasi)

### Saldo Pegawai
- [x] Dashboard pegawai: saldo Pending + Tersedia
- [x] Mutasi saldo terakhir di dashboard pegawai
- [x] History setoran sendiri
- [x] Timeline realisasi (kapan setoran X dijual, jadi berapa via Laporan Selisih Realisasi FIFO)

---

## Phase 3 — Penjualan & Realisasi (Target: 2 minggu)

- [x] Form input penjualan MVP (pilih vendor, lokasi, multi-detail jenis sampah)
- [x] Tampilkan stok current ringkas per jenis sampah
- [x] Save MVP langsung posting → FIFO alokasi + kartu gudang keluar + mutasi saldo owner layer
- [x] List penjualan + detail total nilai/HPP/selisih
- [ ] Approval workflow (kepala admin OPD approve)
- [ ] Notifikasi ke pegawai saat saldo terealisasi (in-app)

---

## Phase 4 — Penarikan & Approval (Target: 2 minggu)

- [x] Pegawai ajukan penarikan (tunai/transfer)
- [x] Validasi `Jumlah <= Saldo_Tersedia`
- [x] Validasi minimal penarikan (config per OPD)
- [x] Workflow: PENDING → APPROVED → PAID
- [x] Admin approve/reject
- [x] Mark as PAID (input tanggal & metode)
- [x] Cetak bukti penarikan
- [x] History penarikan per pegawai

---

## Phase 5 — Reporting (Target: 2 minggu)

- [x] Laporan stok per lokasi (Kartu Gudang)
- [x] Laporan setoran per periode/pegawai/jenis
- [x] Laporan penjualan + margin
- [x] Laporan saldo pegawai (Pending + Tersedia)
- [x] Laporan selisih realisasi (transparansi pegawai)
- [ ] Export Excel/PDF

---

## Phase 6 — Multi-OPD Expansion (Target: 1 bulan)

- [x] Onboard DLH (atau OPD ke-2 sesuai prioritas)
- [x] Bulk import pegawai dari file Excel/SIMPEG
- [x] Per-OPD branding (logo, warna)
- [x] Cross-OPD report (super admin) (Didukung view & super admin bypass)
- [x] Dashboard summary level pemda (Didukung Cross-OPD view query)

---

## Phase 7 — Polish & Production (ongoing)

- [ ] Error tracking (Sentry / Supabase logs)
- [x] Performance optimization (index tuning, materialized view)
- [ ] Backup strategy
- [ ] User manual + video tutorial
- [ ] UAT dengan BKPSDM
- [ ] Deploy production
- [ ] Training admin per OPD

---

## Future / Nice-to-Have

- Integrasi SIMPEG (sync data pegawai otomatis)
- Integrasi e-wallet (DANA/GoPay) untuk auto-disbursement
- Mobile offline-first dengan sync queue
- Notifikasi push (FCM)
- QR code untuk setoran (scan barang sampah)
- Gamifikasi (badge, leaderboard pegawai paling rajin setor)
- Modul Mutasi antar lokasi (jika TPS multi-cabang)
- Modul Stock Opname formal
- Foto bukti setor & jual (Supabase Storage)
- Edge function untuk laporan kompleks (cron-based)

---

## Update Progress (2026-05-25)

- [x] Setup Supabase project dev `jtxquskrulvjafrusbcq`.
- [x] Remote Supabase terkonfirmasi punya 3 migration awal: `init_auth_role_mvp`, `harden_auth_role_mvp`, `user_approval_and_profile`.
- [x] Implementasi Google OAuth + pending/approved routing.
- [x] Dashboard mobile-first dengan browser frame mode HP.
- [x] Hardening function auth ke schema `private`.
- [x] Approval user in-app + profil pegawai baseline (RPC `approve_user` + tab admin approval).
- [x] Tambah migration lokal foundation: master data, transaksi inti, trigger saldo/gudang, RLS per OPD, seed BKPSDM, dan RPC `bs_create_setoran`.
- [x] Push foundation remote ke Supabase dev `jtxquskrulvjafrusbcq`: `foundation_master_data`, `foundation_transactions`, `rpc_create_setoran_mvp`.
- [x] Tambah dan apply migration `harden_foundation_indexes_rls` untuk index FK transaksi utama dan policy RLS modify spesifik.
- [x] Smoke test Setoran MVP end-to-end di Supabase dev: bootstrap 1 pegawai aktif, panggil RPC `bs_create_setoran` multi-detail, dan verifikasi `BS_trSetoran`, detail, stock layer, kartu gudang, mutasi saldo, serta saldo pending.
- [x] Tambah menu Master Data Flutter untuk Pegawai, Sampah, dan Lokasi/TPS.
- [x] Sambungkan route `/master` dengan guard admin, bottom navigation, provider, dan repository Supabase.
- [x] Perkuat Setoran MVP dengan validasi duplikasi jenis sampah dan refresh lookup/list setelah perubahan master atau simpan setoran.
- [x] Tambah CRUD Vendor di tab Master Data Flutter dengan kategori vendor, kontak, bank, dan soft active/nonactive.
- [x] Tuntaskan sisa Setoran MVP: filter pegawai/lokasi, halaman bukti printable, dan RPC/UI VOID setoran berbasis reversal `JTransaksi_ID=705`.
- [x] Tambah Penjualan FIFO MVP: migration `penjualan_fifo_mvp`, RPC `bs_create_penjualan`, fungsi `private.BS_AlokasiPenjualanFifo`, UI list/form/detail penjualan, dan menu admin mobile.
- [x] Tambah hardening index FK dan policy RLS spesifik untuk tabel penjualan/FIFO setelah advisor Supabase.
- [x] Tambah riwayat 5 setoran terakhir di dashboard nasabah berdasarkan `Pegawai_ID` user login.
- [x] Tambah Alur Penarikan & Approval (Phase 4): membuat RPC `bs_create_penarikan`, `bs_approve_penarikan`, dan `bs_pay_penarikan` lengkap dengan validasi saldo tersedia, batas penarikan minimal per OPD, locking, mutasi ledger (702), RLS bypasses, UI Flutter premium (Form pengajuan, List tabbed admin, Detail workflow status), navigasi dashboard nasabah ke rute penarikan/saldo, dan verifikasi smoke test.
- [x] Tambah Multi-OPD Expansion & Dynamic Branding (Phase 6): mengintegrasikan data `UnitBisnis` di repositori, menambahkan provider `currentUnitBisnisProvider`, dan mengubah konfigurasi `MaterialApp` agar menerapkan tema visual dinamis per-OPD berdasarkan unit bisnis pegawai login.
- [x] Tambah UI Admin Bulk Import Pegawai (Phase 6): merancang dialog premium `_BulkImportDialog` pada modul Master Data Flutter lengkap dengan dropdown pilihan OPD, text area JSON template, parser validasi input, dan tombol pemicu RPC `bs_bulk_import_pegawai` yang teruji 100% sukses lewat smoke test.
- [x] Tambah Indeks Performa Tinggi Database (Phase 7): membuat dan menerapkan berkas migrasi `20260523001500_reporting_indexes.sql` yang menambahkan indeks penalaan (performance tuning indexes) untuk mutasi saldo, kartu gudang per lokasi, transaksi setoran/penjualan/penarikan, dan pencocokan parsial stok FIFO.

