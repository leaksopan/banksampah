CREATE OR REPLACE FUNCTION "private"."BS_AlokasiPenjualanFifo"(
  p_detail_id_penjualan BIGINT
) RETURNS NUMERIC AS $$
DECLARE
  v_Detail RECORD;
  v_Penjualan RECORD;
  v_Layer RECORD;
  v_QtyDibutuhkan NUMERIC(14,3);
  v_QtyAmbil NUMERIC(14,3);
  v_SelisihPerKg NUMERIC(14,2);
  v_NilaiEstimasi NUMERIC(14,2);
  v_NilaiRealisasi NUMERIC(14,2);
  v_FIFOKeluarID BIGINT;
  v_TotalHpp NUMERIC(14,2) := 0;
BEGIN
  SELECT *
  INTO v_Detail
  FROM public."BS_trPenjualanDetail"
  WHERE "Detail_ID" = p_detail_id_penjualan
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'detail penjualan tidak ditemukan: %', p_detail_id_penjualan
      USING ERRCODE = 'P0001';
  END IF;

  SELECT *
  INTO v_Penjualan
  FROM public."BS_trPenjualan"
  WHERE "No_Bukti" = v_Detail."No_Bukti"
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'header penjualan tidak ditemukan untuk detail: %', p_detail_id_penjualan
      USING ERRCODE = 'P0001';
  END IF;

  v_QtyDibutuhkan := v_Detail."Qty";

  FOR v_Layer IN
    SELECT *
    FROM public."BS_trStockLayer"
    WHERE "UnitBisnisID" = v_Penjualan."UnitBisnisID"
      AND "Lokasi_ID" = v_Penjualan."Lokasi_ID"
      AND "Sampah_ID" = v_Detail."Sampah_ID"
      AND "Status" = 'ACTIVE'
      AND "Qty_Sisa" > 0
    ORDER BY "Tgl_Masuk" ASC, "Layer_ID" ASC
    FOR UPDATE
  LOOP
    EXIT WHEN v_QtyDibutuhkan <= 0.001;

    v_QtyAmbil := LEAST(v_Layer."Qty_Sisa", v_QtyDibutuhkan);
    v_SelisihPerKg := v_Detail."Harga_Jual" - v_Layer."Harga_Beli";
    v_NilaiEstimasi := ROUND(v_Layer."Harga_Beli" * v_QtyAmbil, 2);
    v_NilaiRealisasi := ROUND(v_Detail."Harga_Jual" * v_QtyAmbil, 2);

    INSERT INTO public."BS_trKartuFIFO_Keluar"(
      "Lokasi_ID",
      "Sampah_ID",
      "No_Bukti",
      "Detail_ID_Penjualan",
      "Layer_ID",
      "Pegawai_ID",
      "Qty_Keluar",
      "Harga_Beli",
      "Harga_Jual",
      "Selisih_PerKg",
      "Total_Selisih",
      "NoBuktiAsal",
      "UnitBisnisID"
    )
    VALUES (
      v_Penjualan."Lokasi_ID",
      v_Detail."Sampah_ID",
      v_Penjualan."No_Bukti",
      p_detail_id_penjualan,
      v_Layer."Layer_ID",
      v_Layer."Pegawai_ID",
      v_QtyAmbil,
      v_Layer."Harga_Beli",
      v_Detail."Harga_Jual",
      v_SelisihPerKg,
      ROUND(v_SelisihPerKg * v_QtyAmbil, 2),
      v_Layer."No_Bukti_Setoran",
      v_Penjualan."UnitBisnisID"
    )
    RETURNING "FIFOKeluar_ID" INTO v_FIFOKeluarID;

    UPDATE public."BS_trStockLayer"
    SET
      "Qty_Sisa" = "Qty_Sisa" - v_QtyAmbil,
      "Status" = CASE
        WHEN ("Qty_Sisa" - v_QtyAmbil) <= 0.001 THEN 'EXHAUSTED'
        ELSE 'ACTIVE'
      END
    WHERE "Layer_ID" = v_Layer."Layer_ID";

    INSERT INTO public."BS_trMutasiSaldo"(
      "Pegawai_ID",
      "JTransaksi_ID",
      "No_Bukti_Ref",
      "FIFOKeluar_ID_Ref",
      "Pending_Debit",
      "Tersedia_Kredit",
      "Tgl_Mutasi",
      "Keterangan",
      "User_ID",
      "UnitBisnisID"
    )
    VALUES (
      v_Layer."Pegawai_ID",
      701,
      v_Penjualan."No_Bukti",
      v_FIFOKeluarID,
      v_NilaiEstimasi,
      v_NilaiRealisasi,
      v_Penjualan."Tgl_Penjualan",
      FORMAT(
        'Realisasi penjualan %s kg @ %s; estimasi %s, realisasi %s',
        v_QtyAmbil,
        v_Detail."Harga_Jual",
        v_NilaiEstimasi,
        v_NilaiRealisasi
      ),
      v_Penjualan."User_ID",
      v_Penjualan."UnitBisnisID"
    );

    v_TotalHpp := v_TotalHpp + v_NilaiEstimasi;
    v_QtyDibutuhkan := v_QtyDibutuhkan - v_QtyAmbil;
  END LOOP;

  IF v_QtyDibutuhkan > 0.001 THEN
    RAISE EXCEPTION 'stok tidak cukup untuk sampah %, sisa kebutuhan % kg', v_Detail."Sampah_ID", v_QtyDibutuhkan
      USING ERRCODE = 'P0001';
  END IF;

  UPDATE public."BS_trPenjualanDetail"
  SET "Total_HPP_Detail" = v_TotalHpp
  WHERE "Detail_ID" = p_detail_id_penjualan;

  RETURN v_TotalHpp;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

