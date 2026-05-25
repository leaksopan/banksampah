# 10 — Supabase Setup

> Step-by-step setup Supabase project untuk dev sampai production.

## Prasyarat

- Account Supabase (gratis, free tier cukup untuk dev)
- Supabase CLI v1.x ke atas (`npm i -g supabase` atau `brew install supabase/tap/supabase`)
- Docker Desktop (untuk local dev)
- Account Google Cloud Console (untuk OAuth client)

## A. Buat Project

1. Login ke <https://supabase.com>
2. Create New Project:
   - Name: `bank-sampah-dev`
   - Region: `Southeast Asia (Singapore)` — terdekat ke Bali
   - Database password: simpan di password manager
   - Plan: Free (cukup untuk dev)
3. Tunggu provisioning ~2 menit
4. Catat:
   - Project URL: `https://xxx.supabase.co`
   - Anon Key (public)
   - Service Role Key (RAHASIA, jangan commit)

## B. Setup OAuth Google

1. Google Cloud Console → APIs & Services → OAuth consent screen
2. External, isi nama app, support email
3. Buat Credentials → OAuth 2.0 Client ID:
   - Type: Web application
   - Authorized redirect URI: `https://xxx.supabase.co/auth/v1/callback`
4. Copy Client ID & Secret
5. Supabase dashboard → Authentication → Providers → Google:
   - Enable
   - Paste Client ID & Secret
   - Tambahkan **Additional Redirect URLs** untuk dev web:
     - `http://127.0.0.1:5050`
     - `http://localhost:5050`
   - Pastikan **Site URL** tidak mengarah ke port dev lama (mis. `localhost:3000`) agar callback tidak nyasar.
   - Save

## C. Init Project Lokal

```bash
mkdir Bank_Sampah && cd Bank_Sampah
supabase init
```

Hasil:
```
Bank_Sampah/
└── supabase/
    ├── config.toml
    ├── seed.sql
    └── migrations/
```

Link ke remote project:
```bash
supabase link --project-ref xxx
```

### MCP Supabase untuk Codex

Codex membaca konfigurasi MCP dalam format TOML dengan key `mcp_servers`, bukan JSON `mcpServers`. Untuk konfigurasi lokal repo, pakai `.codex/config.toml`. File ini dapat berisi access token personal, jadi wajib masuk `.gitignore` dan tidak di-commit.

Template Codex TOML:
```toml
[mcp_servers.supabase-mcp-server]
command = "cmd.exe"
args = ["/c", "npx", "-y", "@supabase/mcp-server-supabase@latest"]
startup_timeout_sec = 60
tool_timeout_sec = 120

[mcp_servers.supabase-mcp-server.env]
SUPABASE_ACCESS_TOKEN = "ISI_ACCESS_TOKEN_LOKAL"
```

## D. Migration Strategy

### Folder Structure
```
supabase/migrations/
  ├── 20260523000001_init_master_shared.sql
  ├── 20260523000002_init_master_per_opd.sql
  ├── 20260523000003_init_transaksi_bank_sampah.sql
  ├── 20260523000004_seed_jenis_transaksi.sql
  ├── 20260523000005_functions_no_bukti.sql
  ├── 20260523000006_functions_fifo.sql
  ├── 20260523000007_triggers_kartu_gudang.sql
  ├── 20260523000008_triggers_saldo_pegawai.sql
  ├── 20260523000009_rls_policies.sql
  └── 20260523000010_seed_bkpsdm.sql
```

Catatan status 2026-05-23: struktur migration aktual di repo sudah memakai file
`20260523000100_init_auth_role_mvp.sql` sampai
`20260523000600_rpc_create_setoran_mvp.sql`. Remote project dev
`jtxquskrulvjafrusbcq` sudah terkonfirmasi memiliki 3 migration awal
auth/approval; migration `00400` sampai `00600` adalah foundation lokal berikutnya
untuk master data, transaksi inti, trigger saldo/gudang, RLS per OPD, dan RPC setoran MVP.

