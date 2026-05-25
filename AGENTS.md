# AGENTS.md — Bank Sampah Pemda
never run flutter analyze unless i told you so
do not ever do anything flutter test jsut focus on coding unless i told you so


> Entry point untuk AI agent (Kiro, Copilot, dll) yang ngerjain proyek ini. 
> Selalu gunakan MCP supabase dan ke Project ID/ref: jtxquskrulvjafrusbcq
> **Selalu baca file ini dulu sebelum mulai ngoding.** Detail lebih dalam ada di `.docs/`.

---

## 1. Konteks Proyek (TL;DR)

Aplikasi **Bank Sampah Pegawai Pemerintah Daerah Kabupaten Badung**.

- **Client awal**: BKPSDM (Badan Kepegawaian dan Pengembangan SDM).
- **Target user**: Staff operasional di setiap OPD (Dinas/Badan/Kantor/Kecamatan).
- **End-state**: Multi-OPD dalam 1 pemda — BKPSDM dulu, expand ke DLH, Dinkes, dll.
- **Use case inti**: Pegawai setor sampah ke admin → sampah ditimbun di TPS → admin jual ke vendor → saldo pegawai realized → pegawai bisa tarik tunai/transfer.

**Bukan** aplikasi untuk masyarakat umum. Bukan multi-pemda (1 deployment = 1 pemda).

---

## 2. Stack & Tooling

| Aspek | Pilihan |
|---|---|
| Framework | Flutter (mobile + web dari 1 codebase) |
| Backend | Supabase (PostgreSQL + Auth + Storage + RLS) |
| Auth | Google OAuth via Supabase |
| State Mgmt | (TBD — kemungkinan Riverpod) |
| UI Library | ShadCN-equivalent untuk Flutter / shadcn untuk web jika perlu |
| Database | PostgreSQL (Supabase managed) |
| Pattern Referensi | **Simpus Kuta 1** (SQL Server enterprise puskesmas Badung) |

---

## 3. Aturan Eksekusi untuk Agent

### Wajib

1. **Baca `.docs/` sebelum kerja**. Kalau context hilang, baca ulang `.docs/README.md`.
2. **Ikuti naming convention Simpus** (PascalCase + underscore, bukan camelCase polos). Detail di `.docs/04-naming-convention.md`.
3. **Bahasa Indonesia** untuk semua dokumentasi, komentar code boleh EN bila istilah teknis.
4. **Minim hardcode**. Konfigurasi pakai master table atau JSONB config.
5. **Audit trail wajib** di setiap transaksi (`User_ID`, `Tgl_Update`, `HostName`, `Status_Batal`).
6. **Soft delete** (`Status_Batal`, `Aktif`), bukan hard delete.
7. **Transaksi 2-stage**: input → posting. Field `Posting_KG`, `Posting_Saldo`, `Posted`.
8. **Update `.docs/` setiap kali ada keputusan arsitektur baru**. Konsistensi dokumen prioritas.

### Validasi & Testing (Pragmatis)

1. **Tidak wajib** menjalankan `flutter analyze` / `flutter test` di **setiap** task kecil.
2. Testing lengkap dijalankan untuk perubahan **berisiko menengah-tinggi** (routing, auth, transaksi, schema, state shared).
3. Untuk perubahan minor UI/copy/docs, cukup smoke check cepat di layar terkait.
4. Jika test suite berat/lama, jalankan subset paling relevan dulu dan catat scope yang belum dites.

### Larangan

1. Jangan create tabel baru tanpa cek apakah pattern-nya sudah ada di Simpus referensi.
2. Jangan hard-code role/permission/jenis sampah/jenis transaksi — semua via master table.
3. Jangan UPDATE/DELETE record transaksi yang sudah `Posted=1`. Pakai reversal pattern.
4. Jangan pakai FLOAT untuk uang. `MONEY` (SQL Server) / `NUMERIC(14,2)` (Postgres).
5. Jangan deviasi dari konvensi Simpus tanpa update `.docs/04-naming-convention.md` + alasan.

---

## 4. Quick Index `.docs/`

| File | Isi |
|---|---|
| `00-overview.md` | Visi, scope, stakeholder, batasan |
| `01-architecture.md` | Stack, folder structure, deployment model |
| `02-database-schema.md` | Skema database lengkap (DDL final) |
| `03-business-flow.md` | Alur setor → jual → realisasi → tarik |
| `04-naming-convention.md` | Aturan naming (mirror Simpus) |
| `05-multi-opd-strategy.md` | Multi-instansi, RLS, isolasi data |
| `06-fifo-realisasi-saldo.md` | Algoritma FIFO layer + alokasi selisih |
| `07-no-bukti-format.md` | Format nomor bukti (pattern Simpus) |
| `08-jenis-transaksi.md` | Mapping `JTransaksi_ID` (700–706) |
| `09-flutter-structure.md` | Struktur folder Flutter & layering |
| `10-supabase-setup.md` | Setup Supabase project & migration |
| `11-roadmap.md` | Milestone & prioritas development |
| `12-glossary.md` | Istilah domain (OPD, BKPSDM, TPS, dll) |

---

## 5. Alur Kerja Saat Development

1. **Sebelum mulai task**: baca file `.docs/` yang relevan dengan task.
2. **Saat eksekusi**: ikuti pattern yang sudah didefinisikan. Kalau ada ambiguitas, tanya user atau flag sebagai asumsi.
3. **Setelah selesai**: update file `.docs/` yang terkait (kalau ada perubahan arsitektur/pattern).
4. **Commit message**: bahasa Indonesia, prefix `[modul]` (e.g. `[setoran] tambah validasi qty minimal`).

---

## 6. Status Proyek

**Fase**: Phase 1 / Foundation Database.

Sudah ada:
- Codebase Flutter awal dengan Google OAuth, pending approval, dashboard mobile-first, dan approval user.
- Supabase project dev `jtxquskrulvjafrusbcq`.
- Remote migration awal: `init_auth_role_mvp`, `harden_auth_role_mvp`, `user_approval_and_profile`.
- Migration lokal foundation untuk master data, transaksi inti, RLS, trigger saldo/gudang, dan RPC `bs_create_setoran`.

Masih dikerjakan:
- Push/validasi migration foundation ke remote Supabase jika belum diterapkan.
- UI operasional setoran, penjualan, penarikan, master data, dan laporan.
- FIFO penjualan penuh (`BS_AlokasiPenjualanFifo`) setelah setoran MVP stabil.

Lihat `.docs/11-roadmap.md` untuk milestone berikutnya.
