-- 20260523001700_harden_multi_opd_rls.sql

-- 1. Perbarui policy SELECT mPegawai
DROP POLICY IF EXISTS "mPegawai_select_self_or_admin" ON public."mPegawai";
CREATE POLICY "mPegawai_select_self_or_admin" ON public."mPegawai" FOR SELECT
USING (
  "User_ID" = "private"."currentUserID"() 
  OR "private"."userHasAccessToUnit"("UnitBisnisID")
);

-- 2. Perbarui policy INSERT/UPDATE/DELETE mPegawai
DROP POLICY IF EXISTS "mPegawai_modify_admin" ON public."mPegawai";
CREATE POLICY "mPegawai_modify_admin" ON public."mPegawai" FOR ALL
USING (
  "private"."userHasAccessToUnit"("UnitBisnisID")
)
WITH CHECK (
  "private"."userHasAccessToUnit"("UnitBisnisID")
);
