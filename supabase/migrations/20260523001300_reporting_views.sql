-- 20260523001300_reporting_views.sql

CREATE OR REPLACE VIEW public."vBS_StockCurrent" AS
SELECT
  kg."Lokasi_ID", l."Nama_Lokasi",
  kg."Sampah_ID", s."Nama_Sampah", s."Kode_Sampah",
  kg."Qty_Saldo" AS "Stock_Akhir", kg."Harga_Persediaan" AS "Harga_Rata",
  kg."UnitBisnisID"
FROM public."BS_trKartuGudang" kg
JOIN public."mLokasi" l ON l."Lokasi_ID" = kg."Lokasi_ID"
JOIN public."mSampah" s ON s."Sampah_ID" = kg."Sampah_ID"
WHERE kg."RowTerakhir" = TRUE;

ALTER VIEW public."vBS_StockCurrent" OWNER TO postgres;

CREATE OR REPLACE VIEW public."vBS_RingkasanPegawai" AS
SELECT
  p."Pegawai_ID", p."Nama_Pegawai", p."NIP",
  p."UnitBisnisID", ub."UnitBisnisName",
  COALESCE(s."Saldo_Pending", 0) AS "Saldo_Pending",
  COALESCE(s."Saldo_Tersedia", 0) AS "Saldo_Tersedia",
  COALESCE(s."Total_Ditarik", 0) AS "Total_Ditarik",
  COALESCE(s."Total_Berat_Setor", 0) AS "Total_Berat_Setor",
  COALESCE(s."Total_Berat_Terjual", 0) AS "Total_Berat_Terjual"
FROM public."mPegawai" p
JOIN public."mUnitBisnis" ub ON ub."UnitBisnisID" = p."UnitBisnisID"
LEFT JOIN public."BS_tSaldoPegawai" s ON s."Pegawai_ID" = p."Pegawai_ID";

ALTER VIEW public."vBS_RingkasanPegawai" OWNER TO postgres;


CREATE OR REPLACE FUNCTION public."bs_report_kartu_gudang"(
  p_lokasi_id INT,
  p_sampah_id INT,
  p_from TIMESTAMPTZ DEFAULT NULL,
  p_to TIMESTAMPTZ DEFAULT NULL
) RETURNS TABLE (
  "Kartu_ID" BIGINT,
  "Lokasi_ID" INT,
  "Nama_Lokasi" VARCHAR(100),
  "Sampah_ID" INT,
  "Nama_Sampah" VARCHAR(200),
  "No_Bukti" VARCHAR(50),
  "Nama_Transaksi" VARCHAR(50),
  "Tgl_Transaksi" TIMESTAMPTZ,
  "Qty_Masuk" NUMERIC(14,3),
  "Harga_Masuk" NUMERIC(14,2),
  "Qty_Keluar" NUMERIC(14,3),
  "Harga_Keluar" NUMERIC(14,2),
  "Qty_Saldo" NUMERIC(14,3),
  "Harga_Persediaan" NUMERIC(14,2),
  "UnitBisnisID" INT
) AS $$
BEGIN
  -- Ensure that the caller has access to the location's UnitBisnisID
  IF NOT EXISTS (
    SELECT 1 FROM public."mLokasi" loc
    WHERE loc."Lokasi_ID" = p_lokasi_id
      AND "private"."userHasAccessToUnit"(loc."UnitBisnisID")
  ) THEN
    RAISE EXCEPTION 'unauthorized: tidak punya akses ke lokasi ini'
      USING ERRCODE = 'P0001';
  END IF;

  RETURN QUERY
  SELECT
    kg."Kartu_ID",
    kg."Lokasi_ID",
    l."Nama_Lokasi",
    kg."Sampah_ID",
    s."Nama_Sampah",
    kg."No_Bukti",
    jt."Nama_Transaksi",
    kg."Tgl_Transaksi",
    kg."Qty_Masuk",
    kg."Harga_Masuk",
    kg."Qty_Keluar",
    kg."Harga_Keluar",
    kg."Qty_Saldo",
    kg."Harga_Persediaan",
    kg."UnitBisnisID"
  FROM public."BS_trKartuGudang" kg
  JOIN public."mLokasi" l ON l."Lokasi_ID" = kg."Lokasi_ID"
  JOIN public."mSampah" s ON s."Sampah_ID" = kg."Sampah_ID"
  JOIN public."mJenisTransaksi" jt ON jt."JTransaksi_ID" = kg."JTransaksi_ID"
  WHERE kg."Lokasi_ID" = p_lokasi_id
    AND kg."Sampah_ID" = p_sampah_id
    AND (p_from IS NULL OR kg."Tgl_Transaksi" >= p_from)
    AND (p_to IS NULL OR kg."Tgl_Transaksi" < p_to)
  ORDER BY kg."Tgl_Transaksi" ASC, kg."Kartu_ID" ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

