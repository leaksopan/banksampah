CREATE TABLE IF NOT EXISTS "BS_SequenceCounter" (
  "UnitBisnisID"    INT NOT NULL REFERENCES "mUnitBisnis"("UnitBisnisID"),
  "Kode_Modul"      VARCHAR(5) NOT NULL,
  "Tanggal"         VARCHAR(6) NOT NULL,
  "Counter"         INT NOT NULL DEFAULT 0,
  PRIMARY KEY ("UnitBisnisID", "Kode_Modul", "Tanggal")
);

CREATE TABLE IF NOT EXISTS "BS_trSetoran" (
  "No_Bukti"            VARCHAR(50) PRIMARY KEY,
  "Tgl_Setoran"         TIMESTAMPTZ NOT NULL,
  "Pegawai_ID"          INT NOT NULL REFERENCES "mPegawai"("Pegawai_ID"),
  "Lokasi_ID"           INT NOT NULL REFERENCES "mLokasi"("Lokasi_ID"),
  "Total_Berat"         NUMERIC(14,3) NOT NULL DEFAULT 0,
  "Total_Nilai"         NUMERIC(14,2) NOT NULL DEFAULT 0,
  "Keterangan"          VARCHAR(200),
  "User_ID"             INT REFERENCES "mUser"("User_ID"),
  "Tgl_Update"          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "Jam_Setor"           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "HostName"            VARCHAR(50),
  "Status_Batal"        BOOLEAN NOT NULL DEFAULT FALSE,
  "Posting_KG"          BOOLEAN NOT NULL DEFAULT FALSE,
  "Posting_Saldo"       BOOLEAN NOT NULL DEFAULT FALSE,
  "Posted"              BOOLEAN NOT NULL DEFAULT FALSE,
  "UnitBisnisID"        INT NOT NULL REFERENCES "mUnitBisnis"("UnitBisnisID")
);

CREATE INDEX IF NOT EXISTS "idx_BS_Setoran_Pegawai_Tgl" ON "BS_trSetoran"("Pegawai_ID", "Tgl_Setoran" DESC);
CREATE INDEX IF NOT EXISTS "idx_BS_Setoran_Lokasi_Tgl" ON "BS_trSetoran"("Lokasi_ID", "Tgl_Setoran" DESC);
CREATE INDEX IF NOT EXISTS "idx_BS_Setoran_Unit" ON "BS_trSetoran"("UnitBisnisID", "Tgl_Setoran" DESC);

CREATE TABLE IF NOT EXISTS "BS_trSetoranDetail" (
  "Detail_ID"           BIGSERIAL PRIMARY KEY,
  "No_Bukti"            VARCHAR(50) NOT NULL REFERENCES "BS_trSetoran"("No_Bukti") ON DELETE CASCADE,
  "Sampah_ID"           INT NOT NULL REFERENCES "mSampah"("Sampah_ID"),
  "Kode_Satuan"         VARCHAR(10) NOT NULL REFERENCES "mSatuan"("Kode_Satuan"),
  "Qty"                 NUMERIC(14,3) NOT NULL CHECK ("Qty" > 0),
  "Harga_Beli"          NUMERIC(14,2) NOT NULL,
  "Subtotal"            NUMERIC(14,2) NOT NULL,
  "NoUrut"              SMALLINT NOT NULL
);

CREATE INDEX IF NOT EXISTS "idx_BS_SetoranDetail_NoBukti" ON "BS_trSetoranDetail"("No_Bukti");
CREATE INDEX IF NOT EXISTS "idx_BS_SetoranDetail_Sampah" ON "BS_trSetoranDetail"("Sampah_ID");

