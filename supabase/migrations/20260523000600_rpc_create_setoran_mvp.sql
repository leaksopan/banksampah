CREATE OR REPLACE FUNCTION "private"."BS_GenerateNoBuktiImpl"(
  p_UnitBisnisID INT,
  p_Kode_Modul TEXT,
  p_Tgl TIMESTAMPTZ DEFAULT NOW()
) RETURNS VARCHAR AS $$
DECLARE
  v_Tanggal VARCHAR(6);
  v_Counter INT;
  v_Prefix VARCHAR(30);
BEGIN
  IF p_Kode_Modul NOT IN ('BSP', 'BSJ', 'BST') THEN
    RAISE EXCEPTION 'kode modul tidak valid: %', p_Kode_Modul
      USING ERRCODE = 'P0001';
  END IF;

  SELECT "NomorBukti"
  INTO v_Prefix
  FROM public."mUnitBisnis"
  WHERE "UnitBisnisID" = p_UnitBisnisID
  LIMIT 1;

  IF v_Prefix IS NULL THEN
    RAISE EXCEPTION 'UnitBisnisID tidak ditemukan: %', p_UnitBisnisID
      USING ERRCODE = 'P0001';
  END IF;

  v_Tanggal := TO_CHAR(p_Tgl AT TIME ZONE 'Asia/Makassar', 'YYMMDD');

  INSERT INTO public."BS_SequenceCounter"("UnitBisnisID", "Kode_Modul", "Tanggal", "Counter")
  VALUES (p_UnitBisnisID, p_Kode_Modul, v_Tanggal, 1)
  ON CONFLICT ("UnitBisnisID", "Kode_Modul", "Tanggal") DO UPDATE SET
    "Counter" = public."BS_SequenceCounter"."Counter" + 1
  RETURNING "Counter" INTO v_Counter;

  RETURN v_Tanggal || p_Kode_Modul || '#' || v_Prefix || '-' || LPAD(v_Counter::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

REVOKE ALL ON FUNCTION "private"."BS_GenerateNoBuktiImpl"(INT, TEXT, TIMESTAMPTZ) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "private"."BS_GenerateNoBuktiImpl"(INT, TEXT, TIMESTAMPTZ) TO authenticated;

CREATE OR REPLACE FUNCTION public."BS_GenerateNoBukti"(
  p_UnitBisnisID INT,
  p_Kode_Modul TEXT,
  p_Tgl TIMESTAMPTZ DEFAULT NOW()
) RETURNS VARCHAR AS $$
  SELECT "private"."BS_GenerateNoBuktiImpl"(p_UnitBisnisID, p_Kode_Modul, p_Tgl);
$$ LANGUAGE sql SECURITY INVOKER SET search_path = public, private;

GRANT EXECUTE ON FUNCTION public."BS_GenerateNoBukti"(INT, TEXT, TIMESTAMPTZ) TO authenticated;

CREATE OR REPLACE FUNCTION "private"."bs_create_setoran_impl"(
  p_pegawai_id INT,
  p_lokasi_id INT,
  p_keterangan TEXT DEFAULT NULL,
  p_details JSONB DEFAULT '[]'::jsonb
) RETURNS JSONB AS $$
DECLARE
  v_User_ID INT;
  v_UnitBisnisID INT;
  v_LokasiUnitBisnisID INT;
  v_NoBukti VARCHAR(50);
  v_Detail JSONB;
  v_Sampah RECORD;
  v_Qty NUMERIC(14,3);
  v_HargaBeli NUMERIC(14,2);
  v_Subtotal NUMERIC(14,2);
  v_TotalBerat NUMERIC(14,3) := 0;
  v_TotalNilai NUMERIC(14,2) := 0;
  v_NoUrut SMALLINT := 0;
  v_DetailID BIGINT;
BEGIN
  IF NOT "private"."currentUserIsAdmin"() THEN
    RAISE EXCEPTION 'unauthorized: hanya admin yang dapat input setoran'
      USING ERRCODE = 'P0001';
  END IF;

  IF jsonb_typeof(p_details) IS DISTINCT FROM 'array' OR jsonb_array_length(p_details) = 0 THEN
    RAISE EXCEPTION 'detail setoran wajib diisi'
      USING ERRCODE = 'P0001';
  END IF;

  v_User_ID := "private"."currentUserID"();

  SELECT "UnitBisnisID"
  INTO v_UnitBisnisID
  FROM public."mPegawai"
  WHERE "Pegawai_ID" = p_pegawai_id
    AND "Status_Aktif" = TRUE
  LIMIT 1;

  IF v_UnitBisnisID IS NULL THEN
    RAISE EXCEPTION 'pegawai tidak ditemukan atau tidak aktif: %', p_pegawai_id
      USING ERRCODE = 'P0001';
  END IF;

  IF NOT "private"."userHasAccessToUnit"(v_UnitBisnisID) THEN
    RAISE EXCEPTION 'unauthorized: tidak punya akses ke OPD pegawai'
      USING ERRCODE = 'P0001';
  END IF;

  SELECT "UnitBisnisID"
  INTO v_LokasiUnitBisnisID
  FROM public."mLokasi"
  WHERE "Lokasi_ID" = p_lokasi_id
    AND "Status_Aktif" = TRUE
  LIMIT 1;

  IF v_LokasiUnitBisnisID IS NULL THEN
    RAISE EXCEPTION 'lokasi tidak ditemukan atau tidak aktif: %', p_lokasi_id
      USING ERRCODE = 'P0001';
  END IF;

  IF v_LokasiUnitBisnisID <> v_UnitBisnisID THEN
    RAISE EXCEPTION 'lokasi dan pegawai berbeda OPD'
      USING ERRCODE = 'P0001';
  END IF;

  v_NoBukti := "private"."BS_GenerateNoBuktiImpl"(v_UnitBisnisID, 'BSP', NOW());

  INSERT INTO public."BS_trSetoran"(
    "No_Bukti",
    "Tgl_Setoran",
    "Pegawai_ID",
    "Lokasi_ID",
    "Total_Berat",
    "Total_Nilai",
    "Keterangan",
    "User_ID",
    "Tgl_Update",
    "Jam_Setor",
    "HostName",
    "Status_Batal",
    "Posting_KG",
    "Posting_Saldo",
    "Posted",
    "UnitBisnisID"
  )
  VALUES (
    v_NoBukti,
    NOW(),
    p_pegawai_id,
    p_lokasi_id,
    0,
    0,
    NULLIF(TRIM(p_keterangan), ''),
    v_User_ID,
    NOW(),
    NOW(),
    'supabase-rpc',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    v_UnitBisnisID
  );

  FOR v_Detail IN SELECT value FROM jsonb_array_elements(p_details)
  LOOP
    v_NoUrut := v_NoUrut + 1;

    v_Qty := COALESCE(
      NULLIF(v_Detail ->> 'Qty', '')::NUMERIC,
      NULLIF(v_Detail ->> 'qty', '')::NUMERIC
    );

    IF v_Qty IS NULL OR v_Qty <= 0 THEN
      RAISE EXCEPTION 'qty detail ke-% harus lebih dari 0', v_NoUrut
        USING ERRCODE = 'P0001';
    END IF;

    SELECT
      s."Sampah_ID",
      s."Kode_Satuan",
      s."Harga_Beli",
      s."UnitBisnisID",
      s."Aktif"
    INTO v_Sampah
    FROM public."mSampah" s
    WHERE s."Sampah_ID" = COALESCE(
        NULLIF(v_Detail ->> 'Sampah_ID', '')::INT,
        NULLIF(v_Detail ->> 'sampah_id', '')::INT,
        NULLIF(v_Detail ->> 'sampahId', '')::INT
      )
    LIMIT 1;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'sampah detail ke-% tidak ditemukan', v_NoUrut
        USING ERRCODE = 'P0001';
    END IF;

    IF v_Sampah."UnitBisnisID" <> v_UnitBisnisID OR v_Sampah."Aktif" = FALSE THEN
      RAISE EXCEPTION 'sampah detail ke-% tidak aktif atau berbeda OPD', v_NoUrut
        USING ERRCODE = 'P0001';
    END IF;

    v_HargaBeli := v_Sampah."Harga_Beli";
    v_Subtotal := ROUND(v_Qty * v_HargaBeli, 2);
    v_TotalBerat := v_TotalBerat + v_Qty;
    v_TotalNilai := v_TotalNilai + v_Subtotal;

    INSERT INTO public."BS_trSetoranDetail"(
      "No_Bukti",
      "Sampah_ID",
      "Kode_Satuan",
      "Qty",
      "Harga_Beli",
      "Subtotal",
      "NoUrut"
    )
    VALUES (
      v_NoBukti,
      v_Sampah."Sampah_ID",
      v_Sampah."Kode_Satuan",
      v_Qty,
      v_HargaBeli,
      v_Subtotal,
      v_NoUrut
    )
    RETURNING "Detail_ID" INTO v_DetailID;

    INSERT INTO public."BS_trStockLayer"(
      "No_Bukti_Setoran",
      "Detail_ID_Setoran",
      "Sampah_ID",
      "Pegawai_ID",
      "Lokasi_ID",
      "Qty_Awal",
      "Qty_Sisa",
      "Harga_Beli",
      "Tgl_Masuk",
      "Status",
      "UnitBisnisID"
    )
    VALUES (
      v_NoBukti,
      v_DetailID,
      v_Sampah."Sampah_ID",
      p_pegawai_id,
      p_lokasi_id,
      v_Qty,
      v_Qty,
      v_HargaBeli,
      NOW(),
      'ACTIVE',
      v_UnitBisnisID
    );

    INSERT INTO public."BS_trKartuGudang"(
      "Lokasi_ID",
      "Sampah_ID",
      "No_Bukti",
      "JTransaksi_ID",
      "Tgl_Transaksi",
      "Kode_Satuan",
      "Qty_Masuk",
      "Harga_Masuk",
      "Qty_Keluar",
      "Harga_Keluar",
      "UnitBisnisID"
    )
    VALUES (
      p_lokasi_id,
      v_Sampah."Sampah_ID",
      v_NoBukti,
      700,
      NOW(),
      v_Sampah."Kode_Satuan",
      v_Qty,
      v_HargaBeli,
      0,
      0,
      v_UnitBisnisID
    );

    INSERT INTO public."BS_trMutasiSaldo"(
      "Pegawai_ID",
      "JTransaksi_ID",
      "No_Bukti_Ref",
      "Pending_Kredit",
      "Tgl_Mutasi",
      "Keterangan",
      "User_ID",
      "UnitBisnisID"
    )
    VALUES (
      p_pegawai_id,
      700,
      v_NoBukti,
      v_Subtotal,
      NOW(),
      FORMAT('Setoran sampah %s kg @ %s', v_Qty, v_HargaBeli),
      v_User_ID,
      v_UnitBisnisID
    );
  END LOOP;

  UPDATE public."BS_trSetoran"
  SET
    "Total_Berat" = v_TotalBerat,
    "Total_Nilai" = v_TotalNilai,
    "Posting_KG" = TRUE,
    "Posting_Saldo" = TRUE,
    "Posted" = TRUE,
    "Tgl_Update" = NOW()
  WHERE "No_Bukti" = v_NoBukti;

  UPDATE public."BS_tSaldoPegawai"
  SET
    "Total_Berat_Setor" = "Total_Berat_Setor" + v_TotalBerat,
    "Tgl_Update" = NOW()
  WHERE "Pegawai_ID" = p_pegawai_id;

  RETURN jsonb_build_object(
    'ok', TRUE,
    'no_bukti', v_NoBukti,
    'pegawai_id', p_pegawai_id,
    'lokasi_id', p_lokasi_id,
    'total_berat', v_TotalBerat,
    'total_nilai', v_TotalNilai,
    'detail_count', v_NoUrut
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

REVOKE ALL ON FUNCTION "private"."bs_create_setoran_impl"(INT, INT, TEXT, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "private"."bs_create_setoran_impl"(INT, INT, TEXT, JSONB) TO authenticated;

CREATE OR REPLACE FUNCTION public."bs_create_setoran"(
  p_pegawai_id INT,
  p_lokasi_id INT,
  p_keterangan TEXT DEFAULT NULL,
  p_details JSONB DEFAULT '[]'::jsonb
) RETURNS JSONB AS $$
  SELECT "private"."bs_create_setoran_impl"(p_pegawai_id, p_lokasi_id, p_keterangan, p_details);
$$ LANGUAGE sql SECURITY INVOKER SET search_path = public, private;

GRANT EXECUTE ON FUNCTION public."bs_create_setoran"(INT, INT, TEXT, JSONB) TO authenticated;