REVOKE ALL ON FUNCTION "private"."BS_AlokasiPenjualanFifo"(BIGINT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "private"."BS_AlokasiPenjualanFifo"(BIGINT) TO authenticated;

CREATE OR REPLACE FUNCTION "private"."bs_create_penjualan_impl"(
  p_vendor_id INT,
  p_lokasi_id INT,
  p_type_pembayaran TEXT DEFAULT 'C',
  p_keterangan TEXT DEFAULT NULL,
  p_details JSONB DEFAULT '[]'::jsonb
) RETURNS JSONB AS $$
DECLARE
  v_User_ID INT;
  v_UnitBisnisID INT;
  v_LokasiUnitBisnisID INT;
  v_NoBukti VARCHAR(50);
  v_TypePembayaran CHAR(1);
  v_Detail JSONB;
  v_Sampah RECORD;
  v_SampahID INT;
  v_Qty NUMERIC(14,3);
  v_HargaJual NUMERIC(14,2);
  v_Subtotal NUMERIC(14,2);
  v_StokTersedia NUMERIC(14,3);
  v_TotalBerat NUMERIC(14,3) := 0;
  v_TotalNilai NUMERIC(14,2) := 0;
  v_TotalHpp NUMERIC(14,2) := 0;
  v_TotalHppDetail NUMERIC(14,2);
  v_NoUrut SMALLINT := 0;
  v_DetailID BIGINT;
  v_SeenSampah INT[] := ARRAY[]::INT[];
BEGIN
  IF NOT "private"."currentUserIsAdmin"() THEN
    RAISE EXCEPTION 'unauthorized: hanya admin yang dapat input penjualan'
      USING ERRCODE = 'P0001';
  END IF;

  IF jsonb_typeof(p_details) IS DISTINCT FROM 'array' OR jsonb_array_length(p_details) = 0 THEN
    RAISE EXCEPTION 'detail penjualan wajib diisi'
      USING ERRCODE = 'P0001';
  END IF;

  v_TypePembayaran := UPPER(COALESCE(NULLIF(TRIM(p_type_pembayaran), ''), 'C'))::CHAR(1);
  IF v_TypePembayaran NOT IN ('C', 'T') THEN
    RAISE EXCEPTION 'type pembayaran tidak valid: %', p_type_pembayaran
      USING ERRCODE = 'P0001';
  END IF;

  v_User_ID := "private"."currentUserID"();

  SELECT "UnitBisnisID"
  INTO v_UnitBisnisID
  FROM public."mVendor"
  WHERE "Vendor_ID" = p_vendor_id
    AND "Status_Aktif" = TRUE
  LIMIT 1;

  IF v_UnitBisnisID IS NULL THEN
    RAISE EXCEPTION 'vendor tidak ditemukan atau tidak aktif: %', p_vendor_id
      USING ERRCODE = 'P0001';
  END IF;

  IF NOT "private"."userHasAccessToUnit"(v_UnitBisnisID) THEN
    RAISE EXCEPTION 'unauthorized: tidak punya akses ke OPD vendor'
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
    RAISE EXCEPTION 'lokasi dan vendor berbeda OPD'
      USING ERRCODE = 'P0001';
  END IF;

  FOR v_Detail IN SELECT value FROM jsonb_array_elements(p_details)
  LOOP
    v_NoUrut := v_NoUrut + 1;
    v_SampahID := COALESCE(
      NULLIF(v_Detail ->> 'Sampah_ID', '')::INT,
      NULLIF(v_Detail ->> 'sampah_id', '')::INT,
      NULLIF(v_Detail ->> 'sampahId', '')::INT
    );

    IF v_SampahID IS NULL THEN
      RAISE EXCEPTION 'sampah detail ke-% wajib diisi', v_NoUrut
        USING ERRCODE = 'P0001';
    END IF;

    IF v_SampahID = ANY(v_SeenSampah) THEN
      RAISE EXCEPTION 'sampah detail ke-% dobel dalam satu penjualan', v_NoUrut
        USING ERRCODE = 'P0001';
    END IF;
    v_SeenSampah := array_append(v_SeenSampah, v_SampahID);

    v_Qty := COALESCE(
      NULLIF(v_Detail ->> 'Qty', '')::NUMERIC,
      NULLIF(v_Detail ->> 'qty', '')::NUMERIC
    );
    v_HargaJual := COALESCE(
      NULLIF(v_Detail ->> 'Harga_Jual', '')::NUMERIC,
      NULLIF(v_Detail ->> 'harga_jual', '')::NUMERIC,
      NULLIF(v_Detail ->> 'hargaJual', '')::NUMERIC
    );

    IF v_Qty IS NULL OR v_Qty <= 0 THEN
      RAISE EXCEPTION 'qty detail ke-% harus lebih dari 0', v_NoUrut
        USING ERRCODE = 'P0001';
    END IF;

    IF v_HargaJual IS NULL OR v_HargaJual < 0 THEN
      RAISE EXCEPTION 'harga jual detail ke-% tidak valid', v_NoUrut
        USING ERRCODE = 'P0001';
    END IF;

    SELECT
      s."Sampah_ID",
      s."Kode_Satuan",
      s."UnitBisnisID",
      s."Aktif"
    INTO v_Sampah
    FROM public."mSampah" s
    WHERE s."Sampah_ID" = v_SampahID
    LIMIT 1;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'sampah detail ke-% tidak ditemukan', v_NoUrut
        USING ERRCODE = 'P0001';
    END IF;

    IF v_Sampah."UnitBisnisID" <> v_UnitBisnisID OR v_Sampah."Aktif" = FALSE THEN
      RAISE EXCEPTION 'sampah detail ke-% tidak aktif atau berbeda OPD', v_NoUrut
        USING ERRCODE = 'P0001';
    END IF;

    SELECT COALESCE(SUM(sl."Qty_Sisa"), 0)
    INTO v_StokTersedia
    FROM public."BS_trStockLayer" sl
    WHERE sl."UnitBisnisID" = v_UnitBisnisID
      AND sl."Lokasi_ID" = p_lokasi_id
      AND sl."Sampah_ID" = v_SampahID
      AND sl."Status" = 'ACTIVE'
      AND sl."Qty_Sisa" > 0;

    IF v_StokTersedia + 0.001 < v_Qty THEN
      RAISE EXCEPTION 'stok % kg tidak cukup untuk detail ke-%; butuh % kg', v_StokTersedia, v_NoUrut, v_Qty
        USING ERRCODE = 'P0001';
    END IF;
  END LOOP;

  v_NoBukti := "private"."BS_GenerateNoBuktiImpl"(v_UnitBisnisID, 'BSJ', NOW());

  INSERT INTO public."BS_trPenjualan"(
    "No_Bukti",
    "Tgl_Penjualan",
    "Vendor_ID",
    "Lokasi_ID",
    "Total_Berat",
    "Total_Nilai",
    "Total_HPP",
    "Total_Selisih",
    "Type_Pembayaran",
    "Keterangan",
    "User_ID",
    "Tgl_Update",
    "Jam_Posting",
    "HostName",
    "Status_Batal",
    "Posting_KG",
    "Posting_Saldo",
    "Posted",
    "Disetujui",
    "DisetujuiTgl",
    "DisetujuiUserID",
    "UnitBisnisID"
  )
  VALUES (
    v_NoBukti,
    NOW(),
    p_vendor_id,
    p_lokasi_id,
    0,
    0,
    0,
    0,
    v_TypePembayaran,
    NULLIF(TRIM(p_keterangan), ''),
    v_User_ID,
    NOW(),
    NOW(),
    'supabase-rpc',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    TRUE,
    NOW(),
    v_User_ID,
    v_UnitBisnisID
  );

  v_NoUrut := 0;

  FOR v_Detail IN SELECT value FROM jsonb_array_elements(p_details)
  LOOP
    v_NoUrut := v_NoUrut + 1;
    v_SampahID := COALESCE(
      NULLIF(v_Detail ->> 'Sampah_ID', '')::INT,
      NULLIF(v_Detail ->> 'sampah_id', '')::INT,
      NULLIF(v_Detail ->> 'sampahId', '')::INT
    );
    v_Qty := COALESCE(
      NULLIF(v_Detail ->> 'Qty', '')::NUMERIC,
      NULLIF(v_Detail ->> 'qty', '')::NUMERIC
    );
    v_HargaJual := COALESCE(
      NULLIF(v_Detail ->> 'Harga_Jual', '')::NUMERIC,
      NULLIF(v_Detail ->> 'harga_jual', '')::NUMERIC,
      NULLIF(v_Detail ->> 'hargaJual', '')::NUMERIC
    );

    SELECT
      s."Sampah_ID",
      s."Kode_Satuan"
    INTO v_Sampah
    FROM public."mSampah" s
    WHERE s."Sampah_ID" = v_SampahID
    LIMIT 1;

    v_Subtotal := ROUND(v_Qty * v_HargaJual, 2);
    v_TotalBerat := v_TotalBerat + v_Qty;
    v_TotalNilai := v_TotalNilai + v_Subtotal;

    INSERT INTO public."BS_trPenjualanDetail"(
      "No_Bukti",
      "Sampah_ID",
      "Kode_Satuan",
      "Qty",
      "Harga_Jual",
      "Subtotal",
      "Total_HPP_Detail",
      "NoUrut"
    )
    VALUES (
      v_NoBukti,
      v_Sampah."Sampah_ID",
      v_Sampah."Kode_Satuan",
      v_Qty,
      v_HargaJual,
      v_Subtotal,
      0,
      v_NoUrut
    )
    RETURNING "Detail_ID" INTO v_DetailID;

    v_TotalHppDetail := "private"."BS_AlokasiPenjualanFifo"(v_DetailID);
    v_TotalHpp := v_TotalHpp + v_TotalHppDetail;

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
      701,
      NOW(),
      v_Sampah."Kode_Satuan",
      0,
      0,
      v_Qty,
      v_HargaJual,
      v_UnitBisnisID
    );
  END LOOP;

  UPDATE public."BS_trPenjualan"
  SET
    "Total_Berat" = v_TotalBerat,
    "Total_Nilai" = v_TotalNilai,
    "Total_HPP" = v_TotalHpp,
    "Total_Selisih" = v_TotalNilai - v_TotalHpp,
    "Posting_KG" = TRUE,
    "Posting_Saldo" = TRUE,
    "Posted" = TRUE,
    "Tgl_Update" = NOW(),
    "Jam_Posting" = NOW()
  WHERE "No_Bukti" = v_NoBukti;

  UPDATE public."BS_tSaldoPegawai" saldo
  SET
    "Total_Berat_Terjual" = COALESCE(saldo."Total_Berat_Terjual", 0) + fifo.total_qty,
    "Tgl_Update" = NOW()
  FROM (
    SELECT
      "Pegawai_ID",
      SUM("Qty_Keluar") AS total_qty
    FROM public."BS_trKartuFIFO_Keluar"
    WHERE "No_Bukti" = v_NoBukti
    GROUP BY "Pegawai_ID"
  ) fifo
  WHERE saldo."Pegawai_ID" = fifo."Pegawai_ID";

  RETURN jsonb_build_object(
    'ok', TRUE,
    'no_bukti', v_NoBukti,
    'vendor_id', p_vendor_id,
    'lokasi_id', p_lokasi_id,
    'total_berat', v_TotalBerat,
    'total_nilai', v_TotalNilai,
    'total_hpp', v_TotalHpp,
    'total_selisih', v_TotalNilai - v_TotalHpp,
    'detail_count', v_NoUrut
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

REVOKE ALL ON FUNCTION "private"."bs_create_penjualan_impl"(INT, INT, TEXT, TEXT, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "private"."bs_create_penjualan_impl"(INT, INT, TEXT, TEXT, JSONB) TO authenticated;

CREATE OR REPLACE FUNCTION public."bs_create_penjualan"(
  p_vendor_id INT,
  p_lokasi_id INT,
  p_type_pembayaran TEXT DEFAULT 'C',
  p_keterangan TEXT DEFAULT NULL,
  p_details JSONB DEFAULT '[]'::jsonb
) RETURNS JSONB AS $$
  SELECT "private"."bs_create_penjualan_impl"(p_vendor_id, p_lokasi_id, p_type_pembayaran, p_keterangan, p_details);
$$ LANGUAGE sql SECURITY INVOKER SET search_path = public, private;

GRANT EXECUTE ON FUNCTION public."bs_create_penjualan"(INT, INT, TEXT, TEXT, JSONB) TO authenticated;