CREATE TABLE IF NOT EXISTS "BS_trStockLayer" (
  "Layer_ID"            BIGSERIAL PRIMARY KEY,
  "No_Bukti_Setoran"    VARCHAR(50) NOT NULL REFERENCES "BS_trSetoran"("No_Bukti"),
  "Detail_ID_Setoran"   BIGINT REFERENCES "BS_trSetoranDetail"("Detail_ID"),
  "Sampah_ID"           INT NOT NULL REFERENCES "mSampah"("Sampah_ID"),
  "Pegawai_ID"          INT NOT NULL REFERENCES "mPegawai"("Pegawai_ID"),
  "Lokasi_ID"           INT NOT NULL REFERENCES "mLokasi"("Lokasi_ID"),
  "Qty_Awal"            NUMERIC(14,3) NOT NULL,
  "Qty_Sisa"            NUMERIC(14,3) NOT NULL,
  "Harga_Beli"          NUMERIC(14,2) NOT NULL,
  "Tgl_Masuk"           TIMESTAMPTZ NOT NULL,
  "Status"              VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  "UnitBisnisID"        INT NOT NULL REFERENCES "mUnitBisnis"("UnitBisnisID"),
  CHECK ("Status" IN ('ACTIVE', 'EXHAUSTED'))
);

CREATE INDEX IF NOT EXISTS "idx_BS_Layer_Active" ON "BS_trStockLayer"("Lokasi_ID", "Sampah_ID", "Tgl_Masuk")
  WHERE "Status" = 'ACTIVE';
CREATE INDEX IF NOT EXISTS "idx_BS_Layer_Pegawai" ON "BS_trStockLayer"("Pegawai_ID", "Status");
CREATE INDEX IF NOT EXISTS "idx_BS_Layer_Unit" ON "BS_trStockLayer"("UnitBisnisID");

CREATE TABLE IF NOT EXISTS "BS_trPenjualan" (
  "No_Bukti"            VARCHAR(50) PRIMARY KEY,
  "Tgl_Penjualan"       TIMESTAMPTZ NOT NULL,
  "Vendor_ID"           INT NOT NULL REFERENCES "mVendor"("Vendor_ID"),
  "Lokasi_ID"           INT NOT NULL REFERENCES "mLokasi"("Lokasi_ID"),
  "Total_Berat"         NUMERIC(14,3) NOT NULL DEFAULT 0,
  "Total_Nilai"         NUMERIC(14,2) NOT NULL DEFAULT 0,
  "Total_HPP"           NUMERIC(14,2) NOT NULL DEFAULT 0,
  "Total_Selisih"       NUMERIC(14,2) NOT NULL DEFAULT 0,
  "Type_Pembayaran"     CHAR(1) NOT NULL DEFAULT 'C',
  "Keterangan"          VARCHAR(200),
  "User_ID"             INT REFERENCES "mUser"("User_ID"),
  "Tgl_Update"          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "Jam_Posting"         TIMESTAMPTZ,
  "HostName"            VARCHAR(50),
  "Status_Batal"        BOOLEAN NOT NULL DEFAULT FALSE,
  "Posting_KG"          BOOLEAN NOT NULL DEFAULT FALSE,
  "Posting_Saldo"       BOOLEAN NOT NULL DEFAULT FALSE,
  "Posted"              BOOLEAN NOT NULL DEFAULT FALSE,
  "Disetujui"           BOOLEAN NOT NULL DEFAULT FALSE,
  "DisetujuiTgl"        TIMESTAMPTZ,
  "DisetujuiUserID"     INT REFERENCES "mUser"("User_ID"),
  "UnitBisnisID"        INT NOT NULL REFERENCES "mUnitBisnis"("UnitBisnisID")
);

CREATE INDEX IF NOT EXISTS "idx_BS_Penjualan_Unit_Tgl" ON "BS_trPenjualan"("UnitBisnisID", "Tgl_Penjualan" DESC);
CREATE INDEX IF NOT EXISTS "idx_BS_Penjualan_Vendor" ON "BS_trPenjualan"("Vendor_ID");

