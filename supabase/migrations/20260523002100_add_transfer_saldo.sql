-- 20260523002100_add_transfer_saldo.sql
-- Registrasi jenis transaksi baru untuk Transfer Saldo

INSERT INTO public."mJenisTransaksi"("JTransaksi_ID", "Nama_Transaksi")
VALUES (713, 'Transfer Saldo Antar Nasabah')
ON CONFLICT ("JTransaksi_ID") DO NOTHING;

-- Buat tabel transaksi transfer saldo
CREATE TABLE IF NOT EXISTS public."BS_trTransfer" (
  "No_Bukti"            VARCHAR(50) PRIMARY KEY,
  "Tgl_Transfer"         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "Pengirim_Pegawai_ID"  INT NOT NULL REFERENCES public."mPegawai"("Pegawai_ID"),
  "Penerima_Pegawai_ID"  INT NOT NULL REFERENCES public."mPegawai"("Pegawai_ID"),
  "Jumlah"              NUMERIC(14,2) NOT NULL CHECK ("Jumlah" > 0),
  "Keterangan"          VARCHAR(250),
  "User_ID"             INT REFERENCES public."mUser"("User_ID"),
  "Status_Batal"        BOOLEAN NOT NULL DEFAULT FALSE,
  "Posted"              BOOLEAN NOT NULL DEFAULT FALSE,
  "UnitBisnisID"        INT NOT NULL REFERENCES public."mUnitBisnis"("UnitBisnisID"),
  CONSTRAINT "chk_transfer_pengirim_penerima_beda" CHECK ("Pengirim_Pegawai_ID" <> "Penerima_Pegawai_ID")
);

ALTER TABLE public."BS_trTransfer" OWNER TO postgres;

-- Indexes
CREATE INDEX IF NOT EXISTS "idx_BS_Transfer_Pengirim" ON public."BS_trTransfer"("Pengirim_Pegawai_ID", "Tgl_Transfer" DESC);
CREATE INDEX IF NOT EXISTS "idx_BS_Transfer_Penerima" ON public."BS_trTransfer"("Penerima_Pegawai_ID", "Tgl_Transfer" DESC);
CREATE INDEX IF NOT EXISTS "idx_BS_Transfer_Unit" ON public."BS_trTransfer"("UnitBisnisID", "Tgl_Transfer" DESC);

-- RLS
ALTER TABLE public."BS_trTransfer" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "BS_trTransfer_select_self_or_unit_admin" ON public."BS_trTransfer";
CREATE POLICY "BS_trTransfer_select_self_or_unit_admin" ON public."BS_trTransfer"
FOR SELECT
USING (
  "private"."userHasAccessToUnit"("UnitBisnisID")
  OR EXISTS (
    SELECT 1 FROM public."mPegawai" mp
    WHERE mp."Pegawai_ID" = "Pengirim_Pegawai_ID" AND mp."User_ID" = "private"."currentUserID"()
  )
  OR EXISTS (
    SELECT 1 FROM public."mPegawai" mp
    WHERE mp."Pegawai_ID" = "Penerima_Pegawai_ID" AND mp."User_ID" = "private"."currentUserID"()
  )
);

DROP POLICY IF EXISTS "BS_trTransfer_insert_self_or_admin" ON public."BS_trTransfer";
CREATE POLICY "BS_trTransfer_insert_self_or_admin" ON public."BS_trTransfer"
FOR INSERT
WITH CHECK (
  "private"."currentUserIsAdmin"()
  OR EXISTS (
    SELECT 1 FROM public."mPegawai" mp
    WHERE mp."Pegawai_ID" = "Pengirim_Pegawai_ID" AND mp."User_ID" = "private"."currentUserID"()
  )
);

GRANT SELECT, INSERT, UPDATE ON public."BS_trTransfer" TO authenticated;

-- Trigger Sinkronisasi Saldo
CREATE OR REPLACE FUNCTION public."BS_TrgSyncTransfer"() RETURNS TRIGGER AS $$
DECLARE
  v_SaldoTersediaPengirim NUMERIC(14,2);
