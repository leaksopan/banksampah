CREATE OR REPLACE FUNCTION "private"."bs_void_setoran_impl"(
  p_no_bukti TEXT,
  p_keterangan TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_User_ID INT;
  v_Setoran RECORD;
  v_Detail RECORD;
  v_RealisasiCount INT;
BEGIN
  IF NOT "private"."currentUserIsAdmin"() THEN
    RAISE EXCEPTION 'unauthorized: hanya admin yang dapat void setoran'
      USING ERRCODE = 'P0001';
  END IF;

  v_User_ID := "private"."currentUserID"();

  SELECT *
  INTO v_Setoran
  FROM public."BS_trSetoran"
  WHERE "No_Bukti" = p_no_bukti
  LIMIT 1
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'setoran tidak ditemukan: %', p_no_bukti
      USING ERRCODE = 'P0001';
  END IF;

  IF NOT "private"."userHasAccessToUnit"(v_Setoran."UnitBisnisID") THEN
    RAISE EXCEPTION 'unauthorized: tidak punya akses ke OPD setoran'
      USING ERRCODE = 'P0001';
  END IF;

  IF v_Setoran."Status_Batal" THEN
    RAISE EXCEPTION 'setoran sudah dibatalkan: %', p_no_bukti
      USING ERRCODE = 'P0001';
  END IF;

  SELECT COUNT(*)
  INTO v_RealisasiCount
  FROM public."BS_trStockLayer" sl
  WHERE sl."No_Bukti_Setoran" = p_no_bukti
    AND (
      sl."Qty_Sisa" <> sl."Qty_Awal"
      OR EXISTS (
        SELECT 1
        FROM public."BS_trKartuFIFO_Keluar" fifo
        WHERE fifo."Layer_ID" = sl."Layer_ID"
      )
    );

  IF v_RealisasiCount > 0 THEN
    RAISE EXCEPTION 'setoran sudah terealisasi sebagian/penuh dan tidak bisa di-void: %', p_no_bukti
      USING ERRCODE = 'P0001';
  END IF;

  UPDATE public."BS_trSetoran"
  SET
    "Status_Batal" = TRUE,
    "User_ID" = v_User_ID,
    "Tgl_Update" = NOW(),
    "HostName" = 'supabase-rpc'
  WHERE "No_Bukti" = p_no_bukti;

  FOR v_Detail IN
    SELECT
      d."Sampah_ID",
      d."Kode_Satuan",
      d."Qty",
      d."Harga_Beli"
    FROM public."BS_trSetoranDetail" d
    WHERE d."No_Bukti" = p_no_bukti
    ORDER BY d."NoUrut"
  LOOP
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
      v_Setoran."Lokasi_ID",
      v_Detail."Sampah_ID",
      p_no_bukti,
      705,
      NOW(),
      v_Detail."Kode_Satuan",
      0,
      0,
      v_Detail."Qty",
      v_Detail."Harga_Beli",
      v_Setoran."UnitBisnisID"
    );
  END LOOP;

  INSERT INTO public."BS_trMutasiSaldo"(
    "Pegawai_ID",
    "JTransaksi_ID",
    "No_Bukti_Ref",
    "Pending_Debit",
    "Tgl_Mutasi",
    "Keterangan",
    "User_ID",
    "UnitBisnisID"
  )
  VALUES (
    v_Setoran."Pegawai_ID",
    705,
    p_no_bukti,
    v_Setoran."Total_Nilai",
    NOW(),
    COALESCE(NULLIF(TRIM(p_keterangan), ''), FORMAT('Pembatalan setoran %s', p_no_bukti)),
    v_User_ID,
    v_Setoran."UnitBisnisID"
  );

  UPDATE public."BS_trStockLayer"
  SET
    "Qty_Sisa" = 0,
    "Status" = 'EXHAUSTED'
  WHERE "No_Bukti_Setoran" = p_no_bukti;

  UPDATE public."BS_tSaldoPegawai"
  SET
    "Total_Berat_Setor" = GREATEST("Total_Berat_Setor" - v_Setoran."Total_Berat", 0),
    "Tgl_Update" = NOW()
  WHERE "Pegawai_ID" = v_Setoran."Pegawai_ID";

  RETURN jsonb_build_object(
    'ok', TRUE,
    'no_bukti', p_no_bukti,
    'total_berat', v_Setoran."Total_Berat",
    'total_nilai', v_Setoran."Total_Nilai"
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

REVOKE ALL ON FUNCTION "private"."bs_void_setoran_impl"(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "private"."bs_void_setoran_impl"(TEXT, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public."bs_void_setoran"(
  p_no_bukti TEXT,
  p_keterangan TEXT DEFAULT NULL
) RETURNS JSONB AS $$
  SELECT "private"."bs_void_setoran_impl"(p_no_bukti, p_keterangan);
$$ LANGUAGE sql SECURITY INVOKER SET search_path = public, private;

GRANT EXECUTE ON FUNCTION public."bs_void_setoran"(TEXT, TEXT) TO authenticated;