CREATE TABLE IF NOT EXISTS "BS_trPenjualanDetail" (
  "Detail_ID"           BIGSERIAL PRIMARY KEY,
  "No_Bukti"            VARCHAR(50) NOT NULL REFERENCES "BS_trPenjualan"("No_Bukti") ON DELETE CASCADE,
  "Sampah_ID"           INT NOT NULL REFERENCES "mSampah"("Sampah_ID"),
  "Kode_Satuan"         VARCHAR(10) NOT NULL REFERENCES "mSatuan"("Kode_Satuan"),
  "Qty"                 NUMERIC(14,3) NOT NULL CHECK ("Qty" > 0),
  "Harga_Jual"          NUMERIC(14,2) NOT NULL,
  "Subtotal"            NUMERIC(14,2) NOT NULL,
  "Total_HPP_Detail"    NUMERIC(14,2) NOT NULL DEFAULT 0,
  "NoUrut"              SMALLINT NOT NULL
);

CREATE INDEX IF NOT EXISTS "idx_BS_PenjualanDetail_NoBukti" ON "BS_trPenjualanDetail"("No_Bukti");
CREATE INDEX IF NOT EXISTS "idx_BS_PenjualanDetail_Sampah" ON "BS_trPenjualanDetail"("Sampah_ID");

CREATE TABLE IF NOT EXISTS "BS_trKartuFIFO_Keluar" (
  "FIFOKeluar_ID"       BIGSERIAL PRIMARY KEY,
  "Lokasi_ID"           INT NOT NULL REFERENCES "mLokasi"("Lokasi_ID"),
  "Sampah_ID"           INT NOT NULL REFERENCES "mSampah"("Sampah_ID"),
  "No_Bukti"            VARCHAR(50) NOT NULL REFERENCES "BS_trPenjualan"("No_Bukti"),
  "Detail_ID_Penjualan" BIGINT REFERENCES "BS_trPenjualanDetail"("Detail_ID"),
  "Layer_ID"            BIGINT NOT NULL REFERENCES "BS_trStockLayer"("Layer_ID"),
  "Pegawai_ID"          INT NOT NULL REFERENCES "mPegawai"("Pegawai_ID"),
  "Qty_Keluar"          NUMERIC(14,3) NOT NULL,
  "Harga_Beli"          NUMERIC(14,2) NOT NULL,
  "Harga_Jual"          NUMERIC(14,2) NOT NULL,
  "Selisih_PerKg"       NUMERIC(14,2) NOT NULL,
  "Total_Selisih"       NUMERIC(14,2) NOT NULL,
  "NoBuktiAsal"         VARCHAR(50),
  "UnitBisnisID"        INT NOT NULL REFERENCES "mUnitBisnis"("UnitBisnisID")
);

CREATE INDEX IF NOT EXISTS "idx_BS_FIFOKeluar_Pegawai" ON "BS_trKartuFIFO_Keluar"("Pegawai_ID");
CREATE INDEX IF NOT EXISTS "idx_BS_FIFOKeluar_Penjualan" ON "BS_trKartuFIFO_Keluar"("No_Bukti");
CREATE INDEX IF NOT EXISTS "idx_BS_FIFOKeluar_Unit" ON "BS_trKartuFIFO_Keluar"("UnitBisnisID");

CREATE TABLE IF NOT EXISTS "BS_trKartuGudang" (
  "Kartu_ID"            BIGSERIAL PRIMARY KEY,
  "Lokasi_ID"           INT NOT NULL REFERENCES "mLokasi"("Lokasi_ID"),
  "Sampah_ID"           INT NOT NULL REFERENCES "mSampah"("Sampah_ID"),
  "No_Bukti"            VARCHAR(50) NOT NULL,
  "JTransaksi_ID"       INT NOT NULL REFERENCES "mJenisTransaksi"("JTransaksi_ID"),
  "Tgl_Transaksi"       TIMESTAMPTZ NOT NULL,
  "Kode_Satuan"         VARCHAR(10) NOT NULL REFERENCES "mSatuan"("Kode_Satuan"),
  "Qty_Masuk"           NUMERIC(14,3) NOT NULL DEFAULT 0,
  "Harga_Masuk"         NUMERIC(14,2) NOT NULL DEFAULT 0,
  "Qty_Keluar"          NUMERIC(14,3) NOT NULL DEFAULT 0,
  "Harga_Keluar"        NUMERIC(14,2) NOT NULL DEFAULT 0,
  "Qty_Saldo"           NUMERIC(14,3) NOT NULL DEFAULT 0,
  "Harga_Persediaan"    NUMERIC(14,2) NOT NULL DEFAULT 0,
  "RowTerakhir"         BOOLEAN NOT NULL DEFAULT FALSE,
  "Jam"                 TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UnitBisnisID"        INT NOT NULL REFERENCES "mUnitBisnis"("UnitBisnisID")
);