BEGIN
  IF NEW."Posted" = TRUE AND OLD."Posted" = FALSE AND NEW."Status_Batal" = FALSE THEN
    -- 1. Validasi saldo tersedia pengirim
    SELECT COALESCE("Saldo_Tersedia", 0) INTO v_SaldoTersediaPengirim
    FROM public."BS_tSaldoPegawai"
    WHERE "Pegawai_ID" = NEW."Pengirim_Pegawai_ID"
    LIMIT 1;

    v_SaldoTersediaPengirim := COALESCE(v_SaldoTersediaPengirim, 0);

    IF v_SaldoTersediaPengirim < NEW."Jumlah" THEN
      RAISE EXCEPTION 'Saldo tersedia pengirim tidak mencukupi untuk transfer (Saldo: %, Transfer: %)', 
        v_SaldoTersediaPengirim, NEW."Jumlah"
        USING ERRCODE = 'P0001';
    END IF;

    -- 2. Input mutasi saldo pengirim (Debit)
    INSERT INTO public."BS_trMutasiSaldo"(
      "Pegawai_ID", "JTransaksi_ID", "No_Bukti_Ref",
      "Tersedia_Debit", "Keterangan", "User_ID", "UnitBisnisID"
    )
    VALUES (
      NEW."Pengirim_Pegawai_ID", 713, NEW."No_Bukti",
      NEW."Jumlah", FORMAT('Transfer ke nasabah %s: %s', NEW."Penerima_Pegawai_ID", NEW."Keterangan"), 
      NEW."User_ID", NEW."UnitBisnisID"
    );

    -- 3. Input mutasi saldo penerima (Kredit)
    INSERT INTO public."BS_trMutasiSaldo"(
      "Pegawai_ID", "JTransaksi_ID", "No_Bukti_Ref",
      "Tersedia_Kredit", "Keterangan", "User_ID", "UnitBisnisID"
    )
    VALUES (
      NEW."Penerima_Pegawai_ID", 713, NEW."No_Bukti",
      NEW."Jumlah", FORMAT('Terima transfer dari nasabah %s: %s', NEW."Pengirim_Pegawai_ID", NEW."Keterangan"),
      NEW."User_ID", NEW."UnitBisnisID"
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

DROP TRIGGER IF EXISTS "trg_BS_SyncTransfer" ON public."BS_trTransfer";
CREATE TRIGGER "trg_BS_SyncTransfer"
AFTER UPDATE OF "Posted" ON public."BS_trTransfer"
FOR EACH ROW EXECUTE FUNCTION public."BS_TrgSyncTransfer"();

-- Trigger Jurnal Otomatis Akuntansi EMKM
CREATE OR REPLACE FUNCTION public."BS_TrgJurnalTransfer"() RETURNS TRIGGER AS $$
DECLARE
  v_Details JSONB;
BEGIN
  IF NEW."Posted" = TRUE AND OLD."Posted" = FALSE AND NEW."Status_Batal" = FALSE THEN
    -- Entri jurnal berpasangan seimbang:
    -- Debit: Hutang Tersedia (2101) = Mengurangi hutang ke nasabah pengirim
    -- Kredit: Hutang Tersedia (2101) = Menambah hutang ke nasabah penerima
    v_Details := JSONB_BUILD_ARRAY(
      JSONB_BUILD_OBJECT(
        'COA_ID', '2101',
        'Debit', NEW."Jumlah",
        'Kredit', 0.00,
        'Keterangan', FORMAT('Debet hutang tersedia transfer saldo pengirim %s', NEW."No_Bukti")
      ),
      JSONB_BUILD_OBJECT(
        'COA_ID', '2101',
        'Debit', 0.00,
        'Kredit', NEW."Jumlah",
        'Keterangan', FORMAT('Kredit hutang tersedia terima transfer saldo penerima %s', NEW."No_Bukti")
      )
    );

    PERFORM private.bs_write_journal_entry(
      NEW."No_Bukti",
      NEW."Tgl_Transfer",
      FORMAT('Jurnal Otomatis Transfer Saldo %s', NEW."No_Bukti"),
      NEW."UnitBisnisID",
      v_Details
    );
  ELSIF NEW."Status_Batal" = TRUE THEN
    DELETE FROM public."BS_trJurnal" WHERE "No_Bukti_Ref" = NEW."No_Bukti";
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

DROP TRIGGER IF EXISTS "trg_BS_JurnalTransfer" ON public."BS_trTransfer";
CREATE TRIGGER "trg_BS_JurnalTransfer"
AFTER UPDATE OF "Posted", "Status_Batal" ON public."BS_trTransfer"
FOR EACH ROW EXECUTE FUNCTION public."BS_TrgJurnalTransfer"();

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';
