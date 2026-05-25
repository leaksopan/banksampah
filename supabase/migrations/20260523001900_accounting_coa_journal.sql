-- 20260523001900_accounting_coa_journal.sql

-- 1. Create mCOA table
CREATE TABLE public."mCOA" (
  "COA_ID"            VARCHAR(10) PRIMARY KEY,
  "COA_Name"          VARCHAR(150) NOT NULL,
  "Kategori_COA"      VARCHAR(30) NOT NULL, -- 'AKTIVA_LANCAR', 'AKTIVA_TETAP', 'KEWAJIBAN', 'EKUITAS', 'PENDAPATAN', 'BEBAN_HPP'
  "Normal_Balance"    VARCHAR(2) NOT NULL, -- 'D' or 'K'
  "Status_Aktif"      BOOLEAN NOT NULL DEFAULT TRUE,
  "Tgl_Update"        TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public."mCOA" OWNER TO postgres;

-- Seed standard COA for SAK-EMKM Bank Sampah
INSERT INTO public."mCOA" ("COA_ID", "COA_Name", "Kategori_COA", "Normal_Balance") VALUES
('1101', 'Kas dan Bank TPS', 'AKTIVA_LANCAR', 'D'),
('1102', 'Piutang Dagang Vendor', 'AKTIVA_LANCAR', 'D'),
('1103', 'Persediaan Sampah - Estimasi', 'AKTIVA_LANCAR', 'D'),
('2101', 'Hutang Nasabah - Tersedia', 'KEWAJIBAN', 'K'),
('2102', 'Hutang Estimasi Nasabah - Pending', 'KEWAJIBAN', 'K'),
('3101', 'Modal Awal Coop/TPS', 'EKUITAS', 'K'),
('3102', 'Saldo Laba Ditahan', 'EKUITAS', 'K'),
('4101', 'Pendapatan Penjualan Sampah', 'PENDAPATAN', 'K'),
('4102', 'Pendapatan Penyesuaian Saldo Nasabah', 'PENDAPATAN', 'K'),
('5101', 'Harga Pokok Penjualan (HPP) Sampah', 'BEBAN_HPP', 'D'),
('5102', 'Beban Penyesuaian Saldo Nasabah', 'BEBAN_HPP', 'D')
ON CONFLICT ("COA_ID") DO NOTHING;

-- 2. Create Journal Header & Detail tables
CREATE TABLE public."BS_trJurnal" (
  "No_Jurnal"         VARCHAR(50) PRIMARY KEY,
  "Tgl_Jurnal"        TIMESTAMPTZ NOT NULL,
  "Keterangan"        VARCHAR(250),
  "No_Bukti_Ref"      VARCHAR(50) NOT NULL,
  "Posted"            BOOLEAN NOT NULL DEFAULT TRUE,
  "UnitBisnisID"      INT NOT NULL REFERENCES public."mUnitBisnis",
  "Tgl_Update"        TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public."BS_trJurnal" OWNER TO postgres;
CREATE INDEX "idx_BS_Jurnal_Ref" ON public."BS_trJurnal"("No_Bukti_Ref");
CREATE INDEX "idx_BS_Jurnal_Unit_Tgl" ON public."BS_trJurnal"("UnitBisnisID", "Tgl_Jurnal" DESC);

CREATE TABLE public."BS_trJurnalDetail" (
  "JurnalDetail_ID"   BIGSERIAL PRIMARY KEY,
  "No_Jurnal"         VARCHAR(50) NOT NULL REFERENCES public."BS_trJurnal" ON DELETE CASCADE,
  "COA_ID"            VARCHAR(10) NOT NULL REFERENCES public."mCOA",
  "Debit"             NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK ("Debit" >= 0),
  "Kredit"            NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK ("Kredit" >= 0),
  "Keterangan"        VARCHAR(250),
  CONSTRAINT "chk_BS_Jurnal_DebKred" CHECK (("Debit" > 0 AND "Kredit" = 0) OR ("Kredit" > 0 AND "Debit" = 0))
);

ALTER TABLE public."BS_trJurnalDetail" OWNER TO postgres;
CREATE INDEX "idx_BS_JurnalDetail_NoJurnal" ON public."BS_trJurnalDetail"("No_Jurnal");
CREATE INDEX "idx_BS_JurnalDetail_COA" ON public."BS_trJurnalDetail"("COA_ID");

-- RLS and Grant Policies
ALTER TABLE public."mCOA" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow authenticated read mCOA" ON public."mCOA" FOR SELECT TO authenticated USING (TRUE);

ALTER TABLE public."BS_trJurnal" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow access BS_trJurnal per unit" ON public."BS_trJurnal"
  FOR ALL TO authenticated USING ("private"."userHasAccessToUnit"("UnitBisnisID"));

ALTER TABLE public."BS_trJurnalDetail" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow access BS_trJurnalDetail via header" ON public."BS_trJurnalDetail"
  FOR ALL TO authenticated USING (
    EXISTS (
      SELECT 1 FROM public."BS_trJurnal" j
      WHERE j."No_Jurnal" = "BS_trJurnalDetail"."No_Jurnal"
        AND "private"."userHasAccessToUnit"(j."UnitBisnisID")
    )
  );

GRANT SELECT ON TABLE public."mCOA" TO authenticated;
GRANT SELECT ON TABLE public."BS_trJurnal" TO authenticated;
GRANT SELECT ON TABLE public."BS_trJurnalDetail" TO authenticated;

-- Helper to safely write journal entries in PL/pgSQL
CREATE OR REPLACE FUNCTION private.bs_write_journal_entry(
  p_no_bukti_ref VARCHAR(50),
  p_tgl TIMESTAMPTZ,
  p_keterangan VARCHAR(250),
  p_unit_id INT,
  p_details JSONB -- Array of object: [{"COA_ID": "...", "Debit": 100, "Kredit": 0, "Keterangan": "..."}]
) RETURNS VOID AS $$
DECLARE
  v_NoJurnal VARCHAR(50);
  v_Item RECORD;
  v_TotalDebit NUMERIC(14,2) := 0;
  v_TotalKredit NUMERIC(14,2) := 0;
BEGIN
  -- 1. Check if journal already exists for this reference (delete old to make it idempotent)
  DELETE FROM public."BS_trJurnal" WHERE "No_Bukti_Ref" = p_no_bukti_ref;

  -- 2. Validate balance
  FOR v_Item IN SELECT * FROM jsonb_to_recordset(p_details) AS x("COA_ID" VARCHAR, "Debit" NUMERIC(14,2), "Kredit" NUMERIC(14,2)) LOOP
    v_TotalDebit := v_TotalDebit + COALESCE(v_Item."Debit", 0);
    v_TotalKredit := v_TotalKredit + COALESCE(v_Item."Kredit", 0);
  END LOOP;

  IF ABS(v_TotalDebit - v_TotalKredit) > 0.01 THEN
    RAISE EXCEPTION 'Jurnal tidak balance! Total Debit: %, Total Kredit: %', v_TotalDebit, v_TotalKredit
      USING ERRCODE = 'P0001';
  END IF;

  -- 3. Insert header (use No_Bukti_Ref prefixed with 'JUR-' as No_Jurnal)
  v_NoJurnal := 'JUR-' || p_no_bukti_ref;
  
  INSERT INTO public."BS_trJurnal"("No_Jurnal", "Tgl_Jurnal", "Keterangan", "No_Bukti_Ref", "UnitBisnisID")
  VALUES (v_NoJurnal, p_tgl, p_keterangan, p_no_bukti_ref, p_unit_id);

  -- 4. Insert details
  FOR v_Item IN 
    SELECT 
      (x->>'COA_ID')::VARCHAR(10) AS coa_id, 
      (x->>'Debit')::NUMERIC(14,2) AS deb, 
      (x->>'Kredit')::NUMERIC(14,2) AS kred, 
      (x->>'Keterangan')::VARCHAR(250) AS ket 
    FROM jsonb_array_elements(p_details) AS x
  LOOP
    IF COALESCE(v_Item.deb, 0) > 0 OR COALESCE(v_Item.kred, 0) > 0 THEN
      INSERT INTO public."BS_trJurnalDetail"("No_Jurnal", "COA_ID", "Debit", "Kredit", "Keterangan")
      VALUES (v_NoJurnal, v_Item.coa_id, COALESCE(v_Item.deb, 0), COALESCE(v_Item.kred, 0), v_Item.ket);
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

-- 3. Automatic Journal Triggers

-- A. Setoran Jurnal Trigger (JTransaksi_ID = 700)
CREATE OR REPLACE FUNCTION public."BS_TrgJurnalSetoran"() RETURNS TRIGGER AS $$
DECLARE
  v_Details JSONB;
BEGIN
  -- Auto-generate journal ONLY when Setoran is POSTED and NOT Cancelled (Status_Batal = FALSE)
  IF NEW."Posted" = TRUE AND NEW."Status_Batal" = FALSE THEN
    v_Details := JSONB_BUILD_ARRAY(
      JSONB_BUILD_OBJECT(
        'COA_ID', '1103',
        'Debit', NEW."Total_Nilai",
        'Kredit', 0.00,
        'Keterangan', FORMAT('Penerimaan persediaan sampah dari setoran %s', NEW."No_Bukti")
      ),
      JSONB_BUILD_OBJECT(
        'COA_ID', '2102',
        'Debit', 0.00,
        'Kredit', NEW."Total_Nilai",
        'Keterangan', FORMAT('Pengakuan hutang estimasi nasabah pending dari setoran %s', NEW."No_Bukti")
      )
    );

    PERFORM private.bs_write_journal_entry(
      NEW."No_Bukti",
      NEW."Tgl_Setoran",
      FORMAT('Jurnal Otomatis Setoran Nasabah %s', NEW."No_Bukti"),
      NEW."UnitBisnisID",
      v_Details
    );
  ELSIF NEW."Status_Batal" = TRUE THEN
    -- If Voided, remove any generated journal for this reference
    DELETE FROM public."BS_trJurnal" WHERE "No_Bukti_Ref" = NEW."No_Bukti";
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

CREATE TRIGGER "trg_BS_JurnalSetoran"
AFTER INSERT OR UPDATE OF "Posted", "Status_Batal" ON public."BS_trSetoran"
FOR EACH ROW EXECUTE FUNCTION public."BS_TrgJurnalSetoran"();


-- B. Penjualan Jurnal Trigger (JTransaksi_ID = 701)
CREATE OR REPLACE FUNCTION public."BS_TrgJurnalPenjualan"() RETURNS TRIGGER AS $$
DECLARE
  v_Details JSONB;
  v_Selisih NUMERIC(14,2);
  v_Hpp NUMERIC(14,2);
  v_Nilai Jual NUMERIC(14,2);
BEGIN
  IF NEW."Posted" = TRUE AND NEW."Status_Batal" = FALSE THEN
    v_Hpp := NEW."Total_HPP";
    v_Nilai := NEW."Total_Nilai";
    v_Selisih := NEW."Total_Selisih"; -- Jual - Beli (HPP)

    -- Base elements:
    -- 1. Debit Kas/Bank (1101) = Uang penjualan aktual
    -- 2. Kredit Pendapatan Penjualan (4101) = Uang penjualan aktual
    -- 3. Debit HPP Sampah (5101) = Nilai estimasi tumpukan FIFO
    -- 4. Kredit Persediaan Sampah - Estimasi (1103) = Nilai estimasi tumpukan FIFO
    -- 5. Debit Hutang Estimasi Nasabah - Pending (2102) = Nilai estimasi tumpukan FIFO
    -- 6. Kredit Hutang Nasabah - Tersedia (2101) = Uang penjualan aktual
    
    -- Now let's balance them:
    -- If Harga Jual < Harga Beli (Selisih < 0): e.g. Beli 25.000, Jual 20.000 (Selisih = -5.000)
    -- Debits: Kas/Bank (20k) + HPP (25k) + Hutang Pending (25k) = 70k
    -- Credits: Pendapatan (20k) + Persediaan (25k) + Hutang Tersedia (20k) = 65k
    -- Need Credit 5k to balance: Kredit Pendapatan Penyesuaian Saldo Nasabah (4102) = 5.000
    
    -- If Harga Jual > Harga Beli (Selisih > 0): e.g. Beli 25.000, Jual 30.000 (Selisih = 5.000)
    -- Debits: Kas/Bank (30k) + HPP (25k) + Hutang Pending (25k) = 80k
    -- Credits: Pendapatan (30k) + Persediaan (25k) + Hutang Tersedia (30k) = 85k
    -- Need Debit 5k to balance: Debit Beban Penyesuaian Saldo Nasabah (5102) = 5.000
    
    IF v_Selisih < 0 THEN
      -- Price dropped
      v_Details := JSONB_BUILD_ARRAY(
        JSONB_BUILD_OBJECT('COA_ID', '1101', 'Debit', v_Nilai, 'Kredit', 0.00, 'Keterangan', 'Kas masuk penjualan sampah'),
        JSONB_BUILD_OBJECT('COA_ID', '4101', 'Debit', 0.00, 'Kredit', v_Nilai, 'Keterangan', 'Pendapatan penjualan sampah ke vendor'),
        JSONB_BUILD_OBJECT('COA_ID', '5101', 'Debit', v_Hpp, 'Kredit', 0.00, 'Keterangan', 'HPP sampah keluar (FIFO)'),
        JSONB_BUILD_OBJECT('COA_ID', '1103', 'Debit', 0.00, 'Kredit', v_Hpp, 'Keterangan', 'Pengurangan persediaan sampah (FIFO)'),
        JSONB_BUILD_OBJECT('COA_ID', '2102', 'Debit', v_Hpp, 'Kredit', 0.00, 'Keterangan', 'Pelepasan hutang pending estimasi nasabah'),
        JSONB_BUILD_OBJECT('COA_ID', '2101', 'Debit', 0.00, 'Kredit', v_Nilai, 'Keterangan', 'Penerbitan hutang tersedia nasabah (realized)'),
        JSONB_BUILD_OBJECT('COA_ID', '4102', 'Debit', 0.00, 'Kredit', ABS(v_Selisih), 'Keterangan', 'Pendapatan penyesuaian penurunan nilai nasabah')
      );
    ELSIF v_Selisih > 0 THEN
      -- Price went up
      v_Details := JSONB_BUILD_ARRAY(
        JSONB_BUILD_OBJECT('COA_ID', '1101', 'Debit', v_Nilai, 'Kredit', 0.00, 'Keterangan', 'Kas masuk penjualan sampah'),
        JSONB_BUILD_OBJECT('COA_ID', '4101', 'Debit', 0.00, 'Kredit', v_Nilai, 'Keterangan', 'Pendapatan penjualan sampah ke vendor'),
        JSONB_BUILD_OBJECT('COA_ID', '5101', 'Debit', v_Hpp, 'Kredit', 0.00, 'Keterangan', 'HPP sampah keluar (FIFO)'),
        JSONB_BUILD_OBJECT('COA_ID', '1103', 'Debit', 0.00, 'Kredit', v_Hpp, 'Keterangan', 'Pengurangan persediaan sampah (FIFO)'),
        JSONB_BUILD_OBJECT('COA_ID', '2102', 'Debit', v_Hpp, 'Kredit', 0.00, 'Keterangan', 'Pelepasan hutang pending estimasi nasabah'),
        JSONB_BUILD_OBJECT('COA_ID', '2101', 'Debit', 0.00, 'Kredit', v_Nilai, 'Keterangan', 'Penerbitan hutang tersedia nasabah (realized)'),
        JSONB_BUILD_OBJECT('COA_ID', '5102', 'Debit', v_Selisih, 'Kredit', 0.00, 'Keterangan', 'Beban penyesuaian kenaikan nilai nasabah')
      );
    ELSE
      -- Sold at exact price
      v_Details := JSONB_BUILD_ARRAY(
        JSONB_BUILD_OBJECT('COA_ID', '1101', 'Debit', v_Nilai, 'Kredit', 0.00, 'Keterangan', 'Kas masuk penjualan sampah'),
        JSONB_BUILD_OBJECT('COA_ID', '4101', 'Debit', 0.00, 'Kredit', v_Nilai, 'Keterangan', 'Pendapatan penjualan sampah ke vendor'),
        JSONB_BUILD_OBJECT('COA_ID', '5101', 'Debit', v_Hpp, 'Kredit', 0.00, 'Keterangan', 'HPP sampah keluar (FIFO)'),
        JSONB_BUILD_OBJECT('COA_ID', '1103', 'Debit', 0.00, 'Kredit', v_Hpp, 'Keterangan', 'Pengurangan persediaan sampah (FIFO)'),
        JSONB_BUILD_OBJECT('COA_ID', '2102', 'Debit', v_Hpp, 'Kredit', 0.00, 'Keterangan', 'Pelepasan hutang pending estimasi nasabah'),
        JSONB_BUILD_OBJECT('COA_ID', '2101', 'Debit', 0.00, 'Kredit', v_Nilai, 'Keterangan', 'Penerbitan hutang tersedia nasabah (realized)')
      );
    END IF;

    PERFORM private.bs_write_journal_entry(
      NEW."No_Bukti",
      NEW."Tgl_Penjualan",
      FORMAT('Jurnal Otomatis Penjualan Vendor %s', NEW."No_Bukti"),
      NEW."UnitBisnisID",
      v_Details
    );
  ELSIF NEW."Status_Batal" = TRUE THEN
    DELETE FROM public."BS_trJurnal" WHERE "No_Bukti_Ref" = NEW."No_Bukti";
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

CREATE TRIGGER "trg_BS_JurnalPenjualan"
AFTER INSERT OR UPDATE OF "Posted", "Status_Batal" ON public."BS_trPenjualan"
FOR EACH ROW EXECUTE FUNCTION public."BS_TrgJurnalPenjualan"();


-- C. Penarikan Jurnal Trigger (JTransaksi_ID = 702)
CREATE OR REPLACE FUNCTION public."BS_TrgJurnalPenarikan"() RETURNS TRIGGER AS $$
DECLARE
  v_Details JSONB;
BEGIN
  -- Journal only generated when Status goes to 'PAID' (meaning cash has been paid out)
  IF NEW."Status" = 'PAID' AND NEW."Status_Batal" = FALSE THEN
    v_Details := JSONB_BUILD_ARRAY(
      JSONB_BUILD_OBJECT(
        'COA_ID', '2101',
        'Debit', NEW."Jumlah",
        'Kredit', 0.00,
        'Keterangan', FORMAT('Pembayaran hutang tersedia kepada nasabah via penarikan %s', NEW."No_Bukti")
      ),
      JSONB_BUILD_OBJECT(
        'COA_ID', '1101',
        'Debit', 0.00,
        'Kredit', NEW."Jumlah",
        'Keterangan', FORMAT('Pengeluaran kas untuk penarikan nasabah %s', NEW."No_Bukti")
      )
    );

    PERFORM private.bs_write_journal_entry(
      NEW."No_Bukti",
      NEW."Tgl_Penarikan",
      FORMAT('Jurnal Otomatis Penarikan Nasabah %s', NEW."No_Bukti"),
      NEW."UnitBisnisID",
      v_Details
    );
  ELSIF NEW."Status_Batal" = TRUE OR NEW."Status" = 'REJECTED' THEN
    DELETE FROM public."BS_trJurnal" WHERE "No_Bukti_Ref" = NEW."No_Bukti";
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

CREATE TRIGGER "trg_BS_JurnalPenarikan"
AFTER INSERT OR UPDATE OF "Status", "Status_Batal" ON public."BS_trPenarikan"
FOR EACH ROW EXECUTE FUNCTION public."BS_TrgJurnalPenarikan"();


-- 4. Reporting Views and Functions

-- Function to get the COA list
CREATE OR REPLACE FUNCTION public."bs_list_coa"()
RETURNS TABLE (
  "COA_ID" VARCHAR(10),
  "COA_Name" VARCHAR(150),
  "Kategori_COA" VARCHAR(30),
  "Normal_Balance" VARCHAR(2)
) AS $$
BEGIN
  RETURN QUERY
  SELECT c."COA_ID", c."COA_Name", c."Kategori_COA", c."Normal_Balance"
  FROM public."mCOA" c
  WHERE c."Status_Aktif" = TRUE
  ORDER BY c."COA_ID" ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public."bs_list_coa"() TO authenticated;


-- RPC bs_report_neraca
CREATE OR REPLACE FUNCTION public."bs_report_neraca"(
  p_unit_id INT,
  p_as_of_date TIMESTAMPTZ DEFAULT NOW()
) RETURNS TABLE (
  "COA_ID" VARCHAR(10),
  "COA_Name" VARCHAR(150),
  "Kategori_COA" VARCHAR(30),
  "Saldo" NUMERIC(14,2)
) AS $$
BEGIN
  -- Security check
  IF NOT "private"."userHasAccessToUnit"(p_unit_id) THEN
    RAISE EXCEPTION 'unauthorized: tidak punya akses ke OPD ini'
      USING ERRCODE = 'P0001';
  END IF;

  RETURN QUERY
  SELECT 
    c."COA_ID", 
    c."COA_Name", 
    c."Kategori_COA",
    COALESCE(
      SUM(
        CASE 
          WHEN c."Normal_Balance" = 'D' THEN jd."Debit" - jd."Kredit"
          ELSE jd."Kredit" - jd."Debit"
        END
      ), 
      0.00
    ) AS "Saldo"
  FROM public."mCOA" c
  LEFT JOIN public."BS_trJurnalDetail" jd ON jd."COA_ID" = c."COA_ID"
  LEFT JOIN public."BS_trJurnal" j ON j."No_Jurnal" = jd."No_Jurnal"
  WHERE c."Status_Aktif" = TRUE
    AND (j."No_Jurnal" IS NULL OR (j."UnitBisnisID" = p_unit_id AND j."Tgl_Jurnal" <= p_as_of_date))
  GROUP BY c."COA_ID", c."COA_Name", c."Kategori_COA"
  ORDER BY c."COA_ID" ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

GRANT EXECUTE ON FUNCTION public."bs_report_neraca"(INT, TIMESTAMPTZ) TO authenticated;


-- RPC bs_report_hpp_labarugi
CREATE OR REPLACE FUNCTION public."bs_report_hpp_labarugi"(
  p_unit_id INT,
  p_from TIMESTAMPTZ DEFAULT NULL,
  p_to TIMESTAMPTZ DEFAULT NULL
) RETURNS TABLE (
  "Total_Pendapatan" NUMERIC(14,2),
  "Total_HPP" NUMERIC(14,2),
  "Total_Penyesuaian_Pendapatan" NUMERIC(14,2),
  "Total_Penyesuaian_Beban" NUMERIC(14,2),
  "Laba_Rugi_Bersih" NUMERIC(14,2)
) AS $$
DECLARE
  v_Pendapatan NUMERIC(14,2) := 0;
  v_Hpp NUMERIC(14,2) := 0;
  v_PenyesuaianPendapatan NUMERIC(14,2) := 0;
  v_PenyesuaianBeban NUMERIC(14,2) := 0;
BEGIN
  -- Security check
  IF NOT "private"."userHasAccessToUnit"(p_unit_id) THEN
    RAISE EXCEPTION 'unauthorized: tidak punya akses ke OPD ini'
      USING ERRCODE = 'P0001';
  END IF;

  -- 1. Sum Pendapatan (COA 4101) - Credit balance
  SELECT COALESCE(SUM(jd."Kredit" - jd."Debit"), 0.00) INTO v_Pendapatan
  FROM public."BS_trJurnalDetail" jd
  JOIN public."BS_trJurnal" j ON j."No_Jurnal" = jd."No_Jurnal"
  WHERE jd."COA_ID" = '4101'
    AND j."UnitBisnisID" = p_unit_id
    AND (p_from IS NULL OR j."Tgl_Jurnal" >= p_from)
    AND (p_to IS NULL OR j."Tgl_Jurnal" < p_to);

  -- 2. Sum HPP (COA 5101) - Debit balance
  SELECT COALESCE(SUM(jd."Debit" - jd."Kredit"), 0.00) INTO v_Hpp
  FROM public."BS_trJurnalDetail" jd
  JOIN public."BS_trJurnal" j ON j."No_Jurnal" = jd."No_Jurnal"
  WHERE jd."COA_ID" = '5101'
    AND j."UnitBisnisID" = p_unit_id
    AND (p_from IS NULL OR j."Tgl_Jurnal" >= p_from)
    AND (p_to IS NULL OR j."Tgl_Jurnal" < p_to);

  -- 3. Sum Penyesuaian Pendapatan (COA 4102) - Credit balance
  SELECT COALESCE(SUM(jd."Kredit" - jd."Debit"), 0.00) INTO v_PenyesuaianPendapatan
  FROM public."BS_trJurnalDetail" jd
  JOIN public."BS_trJurnal" j ON j."No_Jurnal" = jd."No_Jurnal"
  WHERE jd."COA_ID" = '4102'
    AND j."UnitBisnisID" = p_unit_id
    AND (p_from IS NULL OR j."Tgl_Jurnal" >= p_from)
    AND (p_to IS NULL OR j."Tgl_Jurnal" < p_to);

  -- 4. Sum Penyesuaian Beban (COA 5102) - Debit balance
  SELECT COALESCE(SUM(jd."Debit" - jd."Kredit"), 0.00) INTO v_PenyesuaianBeban
  FROM public."BS_trJurnalDetail" jd
  JOIN public."BS_trJurnal" j ON j."No_Jurnal" = jd."No_Jurnal"
  WHERE jd."COA_ID" = '5102'
    AND j."UnitBisnisID" = p_unit_id
    AND (p_from IS NULL OR j."Tgl_Jurnal" >= p_from)
    AND (p_to IS NULL OR j."Tgl_Jurnal" < p_to);

  RETURN QUERY
  SELECT 
    v_Pendapatan, 
    v_Hpp, 
    v_PenyesuaianPendapatan, 
    v_PenyesuaianBeban,
    (v_Pendapatan + v_PenyesuaianPendapatan) - (v_Hpp + v_PenyesuaianBeban) AS "Laba_Rugi_Bersih";
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

GRANT EXECUTE ON FUNCTION public."bs_report_hpp_labarugi"(INT, TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;
