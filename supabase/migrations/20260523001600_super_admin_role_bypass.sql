-- 20260523001600_super_admin_role_bypass.sql

-- 1. Sisipkan SUPER_ADMIN ke tabel mGroup
INSERT INTO public."mGroup" ("Group_ID", "Kode_Group", "Nama_Group", "Status_Aktif")
VALUES (3, 'SUPER_ADMIN', 'Super Admin Pemda', TRUE)
ON CONFLICT ("Group_ID") DO NOTHING;

-- 2. Buat fungsi private.isSuperAdmin()
CREATE OR REPLACE FUNCTION "private"."isSuperAdmin"() 
RETURNS BOOLEAN AS $$
  SELECT "private"."currentUserHasRole"('SUPER_ADMIN');
$$ LANGUAGE sql STABLE SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION "private"."isSuperAdmin"() TO authenticated;

-- 3. Perbarui private.userHasAccessToUnit untuk isolasi tenant & bypass super admin
CREATE OR REPLACE FUNCTION "private"."userHasAccessToUnit"(p_UnitBisnisID INT) 
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public."mUser" mu
    JOIN public."mUserUnitBisnis" uub ON uub."User_ID" = mu."User_ID"
    WHERE mu."Auth_UID" = (SELECT auth.uid())
      AND uub."UnitBisnisID" = p_UnitBisnisID
  ) 
  OR "private"."isSuperAdmin"();
$$ LANGUAGE sql STABLE SECURITY DEFINER;
