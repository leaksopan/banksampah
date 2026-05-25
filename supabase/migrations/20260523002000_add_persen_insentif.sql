-- 20260523002000_add_persen_insentif.sql
-- Menambahkan kolom Persen_Insentif ke tabel mSampah

ALTER TABLE public."mSampah"
ADD COLUMN IF NOT EXISTS "Persen_Insentif" NUMERIC(5,2) NOT NULL DEFAULT 0.00;

-- Menambahkan batasan nilai persen (0% s.d 100%)
ALTER TABLE public."mSampah"
DROP CONSTRAINT IF EXISTS "chk_mSampah_Persen_Insentif";

ALTER TABLE public."mSampah"
ADD CONSTRAINT "chk_mSampah_Persen_Insentif" 
CHECK ("Persen_Insentif" >= 0.00 AND "Persen_Insentif" <= 100.00);

-- Refresh schema cache jika diperlukan
NOTIFY pgrst, 'reload schema';