CREATE INDEX IF NOT EXISTS "idx_BS_KG_Lokasi_Sampah_Tgl" ON "BS_trKartuGudang"("Lokasi_ID", "Sampah_ID", "Tgl_Transaksi");
CREATE INDEX IF NOT EXISTS "idx_BS_KG_RowTerakhir" ON "BS_trKartuGudang"("Lokasi_ID", "Sampah_ID")
  WHERE "RowTerakhir" = TRUE;
CREATE INDEX IF NOT EXISTS "idx_BS_KG_NoBukti" ON "BS_trKartuGudang"("No_Bukti");
CREATE INDEX IF NOT EXISTS "idx_BS_KG_Unit" ON "BS_trKartuGudang"("UnitBisnisID");

CREATE TABLE IF NOT EXISTS "BS_trMutasiSaldo" (
  "Mutasi_ID"               BIGSERIAL PRIMARY KEY,
  "Pegawai_ID"              INT NOT NULL REFERENCES "mPegawai"("Pegawai_ID"),
  "JTransaksi_ID"           INT NOT NULL REFERENCES "mJenisTransaksi"("JTransaksi_ID"),
  "No_Bukti_Ref"            VARCHAR(50),
  "FIFOKeluar_ID_Ref"       BIGINT REFERENCES "BS_trKartuFIFO_Keluar"("FIFOKeluar_ID"),
  "Pending_Debit"           NUMERIC(14,2) NOT NULL DEFAULT 0,
  "Pending_Kredit"          NUMERIC(14,2) NOT NULL DEFAULT 0,
  "Tersedia_Debit"          NUMERIC(14,2) NOT NULL DEFAULT 0,
  "Tersedia_Kredit"         NUMERIC(14,2) NOT NULL DEFAULT 0,
  "Saldo_Pending_Sesudah"   NUMERIC(14,2),
  "Saldo_Tersedia_Sesudah"  NUMERIC(14,2),
  "Tgl_Mutasi"              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "Keterangan"              VARCHAR(300),
  "User_ID"                 INT REFERENCES "mUser"("User_ID"),
  "UnitBisnisID"            INT NOT NULL REFERENCES "mUnitBisnis"("UnitBisnisID")
);

CREATE INDEX IF NOT EXISTS "idx_BS_Mutasi_Pegawai_Tgl" ON "BS_trMutasiSaldo"("Pegawai_ID", "Tgl_Mutasi" DESC);
CREATE INDEX IF NOT EXISTS "idx_BS_Mutasi_Unit_Tgl" ON "BS_trMutasiSaldo"("UnitBisnisID", "Tgl_Mutasi" DESC);
CREATE INDEX IF NOT EXISTS "idx_BS_Mutasi_NoBuktiRef" ON "BS_trMutasiSaldo"("No_Bukti_Ref");

