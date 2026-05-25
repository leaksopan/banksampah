ALTER TABLE "mUnitBisnis"
  ADD COLUMN IF NOT EXISTS "Alamat" VARCHAR(200),
  ADD COLUMN IF NOT EXISTS "Phone" VARCHAR(50),
  ADD COLUMN IF NOT EXISTS "Email" VARCHAR(100),
  ADD COLUMN IF NOT EXISTS "PenanggungJawab" VARCHAR(100),
  ADD COLUMN IF NOT EXISTS "Logo_URL" TEXT,
  ADD COLUMN IF NOT EXISTS "Warna_Primary" VARCHAR(7),
  ADD COLUMN IF NOT EXISTS "Config" JSONB NOT NULL DEFAULT '{}'::jsonb;

CREATE TABLE IF NOT EXISTS "SIMmSection" (
  "SectionID"         VARCHAR(10) PRIMARY KEY,
  "SectionName"       VARCHAR(100) NOT NULL,
  "ParentSectionID"   VARCHAR(10) REFERENCES "SIMmSection"("SectionID"),
  "Tipe_Section"      VARCHAR(30),
  "Level"             SMALLINT,
  "Path"              TEXT,
  "PenanggungJawab"   VARCHAR(100),
  "UnitBisnisID"      INT NOT NULL REFERENCES "mUnitBisnis"("UnitBisnisID"),
  "StatusAktif"       BOOLEAN NOT NULL DEFAULT TRUE,
  "NoUrut"            INT NOT NULL DEFAULT 0,
  "Tgl_Update"        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS "idx_SIMmSection_Parent" ON "SIMmSection"("ParentSectionID");
CREATE INDEX IF NOT EXISTS "idx_SIMmSection_Unit" ON "SIMmSection"("UnitBisnisID");
CREATE INDEX IF NOT EXISTS "idx_SIMmSection_Path" ON "SIMmSection"("Path" text_pattern_ops);

CREATE TABLE IF NOT EXISTS "mKategori" (
  "Kategori_ID"       SERIAL PRIMARY KEY,
  "Kode_Kategori"     VARCHAR(15) UNIQUE NOT NULL,
  "Nama_Kategori"     VARCHAR(50) NOT NULL,
  "Status_Aktif"      BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS "mSubKategori" (
  "SubKategori_ID"    SERIAL PRIMARY KEY,
  "Kategori_ID"       INT NOT NULL REFERENCES "mKategori"("Kategori_ID"),
  "Kode_Sub_Kategori" VARCHAR(15) NOT NULL,
  "Nama_Sub_Kategori" VARCHAR(50) NOT NULL,
  "Status_Aktif"      BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE ("Kategori_ID", "Kode_Sub_Kategori")
);

CREATE TABLE IF NOT EXISTS "mSatuan" (
  "Kode_Satuan"       VARCHAR(10) PRIMARY KEY,
  "Nama_Satuan"       VARCHAR(20) NOT NULL,
  "Satuan_Default"    BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS "mJenisTransaksi" (
  "JTransaksi_ID"     INT PRIMARY KEY,
  "Nama_Transaksi"    VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS "mKategori_Vendor" (
  "Kode_Kategori"     VARCHAR(10) PRIMARY KEY,
  "Kategori_Name"     VARCHAR(100) NOT NULL,
  "Status_Aktif"      BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS "mLokasi" (
  "Lokasi_ID"         SERIAL PRIMARY KEY,
  "Kode_Lokasi"       VARCHAR(30) UNIQUE NOT NULL,
  "Nama_Lokasi"       VARCHAR(100) NOT NULL,
  "Tipe_Lokasi"       VARCHAR(30),
  "Alamat"            TEXT,
  "Latitude"          NUMERIC(10,7),
  "Longitude"         NUMERIC(10,7),
  "UnitBisnisID"      INT NOT NULL REFERENCES "mUnitBisnis"("UnitBisnisID"),
  "Gudang_Utama"      BOOLEAN NOT NULL DEFAULT FALSE,
  "Status_Aktif"      BOOLEAN NOT NULL DEFAULT TRUE,
  "Tgl_Update"        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS "idx_mLokasi_Unit" ON "mLokasi"("UnitBisnisID");

CREATE TABLE IF NOT EXISTS "mSampah" (
  "Sampah_ID"           SERIAL PRIMARY KEY,
  "Kode_Sampah"         VARCHAR(30) UNIQUE NOT NULL,
  "Nama_Sampah"         VARCHAR(200) NOT NULL,
  "Kategori_ID"         INT NOT NULL REFERENCES "mKategori"("Kategori_ID"),
  "SubKategori_ID"      INT REFERENCES "mSubKategori"("SubKategori_ID"),
  "Kode_Satuan"         VARCHAR(10) NOT NULL REFERENCES "mSatuan"("Kode_Satuan"),
  "Harga_Beli"          NUMERIC(14,2) NOT NULL DEFAULT 0,
  "Harga_Jual"          NUMERIC(14,2) NOT NULL DEFAULT 0,
  "TglBerlaku_Harga"    TIMESTAMPTZ,
  "HRataRata"           NUMERIC(14,2) NOT NULL DEFAULT 0,
  "Stock_Akhir"         NUMERIC(14,3) NOT NULL DEFAULT 0,
  "Min_Stock"           NUMERIC(14,3) NOT NULL DEFAULT 0,
  "Aktif"               BOOLEAN NOT NULL DEFAULT TRUE,
  "UnitBisnisID"        INT NOT NULL REFERENCES "mUnitBisnis"("UnitBisnisID"),
  "Tgl_Update"          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "User_Update"         INT REFERENCES "mUser"("User_ID")
);

CREATE INDEX IF NOT EXISTS "idx_mSampah_Unit" ON "mSampah"("UnitBisnisID");
CREATE INDEX IF NOT EXISTS "idx_mSampah_Kategori" ON "mSampah"("Kategori_ID");

CREATE TABLE IF NOT EXISTS "mSampah_ChangePrice" (
  "ID"                  SERIAL PRIMARY KEY,
  "Sampah_ID"           INT NOT NULL REFERENCES "mSampah"("Sampah_ID"),
  "Harga_Beli_Lama"     NUMERIC(14,2),
  "Harga_Beli_Baru"     NUMERIC(14,2),
  "Harga_Jual_Lama"     NUMERIC(14,2),
  "Harga_Jual_Baru"     NUMERIC(14,2),
  "Tgl_Update"          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "User_ID"             INT REFERENCES "mUser"("User_ID"),
  "UnitBisnisID"        INT REFERENCES "mUnitBisnis"("UnitBisnisID")
);

CREATE INDEX IF NOT EXISTS "idx_mSampahChangePrice_Sampah" ON "mSampah_ChangePrice"("Sampah_ID");
CREATE INDEX IF NOT EXISTS "idx_mSampahChangePrice_Unit" ON "mSampah_ChangePrice"("UnitBisnisID");

CREATE TABLE IF NOT EXISTS "mVendor" (
  "Vendor_ID"           SERIAL PRIMARY KEY,
  "Kode_Vendor"         VARCHAR(30) UNIQUE NOT NULL,
  "Nama_Vendor"         VARCHAR(150) NOT NULL,
  "Kode_Kategori"       VARCHAR(10) REFERENCES "mKategori_Vendor"("Kode_Kategori"),
  "Alamat"              TEXT,
  "No_Telepon"          VARCHAR(50),
  "Alamat_Email"        VARCHAR(100),
  "No_NPWP"             VARCHAR(50),
  "Atas_Nama"           VARCHAR(150),
  "Bank"                VARCHAR(100),
  "No_Rek"              VARCHAR(50),
  "Status_Aktif"        BOOLEAN NOT NULL DEFAULT TRUE,
  "UnitBisnisID"        INT NOT NULL REFERENCES "mUnitBisnis"("UnitBisnisID"),
  "Tgl_Update"          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS "idx_mVendor_Unit" ON "mVendor"("UnitBisnisID");

INSERT INTO "mSatuan"("Kode_Satuan", "Nama_Satuan", "Satuan_Default") VALUES
  ('KG', 'Kilogram', TRUE),
  ('PCS', 'Pieces', FALSE),
  ('BTL', 'Botol', FALSE),
  ('LTR', 'Liter', FALSE)
ON CONFLICT ("Kode_Satuan") DO UPDATE SET
  "Nama_Satuan" = EXCLUDED."Nama_Satuan",
  "Satuan_Default" = EXCLUDED."Satuan_Default";

INSERT INTO "mKategori"("Kode_Kategori", "Nama_Kategori") VALUES
  ('ANO', 'Anorganik'),
  ('ORG', 'Organik'),
  ('B3', 'Bahan Berbahaya Beracun'),
  ('RES', 'Residu')
ON CONFLICT ("Kode_Kategori") DO UPDATE SET
  "Nama_Kategori" = EXCLUDED."Nama_Kategori",
  "Status_Aktif" = TRUE;

INSERT INTO "mKategori_Vendor"("Kode_Kategori", "Kategori_Name") VALUES
  ('PGPL', 'Pengepul Sampah'),
  ('PRBR', 'Pabrik Daur Ulang')
ON CONFLICT ("Kode_Kategori") DO UPDATE SET
  "Kategori_Name" = EXCLUDED."Kategori_Name",
  "Status_Aktif" = TRUE;

INSERT INTO "mJenisTransaksi"("JTransaksi_ID", "Nama_Transaksi") VALUES
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
ON CONFLICT ("JTransaksi_ID") DO UPDATE SET
  "Nama_Transaksi" = EXCLUDED."Nama_Transaksi";

WITH unit_bkpsdm AS (
  SELECT "UnitBisnisID" FROM "mUnitBisnis" WHERE "Kode_OPD" = 'BKPSDM' LIMIT 1
)
INSERT INTO "mLokasi"(
  "Kode_Lokasi", "Nama_Lokasi", "Tipe_Lokasi", "UnitBisnisID", "Gudang_Utama", "Status_Aktif"
)
SELECT 'BKPSDM-TPS', 'TPS BKPSDM', 'TPS', "UnitBisnisID", TRUE, TRUE
FROM unit_bkpsdm
ON CONFLICT ("Kode_Lokasi") DO UPDATE SET
  "Nama_Lokasi" = EXCLUDED."Nama_Lokasi",
  "Tipe_Lokasi" = EXCLUDED."Tipe_Lokasi",
  "UnitBisnisID" = EXCLUDED."UnitBisnisID",
  "Gudang_Utama" = TRUE,
  "Status_Aktif" = TRUE,
  "Tgl_Update" = NOW();

WITH unit_bkpsdm AS (
  SELECT "UnitBisnisID" FROM "mUnitBisnis" WHERE "Kode_OPD" = 'BKPSDM' LIMIT 1
),
kategori_ano AS (
  SELECT "Kategori_ID" FROM "mKategori" WHERE "Kode_Kategori" = 'ANO' LIMIT 1
)
INSERT INTO "mSampah"(
  "Kode_Sampah", "Nama_Sampah", "Kategori_ID", "Kode_Satuan",
  "Harga_Beli", "Harga_Jual", "TglBerlaku_Harga", "UnitBisnisID", "Aktif"
)
SELECT seed."Kode_Sampah", seed."Nama_Sampah", kategori_ano."Kategori_ID", 'KG',
       seed."Harga_Beli", seed."Harga_Jual", NOW(), unit_bkpsdm."UnitBisnisID", TRUE
FROM unit_bkpsdm
CROSS JOIN kategori_ano
CROSS JOIN (
  VALUES
    ('BTL-PET', 'Botol PET', 3000::NUMERIC(14,2), 3500::NUMERIC(14,2)),
    ('KRD', 'Kardus', 1500::NUMERIC(14,2), 2000::NUMERIC(14,2)),
    ('KRTS', 'Kertas Campur', 1000::NUMERIC(14,2), 1500::NUMERIC(14,2)),
    ('BESI', 'Besi', 4000::NUMERIC(14,2), 5000::NUMERIC(14,2)),
    ('KACA', 'Kaca', 500::NUMERIC(14,2), 800::NUMERIC(14,2))
) AS seed("Kode_Sampah", "Nama_Sampah", "Harga_Beli", "Harga_Jual")
ON CONFLICT ("Kode_Sampah") DO UPDATE SET
  "Nama_Sampah" = EXCLUDED."Nama_Sampah",
  "Kategori_ID" = EXCLUDED."Kategori_ID",
  "Kode_Satuan" = EXCLUDED."Kode_Satuan",
  "Harga_Beli" = EXCLUDED."Harga_Beli",
  "Harga_Jual" = EXCLUDED."Harga_Jual",
  "TglBerlaku_Harga" = COALESCE("mSampah"."TglBerlaku_Harga", NOW()),
  "UnitBisnisID" = EXCLUDED."UnitBisnisID",
  "Aktif" = TRUE,
  "Tgl_Update" = NOW();

WITH unit_bkpsdm AS (
  SELECT "UnitBisnisID" FROM "mUnitBisnis" WHERE "Kode_OPD" = 'BKPSDM' LIMIT 1
)
INSERT INTO "mVendor"(
  "Kode_Vendor", "Nama_Vendor", "Kode_Kategori", "UnitBisnisID", "Status_Aktif"
)
SELECT 'VND-BKPSDM-001', 'Vendor Pengepul BKPSDM', 'PGPL', "UnitBisnisID", TRUE
FROM unit_bkpsdm
ON CONFLICT ("Kode_Vendor") DO UPDATE SET
  "Nama_Vendor" = EXCLUDED."Nama_Vendor",
  "Kode_Kategori" = EXCLUDED."Kode_Kategori",
  "UnitBisnisID" = EXCLUDED."UnitBisnisID",
  "Status_Aktif" = TRUE,
  "Tgl_Update" = NOW();

ALTER TABLE "SIMmSection" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "mKategori" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "mSubKategori" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "mSatuan" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "mJenisTransaksi" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "mKategori_Vendor" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "mLokasi" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "mSampah" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "mSampah_ChangePrice" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "mVendor" ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION "private"."userHasAccessToUnit"(p_UnitBisnisID INT) RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public."mUser" mu
    JOIN public."mUserUnitBisnis" uub ON uub."User_ID" = mu."User_ID"
    WHERE mu."Auth_UID" = (SELECT auth.uid())
      AND uub."UnitBisnisID" = p_UnitBisnisID
  ) OR "private"."currentUserIsAdmin"();
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, private;

REVOKE ALL ON FUNCTION "private"."userHasAccessToUnit"(INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "private"."userHasAccessToUnit"(INT) TO authenticated;

DROP POLICY IF EXISTS "SIMmSection_select_unit" ON "SIMmSection";
CREATE POLICY "SIMmSection_select_unit" ON "SIMmSection"
FOR SELECT
USING ("private"."userHasAccessToUnit"("UnitBisnisID"));

DROP POLICY IF EXISTS "SIMmSection_modify_admin" ON "SIMmSection";
CREATE POLICY "SIMmSection_modify_admin" ON "SIMmSection"
FOR ALL
USING ("private"."currentUserIsAdmin"())
WITH CHECK ("private"."currentUserIsAdmin"());

DROP POLICY IF EXISTS "mKategori_select_authenticated" ON "mKategori";
CREATE POLICY "mKategori_select_authenticated" ON "mKategori"
FOR SELECT TO authenticated
USING (TRUE);

DROP POLICY IF EXISTS "mSubKategori_select_authenticated" ON "mSubKategori";
CREATE POLICY "mSubKategori_select_authenticated" ON "mSubKategori"
FOR SELECT TO authenticated
USING (TRUE);

DROP POLICY IF EXISTS "mSatuan_select_authenticated" ON "mSatuan";
CREATE POLICY "mSatuan_select_authenticated" ON "mSatuan"
FOR SELECT TO authenticated
USING (TRUE);

DROP POLICY IF EXISTS "mJenisTransaksi_select_authenticated" ON "mJenisTransaksi";
CREATE POLICY "mJenisTransaksi_select_authenticated" ON "mJenisTransaksi"
FOR SELECT TO authenticated
USING (TRUE);

DROP POLICY IF EXISTS "mKategoriVendor_select_authenticated" ON "mKategori_Vendor";
CREATE POLICY "mKategoriVendor_select_authenticated" ON "mKategori_Vendor"
FOR SELECT TO authenticated
USING (TRUE);

DROP POLICY IF EXISTS "mLokasi_select_unit" ON "mLokasi";
CREATE POLICY "mLokasi_select_unit" ON "mLokasi"
FOR SELECT
USING ("private"."userHasAccessToUnit"("UnitBisnisID"));

DROP POLICY IF EXISTS "mLokasi_modify_admin" ON "mLokasi";
CREATE POLICY "mLokasi_modify_admin" ON "mLokasi"
FOR ALL
USING ("private"."currentUserIsAdmin"())
WITH CHECK ("private"."currentUserIsAdmin"());

DROP POLICY IF EXISTS "mSampah_select_unit" ON "mSampah";
CREATE POLICY "mSampah_select_unit" ON "mSampah"
FOR SELECT
USING ("private"."userHasAccessToUnit"("UnitBisnisID"));

DROP POLICY IF EXISTS "mSampah_modify_admin" ON "mSampah";
CREATE POLICY "mSampah_modify_admin" ON "mSampah"
FOR ALL
USING ("private"."currentUserIsAdmin"())
WITH CHECK ("private"."currentUserIsAdmin"());

DROP POLICY IF EXISTS "mSampahChangePrice_select_unit" ON "mSampah_ChangePrice";
CREATE POLICY "mSampahChangePrice_select_unit" ON "mSampah_ChangePrice"
FOR SELECT
USING ("private"."userHasAccessToUnit"("UnitBisnisID"));

DROP POLICY IF EXISTS "mSampahChangePrice_modify_admin" ON "mSampah_ChangePrice";
CREATE POLICY "mSampahChangePrice_modify_admin" ON "mSampah_ChangePrice"
FOR ALL
USING ("private"."currentUserIsAdmin"())
WITH CHECK ("private"."currentUserIsAdmin"());

DROP POLICY IF EXISTS "mVendor_select_unit" ON "mVendor";
CREATE POLICY "mVendor_select_unit" ON "mVendor"
FOR SELECT
USING ("private"."userHasAccessToUnit"("UnitBisnisID"));

DROP POLICY IF EXISTS "mVendor_modify_admin" ON "mVendor";
CREATE POLICY "mVendor_modify_admin" ON "mVendor"
FOR ALL
USING ("private"."currentUserIsAdmin"())
WITH CHECK ("private"."currentUserIsAdmin"());

GRANT SELECT ON
  "SIMmSection",
  "mKategori",
  "mSubKategori",
  "mSatuan",
  "mJenisTransaksi",
  "mKategori_Vendor",
  "mLokasi",
  "mSampah",
  "mSampah_ChangePrice",
  "mVendor"
TO authenticated;

GRANT INSERT, UPDATE ON
  "SIMmSection",
  "mLokasi",
  "mSampah",
  "mSampah_ChangePrice",
  "mVendor"
TO authenticated;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
