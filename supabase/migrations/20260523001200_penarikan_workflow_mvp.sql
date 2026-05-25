CREATE OR REPLACE FUNCTION "private"."bs_create_penarikan_impl"(
  p_pegawai_id INT,
  p_jumlah NUMERIC,
  p_type_pembayaran CHAR,
  p_no_rek VARCHAR DEFAULT NULL,
  p_nama_bank VARCHAR DEFAULT NULL,
  p_atas_nama VARCHAR DEFAULT NULL,
  p_keterangan TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_User_ID INT;
  v_UnitBisnisID INT;
  v_NoBukti VARCHAR(50);
  v_SaldoTersedia NUMERIC(14,2);
  v_SaldoPendingPenarikan NUMERIC(14,2);
  v_MinPenarikan NUMERIC(14,2) := 0;
  v_PegawaiUserID INT;
  v_UserAdmin BOOLEAN;
  v_Config JSONB;
BEGIN
  -- Authenticated user validation
  v_User_ID := "private"."currentUserID"();
  v_UserAdmin := "private"."currentUserIsAdmin"();

  -- Get Pegawai details
  SELECT "UnitBisnisID", "User_ID"
  INTO v_UnitBisnisID, v_PegawaiUserID
  FROM public."mPegawai"
  WHERE "Pegawai_ID" = p_pegawai_id
    AND "Status_Aktif" = TRUE
  LIMIT 1;

  IF v_UnitBisnisID IS NULL THEN
    RAISE EXCEPTION 'pegawai tidak ditemukan atau tidak aktif: %', p_pegawai_id
      USING ERRCODE = 'P0001';
  END IF;

  -- Security check: non-admin can only create penarikan for themselves
  IF NOT v_UserAdmin AND v_PegawaiUserID <> v_User_ID THEN
    RAISE EXCEPTION 'unauthorized: hanya dapat mengajukan penarikan untuk diri sendiri'
      USING ERRCODE = 'P0001';
  END IF;

  -- Admin check: must have access to the pegawai's unit
  IF v_UserAdmin AND NOT "private"."userHasAccessToUnit"(v_UnitBisnisID) THEN
    RAISE EXCEPTION 'unauthorized: tidak punya akses ke OPD pegawai'
      USING ERRCODE = 'P0001';
  END IF;

  -- Parameter validation
  IF p_jumlah IS NULL OR p_jumlah <= 0 THEN
    RAISE EXCEPTION 'jumlah penarikan harus lebih dari 0'
      USING ERRCODE = 'P0001';
  END IF;

  IF p_type_pembayaran NOT IN ('C', 'T') THEN
    RAISE EXCEPTION 'tipe pembayaran harus C (Cash) atau T (Transfer)'
      USING ERRCODE = 'P0001';
  END IF;

  IF p_type_pembayaran = 'T' AND (NULLIF(TRIM(p_no_rek), '') IS NULL OR NULLIF(TRIM(p_nama_bank), '') IS NULL OR NULLIF(TRIM(p_atas_nama), '') IS NULL) THEN
    RAISE EXCEPTION 'rekening transfer bank harus diisi lengkap (bank, no rek, atas nama)'
      USING ERRCODE = 'P0001';
  END IF;

  -- Check minimum withdrawal limit
  SELECT "Config"
  INTO v_Config
  FROM public."mUnitBisnis"
  WHERE "UnitBisnisID" = v_UnitBisnisID
  LIMIT 1;

  IF v_Config ? 'min_penarikan' THEN
    v_MinPenarikan := (v_Config ->> 'min_penarikan')::numeric;
  END IF;

  IF p_jumlah < v_MinPenarikan THEN
    RAISE EXCEPTION 'jumlah penarikan Rp % di bawah batas minimal Rp %', p_jumlah, v_MinPenarikan
      USING ERRCODE = 'P0001';
  END IF;

  -- Lock & Check available balance
  SELECT COALESCE("Saldo_Tersedia", 0)
  INTO v_SaldoTersedia
  FROM public."BS_tSaldoPegawai"
  WHERE "Pegawai_ID" = p_pegawai_id
  FOR UPDATE;

  IF v_SaldoTersedia IS NULL THEN
    v_SaldoTersedia := 0;
  END IF;

  -- Calculate existing pending & approved penarikan
  SELECT COALESCE(SUM("Jumlah"), 0)
  INTO v_SaldoPendingPenarikan
  FROM public."BS_trPenarikan"
  WHERE "Pegawai_ID" = p_pegawai_id
    AND "Status" IN ('PENDING', 'APPROVED')
    AND "Status_Batal" = FALSE;

  IF v_SaldoTersedia - v_SaldoPendingPenarikan < p_jumlah THEN
    RAISE EXCEPTION 'saldo tersedia tidak mencukupi. Tersedia: Rp %, Dalam Proses: Rp %, Diajukan: Rp %', 
      v_SaldoTersedia, v_SaldoPendingPenarikan, p_jumlah
      USING ERRCODE = 'P0001';
  END IF;

  -- Generate No_Bukti (BST)
  v_NoBukti := "private"."BS_GenerateNoBuktiImpl"(v_UnitBisnisID, 'BST', NOW());

  -- Insert Penarikan
  INSERT INTO public."BS_trPenarikan"(
    "No_Bukti",
    "Tgl_Penarikan",
    "Pegawai_ID",
    "Jumlah",
    "Type_Pembayaran",
    "No_Rek",
    "Nama_Bank",
    "Atas_Nama",
    "Status",
    "Disetujui",
    "Keterangan",
    "User_ID",
    "Tgl_Update",
    "HostName",
    "Status_Batal",
    "Posting_Saldo",
    "UnitBisnisID"
  )
  VALUES (
    v_NoBukti,
    NOW(),
    p_pegawai_id,
    p_jumlah,
    p_type_pembayaran,
    CASE WHEN p_type_pembayaran = 'T' THEN TRIM(p_no_rek) ELSE NULL END,
    CASE WHEN p_type_pembayaran = 'T' THEN TRIM(p_nama_bank) ELSE NULL END,
    CASE WHEN p_type_pembayaran = 'T' THEN TRIM(p_atas_nama) ELSE NULL END,
    'PENDING',
    FALSE,
    NULLIF(TRIM(p_keterangan), ''),
    v_User_ID,
    NOW(),
    'supabase-rpc',
    FALSE,
    FALSE,
    v_UnitBisnisID
  );

  RETURN jsonb_build_object(
    'ok', TRUE,
    'no_bukti', v_NoBukti,
    'pegawai_id', p_pegawai_id,
    'jumlah', p_jumlah,
    'status', 'PENDING'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

REVOKE ALL ON FUNCTION "private"."bs_create_penarikan_impl"(INT, NUMERIC, CHAR, VARCHAR, VARCHAR, VARCHAR, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "private"."bs_create_penarikan_impl"(INT, NUMERIC, CHAR, VARCHAR, VARCHAR, VARCHAR, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public."bs_create_penarikan"(
  p_pegawai_id INT,
  p_jumlah NUMERIC,
  p_type_pembayaran CHAR,
  p_no_rek VARCHAR DEFAULT NULL,
  p_nama_bank VARCHAR DEFAULT NULL,
  p_atas_nama VARCHAR DEFAULT NULL,
  p_keterangan TEXT DEFAULT NULL
) RETURNS JSONB AS $$
  SELECT "private"."bs_create_penarikan_impl"(p_pegawai_id, p_jumlah, p_type_pembayaran, p_no_rek, p_nama_bank, p_atas_nama, p_keterangan);
$$ LANGUAGE sql SECURITY INVOKER SET search_path = public, private;

GRANT EXECUTE ON FUNCTION public."bs_create_penarikan"(INT, NUMERIC, CHAR, VARCHAR, VARCHAR, VARCHAR, TEXT) TO authenticated;


CREATE OR REPLACE FUNCTION "private"."bs_approve_penarikan_impl"(
  p_no_bukti VARCHAR,
  p_approve BOOLEAN,
  p_keterangan TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_User_ID INT;
  v_Penarikan RECORD;
BEGIN
  IF NOT "private"."currentUserIsAdmin"() THEN
    RAISE EXCEPTION 'unauthorized: hanya admin yang dapat memproses approval penarikan'
      USING ERRCODE = 'P0001';
  END IF;

  v_User_ID := "private"."currentUserID"();

  SELECT *
  INTO v_Penarikan
  FROM public."BS_trPenarikan"
  WHERE "No_Bukti" = p_no_bukti
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'transaksi penarikan tidak ditemukan: %', p_no_bukti
      USING ERRCODE = 'P0001';
  END IF;

  IF v_Penarikan."Status" <> 'PENDING' THEN
    RAISE EXCEPTION 'transaksi penarikan sudah diproses sebelumnya: status saat ini %', v_Penarikan."Status"
      USING ERRCODE = 'P0001';
  END IF;

  IF NOT "private"."userHasAccessToUnit"(v_Penarikan."UnitBisnisID") THEN
    RAISE EXCEPTION 'unauthorized: tidak punya akses ke OPD transaksi ini'
      USING ERRCODE = 'P0001';
  END IF;

  IF p_approve THEN
    UPDATE public."BS_trPenarikan"
    SET "Status" = 'APPROVED',
        "Disetujui" = TRUE,
        "DisetujuiTgl" = NOW(),
        "DisetujuiUserID" = v_User_ID,
        "Keterangan" = COALESCE(NULLIF(TRIM(p_keterangan), ''), "Keterangan"),
        "Tgl_Update" = NOW()
    WHERE "No_Bukti" = p_no_bukti;
  ELSE
    UPDATE public."BS_trPenarikan"
    SET "Status" = 'REJECTED',
        "Disetujui" = FALSE,
        "DisetujuiTgl" = NOW(),
        "DisetujuiUserID" = v_User_ID,
        "Keterangan" = COALESCE(NULLIF(TRIM(p_keterangan), ''), "Keterangan"),
        "Tgl_Update" = NOW()
    WHERE "No_Bukti" = p_no_bukti;
  END IF;

  RETURN jsonb_build_object(
    'ok', TRUE,
    'no_bukti', p_no_bukti,
    'status', CASE WHEN p_approve THEN 'APPROVED' ELSE 'REJECTED' END
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

REVOKE ALL ON FUNCTION "private"."bs_approve_penarikan_impl"(VARCHAR, BOOLEAN, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "private"."bs_approve_penarikan_impl"(VARCHAR, BOOLEAN, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public."bs_approve_penarikan"(
  p_no_bukti VARCHAR,
  p_approve BOOLEAN,
  p_keterangan TEXT DEFAULT NULL
) RETURNS JSONB AS $$
  SELECT "private"."bs_approve_penarikan_impl"(p_no_bukti, p_approve, p_keterangan);
$$ LANGUAGE sql SECURITY INVOKER SET search_path = public, private;

GRANT EXECUTE ON FUNCTION public."bs_approve_penarikan"(VARCHAR, BOOLEAN, TEXT) TO authenticated;


CREATE OR REPLACE FUNCTION "private"."bs_pay_penarikan_impl"(
  p_no_bukti VARCHAR,
  p_bukti_transfer_url TEXT DEFAULT NULL,
  p_keterangan TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_User_ID INT;
  v_Penarikan RECORD;
  v_SaldoTersedia NUMERIC(14,2);
BEGIN
  IF NOT "private"."currentUserIsAdmin"() THEN
    RAISE EXCEPTION 'unauthorized: hanya admin yang dapat memproses pembayaran penarikan'
      USING ERRCODE = 'P0001';
  END IF;

  v_User_ID := "private"."currentUserID"();

  SELECT *
  INTO v_Penarikan
  FROM public."BS_trPenarikan"
  WHERE "No_Bukti" = p_no_bukti
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'transaksi penarikan tidak ditemukan: %', p_no_bukti
      USING ERRCODE = 'P0001';
  END IF;

  -- Allow paying either directly from PENDING or APPROVED, but NOT PAID/REJECTED
  IF v_Penarikan."Status" NOT IN ('PENDING', 'APPROVED') THEN
    RAISE EXCEPTION 'transaksi penarikan tidak bisa dibayar: status saat ini %', v_Penarikan."Status"
      USING ERRCODE = 'P0001';
  END IF;

  IF NOT "private"."userHasAccessToUnit"(v_Penarikan."UnitBisnisID") THEN
    RAISE EXCEPTION 'unauthorized: tidak punya akses ke OPD transaksi ini'
      USING ERRCODE = 'P0001';
  END IF;

  -- Check available balance again just to be absolutely sure before paying
  SELECT COALESCE("Saldo_Tersedia", 0)
  INTO v_SaldoTersedia
  FROM public."BS_tSaldoPegawai"
  WHERE "Pegawai_ID" = v_Penarikan."Pegawai_ID"
  FOR UPDATE;

  IF v_SaldoTersedia < v_Penarikan."Jumlah" THEN
    RAISE EXCEPTION 'saldo tersedia tidak mencukupi untuk pembayaran ini'
      USING ERRCODE = 'P0001';
  END IF;

  -- Update Penarikan status to PAID
  UPDATE public."BS_trPenarikan"
  SET "Status" = 'PAID',
      "Tgl_Bayar" = NOW(),
      "User_Bayar" = v_User_ID,
      "Bukti_Transfer_URL" = NULLIF(TRIM(p_bukti_transfer_url), ''),
      "Posting_Saldo" = TRUE,
      "Keterangan" = COALESCE(NULLIF(TRIM(p_keterangan), ''), "Keterangan"),
      "Tgl_Update" = NOW()
  WHERE "No_Bukti" = p_no_bukti;

  -- Insert Mutasi Saldo (702 - Penarikan Saldo Pegawai)
  INSERT INTO public."BS_trMutasiSaldo"(
    "Pegawai_ID",
    "JTransaksi_ID",
    "No_Bukti_Ref",
    "Pending_Debit",
    "Pending_Kredit",
    "Tersedia_Debit",
    "Tersedia_Kredit",
    "Tgl_Mutasi",
    "Keterangan",
    "User_ID",
    "UnitBisnisID"
  )
  VALUES (
    v_Penarikan."Pegawai_ID",
    702,
    p_no_bukti,
    0,
    0,
    v_Penarikan."Jumlah",
    0,
    NOW(),
    FORMAT('Penarikan saldo %s Rp %s', CASE WHEN v_Penarikan."Type_Pembayaran" = 'T' THEN 'Transfer Bank' ELSE 'Tunai' END, v_Penarikan."Jumlah"),
    v_User_ID,
    v_Penarikan."UnitBisnisID"
  );

  -- Update Total_Ditarik on SaldoPegawai
  UPDATE public."BS_tSaldoPegawai"
  SET "Total_Ditarik" = "Total_Ditarik" + v_Penarikan."Jumlah",
      "Tgl_Update" = NOW()
  WHERE "Pegawai_ID" = v_Penarikan."Pegawai_ID";

  RETURN jsonb_build_object(
    'ok', TRUE,
    'no_bukti', p_no_bukti,
    'jumlah', v_Penarikan."Jumlah",
    'status', 'PAID'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

REVOKE ALL ON FUNCTION "private"."bs_pay_penarikan_impl"(VARCHAR, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "private"."bs_pay_penarikan_impl"(VARCHAR, TEXT, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public."bs_pay_penarikan"(
  p_no_bukti VARCHAR,
  p_bukti_transfer_url TEXT DEFAULT NULL,
  p_keterangan TEXT DEFAULT NULL
) RETURNS JSONB AS $$
  SELECT "private"."bs_pay_penarikan_impl"(p_no_bukti, p_bukti_transfer_url, p_keterangan);
$$ LANGUAGE sql SECURITY INVOKER SET search_path = public, private;

GRANT EXECUTE ON FUNCTION public."bs_pay_penarikan"(VARCHAR, TEXT, TEXT) TO authenticated;