CREATE TABLE IF NOT EXISTS "BS_trPenarikan" (
  "No_Bukti"            VARCHAR(50) PRIMARY KEY,
  "Tgl_Penarikan"       TIMESTAMPTZ NOT NULL,
  "Pegawai_ID"          INT NOT NULL REFERENCES "mPegawai"("Pegawai_ID"),
  "Jumlah"              NUMERIC(14,2) NOT NULL CHECK ("Jumlah" > 0),
  "Type_Pembayaran"     CHAR(1) NOT NULL,
  "No_Rek"              VARCHAR(50),
  "Nama_Bank"           VARCHAR(50),
  "Atas_Nama"           VARCHAR(150),
  "Status"              VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  "Disetujui"           BOOLEAN NOT NULL DEFAULT FALSE,
  "DisetujuiTgl"        TIMESTAMPTZ,
  "DisetujuiUserID"     INT REFERENCES "mUser"("User_ID"),
  "Tgl_Bayar"           TIMESTAMPTZ,
  "User_Bayar"          INT REFERENCES "mUser"("User_ID"),
  "Bukti_Transfer_URL"  TEXT,
  "Keterangan"          VARCHAR(300),
  "User_ID"             INT REFERENCES "mUser"("User_ID"),
  "Tgl_Update"          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "HostName"            VARCHAR(50),
  "Status_Batal"        BOOLEAN NOT NULL DEFAULT FALSE,
  "Posting_Saldo"       BOOLEAN NOT NULL DEFAULT FALSE,
  "UnitBisnisID"        INT NOT NULL REFERENCES "mUnitBisnis"("UnitBisnisID"),
  CHECK ("Status" IN ('PENDING', 'APPROVED', 'PAID', 'REJECTED'))
);

CREATE INDEX IF NOT EXISTS "idx_BS_Penarikan_Pegawai" ON "BS_trPenarikan"("Pegawai_ID", "Tgl_Penarikan" DESC);
CREATE INDEX IF NOT EXISTS "idx_BS_Penarikan_Status" ON "BS_trPenarikan"("Status", "UnitBisnisID");

CREATE OR REPLACE FUNCTION "private"."BS_TrgSyncSaldoPegawai"() RETURNS TRIGGER AS $$
DECLARE
  v_NewPending   NUMERIC(14,2);
  v_NewTersedia  NUMERIC(14,2);
BEGIN
  INSERT INTO public."BS_tSaldoPegawai"(
    "Pegawai_ID",
    "UnitBisnisID",
    "Saldo_Pending",
    "Saldo_Tersedia",
    "Total_Berat_Setor",
    "Total_Berat_Terjual",
    "Tgl_Update"
  )
  VALUES (
    NEW."Pegawai_ID",
    NEW."UnitBisnisID",
    NEW."Pending_Kredit" - NEW."Pending_Debit",
    NEW."Tersedia_Kredit" - NEW."Tersedia_Debit",
    0,
    0,
    NOW()
  )
  ON CONFLICT ("Pegawai_ID") DO UPDATE SET
    "Saldo_Pending" = public."BS_tSaldoPegawai"."Saldo_Pending" + NEW."Pending_Kredit" - NEW."Pending_Debit",
    "Saldo_Tersedia" = public."BS_tSaldoPegawai"."Saldo_Tersedia" + NEW."Tersedia_Kredit" - NEW."Tersedia_Debit",
    "Tgl_Update" = NOW(),
    "UnitBisnisID" = EXCLUDED."UnitBisnisID"
  RETURNING "Saldo_Pending", "Saldo_Tersedia"
  INTO v_NewPending, v_NewTersedia;

  UPDATE public."BS_trMutasiSaldo"
  SET
    "Saldo_Pending_Sesudah" = v_NewPending,
    "Saldo_Tersedia_Sesudah" = v_NewTersedia
  WHERE "Mutasi_ID" = NEW."Mutasi_ID";

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

DROP TRIGGER IF EXISTS "trg_BS_SyncSaldo" ON "BS_trMutasiSaldo";
CREATE TRIGGER "trg_BS_SyncSaldo"
AFTER INSERT ON "BS_trMutasiSaldo"
FOR EACH ROW EXECUTE FUNCTION "private"."BS_TrgSyncSaldoPegawai"();

