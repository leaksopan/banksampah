# 01 — Architecture

## High-Level Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUTTER APP                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │ Mobile (APK) │  │ Web (PWA)    │  │ Tablet       │       │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘       │
│         └─────────────────┼─────────────────┘               │
│                  Riverpod / State Layer                     │
│                  Repository Layer                           │
│                  Supabase Client SDK                        │
└──────────────────────────┬──────────────────────────────────┘
                           │ HTTPS
┌──────────────────────────┴──────────────────────────────────┐
│                    SUPABASE                                 │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐        │
│  │  Auth    │ │ Postgres │ │ Storage  │ │ Realtime │        │
│  │  (OAuth) │ │  + RLS   │ │ (Bukti)  │ │ (option) │        │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘        │
│  ┌──────────────────────────────────────────────────┐       │
│  │ PostgreSQL Functions & Triggers                  │       │
│  │  • BS_GenerateNoBukti                            │       │
│  │  • BS_PostingSetoran                             │       │
│  │  • BS_AlokasiPenjualanFifo                       │       │
│  │  • BS_SyncSaldoPegawai (trigger)                 │       │
│  │  • BS_PostingKartuGudang (trigger)               │       │
│  └──────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

## Stack Detail

### Frontend

| Aspek | Pilihan | Alasan |
|---|---|---|
| Framework | **Flutter** (latest stable) | 1 codebase mobile + web |
| Bahasa | Dart | - |
| State Mgmt | **Riverpod** | DI built-in, testable, modern |
| Navigation | **go_router** | Deep link friendly, support web |
| HTTP/DB | `supabase_flutter` | Official SDK |
| UI | **Custom + flutter_shadcn_ui** (web), **Material 3** (mobile) | Konsisten brand |
| Form | `reactive_forms` atau `flutter_form_builder` | Validasi terstruktur |
| Date | `intl` + locale `id_ID` | - |
| Money | `NumberFormat.currency(locale:'id', symbol:'Rp ')` | - |

### Backend

| Aspek | Pilihan |
|---|---|
| BaaS | **Supabase Cloud** (development) → Self-hosted (production, optional) |
| Database | PostgreSQL 15+ |
| Auth | Supabase Auth + Google OAuth |
| File Storage | Supabase Storage (foto bukti setor/jual) |
| RLS | Aktif di SEMUA tabel transaksi |
| Migrations | Supabase CLI + folder `supabase/migrations/` |

### DevOps

- **Repo**: monorepo (`/app` Flutter, `/supabase` migration).
- **CI**: GitHub Actions — `flutter test`, `flutter build`, `supabase db push`.
- **Versioning**: SemVer pada `pubspec.yaml`.

## Folder Structure (Repo Root)

```
Bank_Sampah/
├── AGENTS.md                  # Entry untuk AI agent
├── .docs/                     # Dokumentasi (single source of truth)
│   ├── README.md
│   ├── 00-overview.md
│   └── ... (lihat .docs/README.md)
├── app/                       # Flutter project
│   ├── lib/
│   ├── pubspec.yaml
│   └── ... (detail di 09-flutter-structure.md)
├── supabase/
│   ├── migrations/            # SQL migration (timestamped)
│   ├── seed.sql               # Seed master data
│   ├── functions/             # Edge functions (jika perlu)
│   └── config.toml
├── docs-assets/               # ERD, mockup, screenshot
└── README.md                  # Quickstart
```

## Layering Flutter (DDD-Lite)

```
lib/
├── core/                      # config, constants, utils, theme
├── data/                      # supabase client, models, repositories
├── domain/                    # entities, use_cases (optional, kalau kompleks)
├── features/
│   ├── auth/
│   ├── setoran/
│   ├── penjualan/
│   ├── penarikan/
│   ├── master/
│   └── dashboard/
└── main.dart
```

Detail per folder di `09-flutter-structure.md`.

## Deployment Model

### Development
- 1 Supabase project (cloud, free tier).
- 1 Flutter app.
- Database seed: BKPSDM + struktur section + jenis sampah default.

### Production (Phase 1)
- 1 Supabase project (Pro tier).
- Mobile: APK distribusi internal (atau Play Store internal track).
- Web: Vercel/Netlify (atau hosting milik pemda) → Flutter Web build.

### Production (Phase 2 — Multi-OPD scale-up)
- Database tetap 1, isolasi via `UnitBisnisID` + RLS.
- Read replica untuk laporan agregat (kalau load tinggi).
- Detail di `05-multi-opd-strategy.md`.

## Environment Variables

```
# .env (untuk Flutter via flutter_dotenv atau --dart-define)
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJxxxxx
APP_ENV=development|staging|production
DEFAULT_UNIT_BISNIS_ID=2  # BKPSDM (override per build)
```

## Keputusan Penting (ADR Singkat)

| ID | Keputusan | Alasan |
|---|---|---|
| ADR-001 | Pakai Supabase, bukan custom backend | Speed-to-MVP. RLS bawaan udah cukup. |
| ADR-002 | Naming Simpus pattern (PascalCase_Underscore) | Konsistensi dengan ekosistem klien |
| ADR-003 | FIFO Layer + Owner Tracking | Adil + audit-friendly untuk selisih |
| ADR-004 | Saldo 2-bucket (Pending vs Tersedia) | Sync requirement utama klien |
| ADR-005 | Multi-OPD via `UnitBisnisID`, bukan tenant | Sesuai instruksi user |
| ADR-006 | `mJenisTransaksi` di-extend (700+), bukan tabel baru | Reuse pattern Simpus |