GRANT EXECUTE ON FUNCTION public."bs_report_kartu_gudang"(INT, INT, TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;


CREATE OR REPLACE FUNCTION public."bs_report_selisih_realisasi"(
  p_pegawai_id INT
) RETURNS TABLE (
  "FIFOKeluar_ID" BIGINT,
  "No_Bukti" VARCHAR(50),
  "Tgl_Penjualan" TIMESTAMPTZ,
  "Nama_Sampah" VARCHAR(200),
  "Qty_Keluar" NUMERIC(14,3),
  "Harga_Beli" NUMERIC(14,2),
  "Harga_Jual" NUMERIC(14,2),
  "Selisih_PerKg" NUMERIC(14,2),
  "Total_Selisih" NUMERIC(14,2),
  "NoBuktiAsal" VARCHAR(50)
) AS $$
DECLARE
  v_User_ID INT;
  v_PegawaiUserID INT;
  v_UserAdmin BOOLEAN;
  v_UnitBisnisID INT;
BEGIN
  v_User_ID := "private"."currentUserID"();
  v_UserAdmin := "private"."currentUserIsAdmin"();

  SELECT "User_ID", "UnitBisnisID"
  INTO v_PegawaiUserID, v_UnitBisnisID
  FROM public."mPegawai"
  WHERE "Pegawai_ID" = p_pegawai_id
  LIMIT 1;

  -- Security check: non-admin can only view their own
  IF NOT v_UserAdmin AND v_PegawaiUserID <> v_User_ID THEN
    RAISE EXCEPTION 'unauthorized: hanya dapat melihat data milik sendiri'
      USING ERRCODE = 'P0001';
  END IF;

  -- Admin check: must have access to unit
  IF v_UserAdmin AND NOT "private"."userHasAccessToUnit"(v_UnitBisnisID) THEN
    RAISE EXCEPTION 'unauthorized: tidak punya akses ke OPD pegawai'
      USING ERRCODE = 'P0001';
  END IF;

  RETURN QUERY
  SELECT
    fk."FIFOKeluar_ID",
    fk."No_Bukti",
    pj."Tgl_Penjualan",
    s."Nama_Sampah",
    fk."Qty_Keluar",
    fk."Harga_Beli",
    fk."Harga_Jual",
    fk."Selisih_PerKg",
    fk."Total_Selisih",
    fk."NoBuktiAsal"
  FROM public."BS_trKartuFIFO_Keluar" fk
  JOIN public."mSampah" s ON s."Sampah_ID" = fk."Sampah_ID"
  JOIN public."BS_trPenjualan" pj ON pj."No_Bukti" = fk."No_Bukti"
  WHERE fk."Pegawai_ID" = p_pegawai_id
  ORDER BY pj."Tgl_Penjualan" DESC, fk."FIFOKeluar_ID" DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

GRANT EXECUTE ON FUNCTION public."bs_report_selisih_realisasi"(INT) TO authenticated;