CREATE OR REPLACE FUNCTION "private"."BS_TrgKartuGudangSaldo"() RETURNS TRIGGER AS $$
DECLARE
  v_PrevSaldo       NUMERIC(14,3);
  v_PrevHarga       NUMERIC(14,2);
  v_NewSaldo        NUMERIC(14,3);
  v_NewWAC          NUMERIC(14,2);
  v_TotalNilaiAwal  NUMERIC(14,2);
BEGIN
  SELECT "Qty_Saldo", "Harga_Persediaan"
  INTO v_PrevSaldo, v_PrevHarga
  FROM public."BS_trKartuGudang"
  WHERE "Lokasi_ID" = NEW."Lokasi_ID"
    AND "Sampah_ID" = NEW."Sampah_ID"
    AND "RowTerakhir" = TRUE
  ORDER BY "Kartu_ID" DESC
  LIMIT 1;

  v_PrevSaldo := COALESCE(v_PrevSaldo, 0);
  v_PrevHarga := COALESCE(v_PrevHarga, 0);
  v_NewSaldo := v_PrevSaldo + NEW."Qty_Masuk" - NEW."Qty_Keluar";

  IF v_NewSaldo < 0 THEN
    RAISE EXCEPTION 'stok tidak cukup untuk Sampah_ID %, sisa setelah transaksi %', NEW."Sampah_ID", v_NewSaldo
      USING ERRCODE = 'P0001';
  END IF;

  IF NEW."Qty_Masuk" > 0 THEN
    v_TotalNilaiAwal := (v_PrevSaldo * v_PrevHarga) + (NEW."Qty_Masuk" * NEW."Harga_Masuk");
    v_NewWAC := CASE WHEN v_NewSaldo > 0 THEN ROUND(v_TotalNilaiAwal / v_NewSaldo, 2) ELSE 0 END;
  ELSE
    v_NewWAC := CASE WHEN v_NewSaldo > 0 THEN v_PrevHarga ELSE 0 END;
  END IF;

  UPDATE public."BS_trKartuGudang"
  SET "RowTerakhir" = FALSE
  WHERE "Lokasi_ID" = NEW."Lokasi_ID"
    AND "Sampah_ID" = NEW."Sampah_ID"
    AND "RowTerakhir" = TRUE;

  NEW."Qty_Saldo" := v_NewSaldo;
  NEW."Harga_Persediaan" := v_NewWAC;
  NEW."RowTerakhir" := TRUE;

  UPDATE public."mSampah"
  SET
    "Stock_Akhir" = v_NewSaldo,
    "HRataRata" = v_NewWAC,
    "Tgl_Update" = NOW()
  WHERE "Sampah_ID" = NEW."Sampah_ID"
    AND "UnitBisnisID" = NEW."UnitBisnisID";

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

DROP TRIGGER IF EXISTS "trg_BS_KartuGudangSaldo" ON "BS_trKartuGudang";
CREATE TRIGGER "trg_BS_KartuGudangSaldo"
BEFORE INSERT ON "BS_trKartuGudang"
FOR EACH ROW EXECUTE FUNCTION "private"."BS_TrgKartuGudangSaldo"();

ALTER TABLE "BS_SequenceCounter" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "BS_trSetoran" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "BS_trSetoranDetail" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "BS_trStockLayer" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "BS_trPenjualan" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "BS_trPenjualanDetail" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "BS_trKartuFIFO_Keluar" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "BS_trKartuGudang" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "BS_trMutasiSaldo" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "BS_trPenarikan" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "BS_SequenceCounter_admin" ON "BS_SequenceCounter";
CREATE POLICY "BS_SequenceCounter_admin" ON "BS_SequenceCounter"
FOR ALL
USING ("private"."currentUserIsAdmin"())
WITH CHECK ("private"."currentUserIsAdmin"());

DROP POLICY IF EXISTS "BS_trSetoran_select_unit" ON "BS_trSetoran";
CREATE POLICY "BS_trSetoran_select_unit" ON "BS_trSetoran"
FOR SELECT
USING ("private"."userHasAccessToUnit"("UnitBisnisID"));