### Buat Migration Baru
```bash
supabase migration new init_master_shared
```

### Push ke Remote
```bash
supabase db push
```

### Reset Local DB
```bash
supabase db reset
```

## E. RLS Policies

Lihat detail di `05-multi-opd-strategy.md`. Garis besar:

```sql
-- Aktifkan RLS di semua tabel transaksi
ALTER TABLE "BS_trSetoran" ENABLE ROW LEVEL SECURITY;
-- ... dst untuk semua BS_*

-- Helper function
CREATE OR REPLACE FUNCTION "currentUserUnitBisnis"() RETURNS INT AS $$
  SELECT mp."UnitBisnisID" FROM "mPegawai" mp
  JOIN "mUser" mu ON mu."User_ID" = mp."User_ID"
  WHERE mu."Auth_UID" = auth.uid()
  LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- Policy generic
CREATE POLICY "BS_trSetoran_isolasi" ON "BS_trSetoran" FOR ALL
USING ("UnitBisnisID" = "currentUserUnitBisnis"() OR "isSuperAdmin"())
WITH CHECK ("UnitBisnisID" = "currentUserUnitBisnis"() OR "isSuperAdmin"());
```

## F. Seed Data

```sql
-- Seed jenis transaksi
INSERT INTO "mJenisTransaksi"("JTransaksi_ID","Nama_Transaksi") VALUES
  (700,'Setoran Sampah Pegawai'),
  (701,'Penjualan Sampah ke Vendor'),
  (702,'Penarikan Saldo Pegawai'),
  (703,'Realisasi Saldo Pegawai'),
  (704,'Adjustment Saldo Pegawai'),
  (705,'Pembatalan Setoran'),
  (706,'Pembatalan Penjualan'),
  (707,'Mutasi Antar Lokasi - Masuk'),
  (708,'Mutasi Antar Lokasi - Keluar'),
  (709,'Stock Opname Plus'),
  (710,'Stock Opname Minus'),
  (711,'Spoil/Rusak'),
  (712,'Setoran Awal Saldo')
ON CONFLICT ("JTransaksi_ID") DO NOTHING;

-- Seed satuan
INSERT INTO "mSatuan"("Kode_Satuan","Nama_Satuan","Satuan_Default") VALUES
  ('KG','Kilogram', TRUE),
  ('PCS','Pieces', FALSE),
  ('BTL','Botol', FALSE),
  ('LTR','Liter', FALSE)
ON CONFLICT DO NOTHING;

-- Seed kategori
INSERT INTO "mKategori"("Kode_Kategori","Nama_Kategori") VALUES
  ('ANO','Anorganik'),
  ('ORG','Organik'),
  ('B3','Bahan Berbahaya Beracun'),
  ('RES','Residu')
ON CONFLICT DO NOTHING;

-- Seed kategori vendor
INSERT INTO "mKategori_Vendor"("Kode_Kategori","Kategori_Name") VALUES
  ('PGPL','Pengepul Sampah'),
  ('PRBR','Pabrik Daur Ulang')
ON CONFLICT DO NOTHING;

-- Seed group/role
INSERT INTO "mGroup"("Kode_Group","Nama_Group","Permissions") VALUES
  ('ADMIN','Admin', '{"user.approve":true,"dashboard.read":true}'::jsonb),
  ('NASABAH','Nasabah', '{"dashboard.read":true,"saldo.read":true}'::jsonb)
ON CONFLICT DO NOTHING;

-- Seed BKPSDM (OPD pertama)
INSERT INTO "mUnitBisnis"("UnitBisnisName","Kode_OPD","Tipe_OPD","NomorBukti","Status_Aktif")
VALUES ('Badan Kepegawaian dan Pengembangan SDM','BKPSDM','BADAN','BKPSDM',TRUE)
ON CONFLICT DO NOTHING;

-- Seed sampah default (template, bisa di-copy ke OPD lain)
INSERT INTO "mSampah"("Kode_Sampah","Nama_Sampah","Kategori_ID","Kode_Satuan","Harga_Beli","Harga_Jual","UnitBisnisID")
SELECT 'BTL-PET','Botol PET', k."Kategori_ID",'KG',3000,3500, ub."UnitBisnisID"
FROM "mKategori" k, "mUnitBisnis" ub
WHERE k."Kode_Kategori"='ANO' AND ub."Kode_OPD"='BKPSDM'
ON CONFLICT DO NOTHING;

-- ... dst (Kardus, Besi, Kaca, Kertas)
```

