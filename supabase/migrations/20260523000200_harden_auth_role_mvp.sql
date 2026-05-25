CREATE SCHEMA IF NOT EXISTS "private";

REVOKE ALL ON SCHEMA "private" FROM PUBLIC;
GRANT USAGE ON SCHEMA "private" TO authenticated;

CREATE OR REPLACE FUNCTION "private"."currentUserID"() RETURNS INT AS $$
  SELECT "User_ID"
  FROM public."mUser"
  WHERE "Auth_UID" = (SELECT auth.uid())
  LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION "private"."currentUserStatusApproval"() RETURNS TEXT AS $$
  SELECT COALESCE("Status_Approval", 'PENDING')
  FROM public."mUser"
  WHERE "Auth_UID" = (SELECT auth.uid())
  LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION "private"."currentUserHasRole"(p_Kode_Group TEXT) RETURNS BOOLEAN AS $$
  SELECT EXISTS(
    SELECT 1
    FROM public."mUser" mu
    JOIN public."mUserGroup" ug ON ug."User_ID" = mu."User_ID"
    JOIN public."mGroup" mg ON mg."Group_ID" = ug."Group_ID"
    WHERE mu."Auth_UID" = (SELECT auth.uid())
      AND mg."Kode_Group" = p_Kode_Group
      AND mg."Status_Aktif" = TRUE
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION "private"."currentUserIsAdmin"() RETURNS BOOLEAN AS $$
  SELECT "private"."currentUserHasRole"('ADMIN');
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, private;

CREATE OR REPLACE FUNCTION "private"."currentUserUnitBisnis"() RETURNS INT AS $$
  SELECT uub."UnitBisnisID"
  FROM public."mUser" mu
  JOIN public."mUserUnitBisnis" uub ON uub."User_ID" = mu."User_ID"
  WHERE mu."Auth_UID" = (SELECT auth.uid())
  LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION "private"."syncUserOnAuthCreate"() RETURNS TRIGGER AS $$
DECLARE
  v_User_ID INT;
  v_Group_ID INT;
  v_UnitBisnisID INT;
  v_Email TEXT;
  v_Nama_Asli TEXT;
  v_Username TEXT;
BEGIN
  v_Email := LOWER(NEW.email);
  v_Nama_Asli := COALESCE(
    NEW.raw_user_meta_data ->> 'full_name',
    NEW.raw_user_meta_data ->> 'name',
    NEW.email,
    NEW.id::TEXT
  );
  v_Username := COALESCE(v_Email, NEW.id::TEXT);

  INSERT INTO public."mUser"(
    "Username",
    "Nama_Asli",
    "Nama_Singkat",
    "Email",
    "Auth_UID",
    "Status_Approval",
    "Status_Aktif"
  )
  VALUES (
    v_Username,
    v_Nama_Asli,
    LEFT(v_Nama_Asli, 50),
    v_Email,
    NEW.id,
    'PENDING',
    TRUE
  )
  ON CONFLICT ("Email") DO UPDATE SET
    "Auth_UID" = COALESCE(public."mUser"."Auth_UID", EXCLUDED."Auth_UID"),
    "Nama_Asli" = EXCLUDED."Nama_Asli",
    "Nama_Singkat" = EXCLUDED."Nama_Singkat",
    "Tgl_Update" = NOW()
  RETURNING "User_ID" INTO v_User_ID;

  SELECT "Group_ID" INTO v_Group_ID
  FROM public."mGroup"
  WHERE "Kode_Group" = 'NASABAH'
  LIMIT 1;

  IF v_Group_ID IS NOT NULL THEN
    INSERT INTO public."mUserGroup"("User_ID","Group_ID")
    VALUES (v_User_ID, v_Group_ID)
    ON CONFLICT ("User_ID","Group_ID") DO NOTHING;
  END IF;

  SELECT "UnitBisnisID" INTO v_UnitBisnisID
  FROM public."mUnitBisnis"
  WHERE "Kode_OPD" = 'BKPSDM'
  LIMIT 1;

  IF v_UnitBisnisID IS NOT NULL THEN
    INSERT INTO public."mUserUnitBisnis"("User_ID","UnitBisnisID")
    VALUES (v_User_ID, v_UnitBisnisID)
    ON CONFLICT ("User_ID","UnitBisnisID") DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

REVOKE ALL ON FUNCTION "private"."currentUserID"() FROM PUBLIC;
REVOKE ALL ON FUNCTION "private"."currentUserStatusApproval"() FROM PUBLIC;
REVOKE ALL ON FUNCTION "private"."currentUserHasRole"(TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION "private"."currentUserIsAdmin"() FROM PUBLIC;
REVOKE ALL ON FUNCTION "private"."currentUserUnitBisnis"() FROM PUBLIC;
REVOKE ALL ON FUNCTION "private"."syncUserOnAuthCreate"() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION "private"."currentUserID"() TO authenticated;
GRANT EXECUTE ON FUNCTION "private"."currentUserStatusApproval"() TO authenticated;
GRANT EXECUTE ON FUNCTION "private"."currentUserHasRole"(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION "private"."currentUserIsAdmin"() TO authenticated;
GRANT EXECUTE ON FUNCTION "private"."currentUserUnitBisnis"() TO authenticated;

DROP TRIGGER IF EXISTS "trg_SyncUser" ON auth.users;
CREATE TRIGGER "trg_SyncUser"
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION "private"."syncUserOnAuthCreate"();

DROP POLICY IF EXISTS "mUser_select_self_or_admin" ON "mUser";
DROP POLICY IF EXISTS "mUser_update_admin" ON "mUser";
DROP POLICY IF EXISTS "mUserGroup_select_self_or_admin" ON "mUserGroup";
DROP POLICY IF EXISTS "mUserUnitBisnis_select_self_or_admin" ON "mUserUnitBisnis";

CREATE POLICY "mUser_select_self_or_admin" ON "mUser"
FOR SELECT
USING ("Auth_UID" = (SELECT auth.uid()) OR "private"."currentUserIsAdmin"());

CREATE POLICY "mUser_update_admin" ON "mUser"
FOR UPDATE
USING ("private"."currentUserIsAdmin"())
WITH CHECK ("private"."currentUserIsAdmin"());

CREATE POLICY "mUserGroup_select_self_or_admin" ON "mUserGroup"
FOR SELECT
USING ("User_ID" = "private"."currentUserID"() OR "private"."currentUserIsAdmin"());

CREATE POLICY "mUserUnitBisnis_select_self_or_admin" ON "mUserUnitBisnis"
FOR SELECT
USING ("User_ID" = "private"."currentUserID"() OR "private"."currentUserIsAdmin"());

CREATE INDEX IF NOT EXISTS "idx_mUser_ApprovedUser" ON "mUser"("Approved_User_ID");
CREATE INDEX IF NOT EXISTS "idx_mUserGroup_Group" ON "mUserGroup"("Group_ID");
CREATE INDEX IF NOT EXISTS "idx_mUserUnitBisnis_Unit" ON "mUserUnitBisnis"("UnitBisnisID");

GRANT SELECT, UPDATE ON "mUser" TO authenticated;
GRANT SELECT ON "mGroup" TO authenticated;
GRANT SELECT ON "mUserGroup" TO authenticated;
GRANT SELECT ON "mUserUnitBisnis" TO authenticated;
GRANT SELECT ON "mUnitBisnis" TO authenticated;
GRANT SELECT ON "vCurrentUserProfile" TO authenticated;

DROP FUNCTION IF EXISTS public."syncUserOnAuthCreate"();
DROP FUNCTION IF EXISTS public."currentUserUnitBisnis"();
DROP FUNCTION IF EXISTS public."currentUserStatusApproval"();
DROP FUNCTION IF EXISTS public."currentUserIsAdmin"();
DROP FUNCTION IF EXISTS public."currentUserHasRole"(TEXT);
DROP FUNCTION IF EXISTS public."currentUserID"();