DROP POLICY IF EXISTS "BS_trSetoran_modify_admin_unposted" ON "BS_trSetoran";
CREATE POLICY "BS_trSetoran_modify_admin_unposted" ON "BS_trSetoran"
FOR ALL
USING ("private"."currentUserIsAdmin"() AND "Posted" = FALSE)
WITH CHECK ("private"."currentUserIsAdmin"());

DROP POLICY IF EXISTS "BS_trSetoranDetail_select_parent_unit" ON "BS_trSetoranDetail";
CREATE POLICY "BS_trSetoranDetail_select_parent_unit" ON "BS_trSetoranDetail"
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM "BS_trSetoran" h
    WHERE h."No_Bukti" = "BS_trSetoranDetail"."No_Bukti"
      AND "private"."userHasAccessToUnit"(h."UnitBisnisID")
  )
);

DROP POLICY IF EXISTS "BS_trSetoranDetail_modify_admin_parent_unposted" ON "BS_trSetoranDetail";
CREATE POLICY "BS_trSetoranDetail_modify_admin_parent_unposted" ON "BS_trSetoranDetail"
FOR ALL
USING (
  "private"."currentUserIsAdmin"()
  AND EXISTS (
    SELECT 1 FROM "BS_trSetoran" h
    WHERE h."No_Bukti" = "BS_trSetoranDetail"."No_Bukti"
      AND h."Posted" = FALSE
  )
)
WITH CHECK ("private"."currentUserIsAdmin"());

DROP POLICY IF EXISTS "BS_trStockLayer_select_unit" ON "BS_trStockLayer";
CREATE POLICY "BS_trStockLayer_select_unit" ON "BS_trStockLayer"
FOR SELECT
USING ("private"."userHasAccessToUnit"("UnitBisnisID"));

DROP POLICY IF EXISTS "BS_trStockLayer_modify_admin" ON "BS_trStockLayer";
CREATE POLICY "BS_trStockLayer_modify_admin" ON "BS_trStockLayer"
FOR ALL
USING ("private"."currentUserIsAdmin"())
WITH CHECK ("private"."currentUserIsAdmin"());

DROP POLICY IF EXISTS "BS_trPenjualan_select_unit" ON "BS_trPenjualan";
CREATE POLICY "BS_trPenjualan_select_unit" ON "BS_trPenjualan"
FOR SELECT
USING ("private"."userHasAccessToUnit"("UnitBisnisID"));

DROP POLICY IF EXISTS "BS_trPenjualan_modify_admin_unposted" ON "BS_trPenjualan";
CREATE POLICY "BS_trPenjualan_modify_admin_unposted" ON "BS_trPenjualan"
FOR ALL
USING ("private"."currentUserIsAdmin"() AND "Posted" = FALSE)
WITH CHECK ("private"."currentUserIsAdmin"());

DROP POLICY IF EXISTS "BS_trPenjualanDetail_select_parent_unit" ON "BS_trPenjualanDetail";
CREATE POLICY "BS_trPenjualanDetail_select_parent_unit" ON "BS_trPenjualanDetail"
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM "BS_trPenjualan" h
    WHERE h."No_Bukti" = "BS_trPenjualanDetail"."No_Bukti"
      AND "private"."userHasAccessToUnit"(h."UnitBisnisID")
  )
);

DROP POLICY IF EXISTS "BS_trPenjualanDetail_modify_admin_parent_unposted" ON "BS_trPenjualanDetail";
CREATE POLICY "BS_trPenjualanDetail_modify_admin_parent_unposted" ON "BS_trPenjualanDetail"
FOR ALL
USING (
  "private"."currentUserIsAdmin"()
  AND EXISTS (
    SELECT 1 FROM "BS_trPenjualan" h
    WHERE h."No_Bukti" = "BS_trPenjualanDetail"."No_Bukti"
      AND h."Posted" = FALSE
  )
)
WITH CHECK ("private"."currentUserIsAdmin"());