## G. Trigger Auto-Sync `mUser.Auth_UID`

Saat user pertama login Google, Supabase auto-create row di `auth.users`. Untuk MVP, user
baru otomatis dibuat di `mUser` sebagai `PENDING`, diberi role default `NASABAH`, dan
dimapping ke OPD awal BKPSDM. User belum boleh masuk dashboard sampai admin approve
`Status_Approval='APPROVED'`.

```sql
-- Trigger AFTER INSERT auth.users → buat/link mUser pending approval
CREATE OR REPLACE FUNCTION "syncUserOnAuthCreate"() RETURNS TRIGGER AS $$
BEGIN
  -- Upsert mUser by email/Auth_UID.
  -- Default: Status_Approval='PENDING', role NASABAH, UnitBisnis BKPSDM.

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER "trg_SyncUser"
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION "syncUserOnAuthCreate"();
```

> **Pilihan kebijakan**: MVP tidak memakai whitelist. Login Google boleh membuat profil,
> tetapi profil masuk antrean approval. Bootstrap admin pertama dilakukan lewat seed email
> `admin.bkpsdm@example.com` yang wajib diganti ke email admin asli sebelum production.

## H. Storage Bucket

```sql
-- Via SQL atau dashboard
INSERT INTO storage.buckets ("id", "name", "public") VALUES
  ('bukti-bank-sampah','bukti-bank-sampah', FALSE)
ON CONFLICT DO NOTHING;
```

Policy bucket:
```sql
-- User OPD bisa upload bukti ke folder OPD-nya
CREATE POLICY "upload_bukti" ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'bukti-bank-sampah'
  AND (storage.foldername(name))[1] = "currentUserUnitBisnis"()::text
);

-- User OPD bisa baca bukti folder OPD-nya
CREATE POLICY "read_bukti" ON storage.objects FOR SELECT
USING (
  bucket_id = 'bukti-bank-sampah'
  AND (storage.foldername(name))[1] = "currentUserUnitBisnis"()::text
);
```

Konvensi path: `{UnitBisnisID}/{tipe}/{No_Bukti}.jpg`. Contoh: `2/penarikan/260523BST#BKPSDM-000001.jpg`.

## I. Environment Variable Flutter

`.env` (jangan di-commit):
```
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJxxxxx
APP_ENV=development
```

Build:
```bash
flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=eyJxxxxx \
            --dart-define=APP_ENV=development
```

## J. Backup Strategy

- Supabase auto-backup harian (Pro tier ke atas).
- Free tier: manual `pg_dump` weekly.
- Untuk production: setup point-in-time recovery (PITR).

## K. Monitoring

- Supabase dashboard → Database → Logs (query slow log)
- Supabase dashboard → Auth → Users (track sign-up)
- Edge function logs (kalau pakai)
- Optional: integrate Sentry/Logflare untuk app-level error

## L. Production Checklist

- [ ] Upgrade plan ke Pro (atau self-host)
- [ ] Enable PITR backup
- [ ] Pasang custom domain `api.banksampah.pemkabbadung.go.id` (CNAME ke Supabase)
- [ ] Audit RLS coverage (pastikan SEMUA tabel transaksi enabled RLS)
- [ ] Disable signup public (auth.signup_enabled=false)
- [ ] Whitelist domain email pemda only di OAuth settings
- [ ] Rotate database password & service role key
- [ ] Setup alert untuk error rate spike
