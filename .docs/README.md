# 📚 Dokumentasi Bank Sampah Pemda

Dokumentasi ini adalah **single source of truth** untuk konteks, arsitektur, dan keputusan teknis proyek.

> **Aturan**: setiap kali ada keputusan baru, update file yang relevan. Jangan biarkan dokumen out-of-sync dengan implementasi.
>
> **Kebijakan testing**: validasi bersifat risk-based, bukan wajib `flutter analyze`/`flutter test` di setiap task kecil.

## Cara Baca

1. Baru join? Baca **`00-overview.md` → `01-architecture.md` → `04-naming-convention.md`**.
2. Mau ngoding fitur baru? Baca **`02-database-schema.md` + `03-business-flow.md`**.
3. Lupa istilah? Cek **`12-glossary.md`**.

## Index Lengkap

| # | File | Topik |
|---|---|---|
| 00 | [00-overview.md](./00-overview.md) | Visi, scope, stakeholder, batasan |
| 01 | [01-architecture.md](./01-architecture.md) | Stack, folder, deployment model |
| 02 | [02-database-schema.md](./02-database-schema.md) | Skema DB lengkap + DDL |
| 03 | [03-business-flow.md](./03-business-flow.md) | Alur transaksi end-to-end |
| 04 | [04-naming-convention.md](./04-naming-convention.md) | Konvensi naming (mirror Simpus) |
| 05 | [05-multi-opd-strategy.md](./05-multi-opd-strategy.md) | Multi-instansi & isolasi |
| 06 | [06-fifo-realisasi-saldo.md](./06-fifo-realisasi-saldo.md) | Algoritma FIFO + selisih saldo |
| 07 | [07-no-bukti-format.md](./07-no-bukti-format.md) | Format nomor bukti |
| 08 | [08-jenis-transaksi.md](./08-jenis-transaksi.md) | Daftar `JTransaksi_ID` |
| 09 | [09-flutter-structure.md](./09-flutter-structure.md) | Struktur folder Flutter |
| 10 | [10-supabase-setup.md](./10-supabase-setup.md) | Setup Supabase + migration |
| 11 | [11-roadmap.md](./11-roadmap.md) | Milestone dev |
| 12 | [12-glossary.md](./12-glossary.md) | Istilah domain |

## Sumber Referensi Eksternal

- **Database Simpus Kuta 1** (MCP `Puskesmas Dev kuta 1`) — pattern enterprise yang kita follow.
- Permendagri 99/2018 dan PP 18/2016 — struktur OPD pemda.