DROP POLICY IF EXISTS "BS_trKartuFIFO_select_unit" ON "BS_trKartuFIFO_Keluar";
CREATE POLICY "BS_trKartuFIFO_select_unit" ON "BS_trKartuFIFO_Keluar"
FOR SELECT
USING ("private"."userHasAccessToUnit"("UnitBisnisID"));

DROP POLICY IF EXISTS "BS_trKartuFIFO_modify_admin" ON "BS_trKartuFIFO_Keluar";
CREATE POLICY "BS_trKartuFIFO_modify_admin" ON "BS_trKartuFIFO_Keluar"
FOR ALL
USING ("private"."currentUserIsAdmin"())
WITH CHECK ("private"."currentUserIsAdmin"());

DROP POLICY IF EXISTS "BS_trKartuGudang_select_unit" ON "BS_trKartuGudang";
CREATE POLICY "BS_trKartuGudang_select_unit" ON "BS_trKartuGudang"
FOR SELECT
USING ("private"."userHasAccessToUnit"("UnitBisnisID"));

DROP POLICY IF EXISTS "BS_trKartuGudang_modify_admin" ON "BS_trKartuGudang";
CREATE POLICY "BS_trKartuGudang_modify_admin" ON "BS_trKartuGudang"
FOR ALL
USING ("private"."currentUserIsAdmin"())
WITH CHECK ("private"."currentUserIsAdmin"());

DROP POLICY IF EXISTS "BS_trMutasiSaldo_select_self_or_unit_admin" ON "BS_trMutasiSaldo";
CREATE POLICY "BS_trMutasiSaldo_select_self_or_unit_admin" ON "BS_trMutasiSaldo"
FOR SELECT
USING (
  "private"."userHasAccessToUnit"("UnitBisnisID")
  OR EXISTS (
    SELECT 1 FROM "mPegawai" mp
    WHERE mp."Pegawai_ID" = "BS_trMutasiSaldo"."Pegawai_ID"
      AND mp."User_ID" = "private"."currentUserID"()
  )
);

DROP POLICY IF EXISTS "BS_trMutasiSaldo_modify_admin" ON "BS_trMutasiSaldo";
CREATE POLICY "BS_trMutasiSaldo_modify_admin" ON "BS_trMutasiSaldo"
FOR ALL
USING ("private"."currentUserIsAdmin"())
WITH CHECK ("private"."currentUserIsAdmin"());

DROP POLICY IF EXISTS "BS_trPenarikan_select_self_or_unit_admin" ON "BS_trPenarikan";
CREATE POLICY "BS_trPenarikan_select_self_or_unit_admin" ON "BS_trPenarikan"
FOR SELECT
USING (
  "private"."userHasAccessToUnit"("UnitBisnisID")
  OR EXISTS (
    SELECT 1 FROM "mPegawai" mp
    WHERE mp."Pegawai_ID" = "BS_trPenarikan"."Pegawai_ID"
      AND mp."User_ID" = "private"."currentUserID"()
  )
);

DROP POLICY IF EXISTS "BS_trPenarikan_modify_admin" ON "BS_trPenarikan";
CREATE POLICY "BS_trPenarikan_modify_admin" ON "BS_trPenarikan"
FOR ALL
USING ("private"."currentUserIsAdmin"() AND "Posting_Saldo" = FALSE)
WITH CHECK ("private"."currentUserIsAdmin"());

GRANT SELECT, INSERT, UPDATE ON
  "BS_SequenceCounter",
  "BS_trSetoran",
  "BS_trSetoranDetail",
  "BS_trStockLayer",
  "BS_trPenjualan",
  "BS_trPenjualanDetail",
  "BS_trKartuFIFO_Keluar",
  "BS_trKartuGudang",
  "BS_trMutasiSaldo",
  "BS_trPenarikan"
TO authenticated;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
