# 00 — Overview

## Visi

Digitalisasi proses bank sampah di lingkungan pemerintahan daerah, menggantikan flow manual (kertas → Excel → bagi tunai) dengan sistem terpusat yang **akuntabel, sinkron, dan auditable**.

## Masalah yang Dipecahkan

Flow lama (eksisting di klien):

```
Pegawai → bawa sampah ke admin → admin timbang manual
       → admin catat di Excel → Excel dibawa ke TPS
       → sampah dijual ke pengepul → uang dibagikan ke pegawai
```

Pain points:

1. **Tidak sinkron**: estimasi saldo (saat setor) sering beda dengan realisasi (saat dijual). Selisih harga gak ke-track.
2. **Manual prone-to-error**: catat di kertas, rekap di Excel, rawan typo & manipulasi.
3. **Tidak transparan**: pegawai gak tau saldo real-time. Harus tanya admin.
4. **Tidak scalable**: tiap OPD bikin Excel sendiri, format beda-beda.

## Scope MVP (Fase 1)

✅ **In Scope**:
- Master data: Pegawai, Sampah, Vendor (Pengepul), Lokasi/TPS, Harga.
- Transaksi: Setoran sampah, Penjualan ke vendor, Penarikan saldo.
- Kartu gudang: stok masuk/keluar/saldo per jenis sampah per lokasi.
- FIFO layer + alokasi selisih harga ke pegawai owner.
- Saldo pegawai 2-bucket: **Pending** (estimasi) vs **Tersedia** (realized).
- Multi-OPD via `UnitBisnisID`.
- Auth Google via Supabase.
- Audit trail lengkap.

❌ **Out of Scope (Fase 1)**:
- Integrasi SIMPEG / sistem kepegawaian lain.
- Pembayaran otomatis ke rekening (transfer manual dulu).
- Aplikasi untuk masyarakat umum.
- Dashboard analytics deep (cukup laporan basic dulu).
- Notifikasi push / email otomatis.
- Integrasi e-wallet (DANA, GoPay).
- Multi-pemda (1 deployment = 1 pemda).

## Stakeholder

| Role | Siapa | Kepentingan |
|---|---|---|
| Sponsor | BKPSDM Pemkab  | Pilot pertama, butuh tracking jelas |
| End User | Staff operasional OPD | Setor sampah, lihat saldo, tarik |
| Admin Bank Sampah | PIC tiap OPD | Input data, jual ke vendor, approval tarik |
| Super Admin | DLH/Diskominfo (future) | Konsolidasi cross-OPD |
| Auditor | Inspektorat | Audit laporan keuangan & flow |

## Aktor Teknis (Role Aplikasi)

> Definisi role disimpan di tabel `mGroup` / `mUserGroup` (pattern Simpus). Bukan hardcode.

| Role | Akses |
|---|---|
| `OPERATOR` | Input setoran, input penjualan, lihat data OPD-nya |
| `APPROVER` | Approve penarikan, approve penjualan |
| `ADMIN_OPD` | Setup master OPD, manage pegawai OPD |
| `SUPER_ADMIN` | Lintas OPD (pemda level) |
| `PEGAWAI` | Lihat saldo & history setoran sendiri, ajukan penarikan |

## Batasan Non-Fungsional

- **Bahasa**: Indonesia di UI & dokumentasi.
- **Mata uang**: IDR. Pakai `NUMERIC(14,2)`.
- **Timezone**: Asia/Makassar (WITA) — Bali.
- **Retensi data**: 10 tahun (sesuai standar pemda).
- **Skala**: 1 pemda, ~50 OPD, ~10rb pegawai, ~500 transaksi/hari (estimasi).
- **Offline**: opsional (nice to have), prioritas low di MVP karena setoran di kantor.

## Kebijakan Bisnis (Awal)

> Semua bisa di-override per OPD via `mUnitBisnis.Config` (JSONB).

- Pegawai gak bisa tarik saldo **Pending** — hanya **Tersedia**.
- Penarikan minimal **Rp 50.000** (configurable).
- Penjualan ke vendor butuh **approval** sebelum posting saldo.
- Setoran gak bisa di-VOID kalau sudah ke-realisasi sebagian → wajib pakai journal koreksi (`JTransaksi_ID = 704`).
