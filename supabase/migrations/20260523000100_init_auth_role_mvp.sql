CREATE TABLE IF NOT EXISTS "mUnitBisnis" (
  "UnitBisnisID"      SERIAL PRIMARY KEY,
  "UnitBisnisName"    VARCHAR(200) NOT NULL,
  "Kode_OPD"          VARCHAR(30) UNIQUE NOT NULL,
  "Tipe_OPD"          VARCHAR(50),
  "NomorBukti"        VARCHAR(30),
  "Status_Aktif"      BOOLEAN NOT NULL DEFAULT TRUE,
  "Tgl_Update"        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS "mUser" (
  "User_ID"           SERIAL PRIMARY KEY,
  "Username"          VARCHAR(150) UNIQUE NOT NULL,
  "Nama_Asli"         VARCHAR(200) NOT NULL,
  "Nama_Singkat"      VARCHAR(50),
  "Email"             VARCHAR(150) UNIQUE,
  "Status_Aktif"      BOOLEAN NOT NULL DEFAULT TRUE,
  "Auth_UID"          UUID UNIQUE,
  "Status_Approval"   VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  "Approved_Tgl"      TIMESTAMPTZ,
  "Approved_User_ID"  INT REFERENCES "mUser"("User_ID"),
  "Tgl_Daftar"        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "Tgl_Update"        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK ("Status_Approval" IN ('PENDING','APPROVED','REJECTED'))
);

CREATE TABLE IF NOT EXISTS "mGroup" (
  "Group_ID"          SERIAL PRIMARY KEY,
  "Kode_Group"        VARCHAR(30) UNIQUE NOT NULL,
  "Nama_Group"        VARCHAR(100) NOT NULL,
  "Permissions"       JSONB NOT NULL DEFAULT '{}'::jsonb,
  "Status_Aktif"      BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS "mUserGroup" (
  "UserGroup_ID"      SERIAL PRIMARY KEY,
  "User_ID"           INT NOT NULL REFERENCES "mUser"("User_ID") ON DELETE CASCADE,
  "Group_ID"          INT NOT NULL REFERENCES "mGroup"("Group_ID"),
  UNIQUE ("User_ID","Group_ID")
);

CREATE TABLE IF NOT EXISTS "mUserUnitBisnis" (
  "User_ID"           INT NOT NULL REFERENCES "mUser"("User_ID") ON DELETE CASCADE,
  "UnitBisnisID"      INT NOT NULL REFERENCES "mUnitBisnis"("UnitBisnisID"),
  PRIMARY KEY ("User_ID","UnitBisnisID")
);

CREATE INDEX IF NOT EXISTS "idx_mUser_AuthUID" ON "mUser"("Auth_UID");
CREATE INDEX IF NOT EXISTS "idx_mUser_Email" ON "mUser"("Email");
CREATE INDEX IF NOT EXISTS "idx_mUser_StatusApproval" ON "mUser"("Status_Approval");

INSERT INTO "mGroup"("Kode_Group","Nama_Group","Permissions")
VALUES
  ('ADMIN','Admin','{"user.approve":true,"dashboard.read":true}'::jsonb),
  ('NASABAH','Nasabah','{"dashboard.read":true,"saldo.read":true}'::jsonb)
ON CONFLICT ("Kode_Group") DO UPDATE SET
  "Nama_Group" = EXCLUDED."Nama_Group",
  "Permissions" = EXCLUDED."Permissions",
  "Status_Aktif" = TRUE;

INSERT INTO "mUnitBisnis"("UnitBisnisName","Kode_OPD","Tipe_OPD","NomorBukti","Status_Aktif")
VALUES ('Badan Kepegawaian dan Pengembangan SDM','BKPSDM','BADAN','BKPSDM',TRUE)
ON CONFLICT ("Kode_OPD") DO UPDATE SET
  "UnitBisnisName" = EXCLUDED."UnitBisnisName",
  "Tipe_OPD" = EXCLUDED."Tipe_OPD",
  "NomorBukti" = EXCLUDED."NomorBukti",
  "Status_Aktif" = TRUE;

CREATE OR REPLACE FUNCTION "currentUserID"() RETURNS INT AS $$
  SELECT "User_ID"
  FROM "mUser"
  WHERE "Auth_UID" = auth.uid()
  LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION "currentUserStatusApproval"() RETURNS TEXT AS $$
  SELECT COALESCE("Status_Approval", 'PENDING')
  FROM "mUser"
  WHERE "Auth_UID" = auth.uid()
  LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION "currentUserHasRole"(p_Kode_Group TEXT) RETURNS BOOLEAN AS $$
  SELECT EXISTS(
    SELECT 1
    FROM "mUser" mu
    JOIN "mUserGroup" ug ON ug."User_ID" = mu."User_ID"
    JOIN "mGroup" mg ON mg."Group_ID" = ug."Group_ID"
    WHERE mu."Auth_UID" = auth.uid()
      AND mg."Kode_Group" = p_Kode_Group
      AND mg."Status_Aktif" = TRUE
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION "currentUserIsAdmin"() RETURNS BOOLEAN AS $$
  SELECT "currentUserHasRole"('ADMIN');
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION "currentUserUnitBisnis"() RETURNS INT AS $$
  SELECT uub."UnitBisnisID"
  FROM "mUser" mu
  JOIN "mUserUnitBisnis" uub ON uub."User_ID" = mu."User_ID"
  WHERE mu."Auth_UID" = auth.uid()
  LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE VIEW "vCurrentUserProfile"
WITH (security_invoker = true) AS
SELECT
  mu."User_ID",
  mu."Username",
  mu."Nama_Asli",
  mu."Email",
  mu."Auth_UID",
  mu."Status_Aktif",
  mu."Status_Approval",
  COALESCE(
    ARRAY_AGG(mg."Kode_Group" ORDER BY mg."Kode_Group")
      FILTER (WHERE mg."Kode_Group" IS NOT NULL),
    ARRAY[]::VARCHAR[]
  ) AS "Roles"
FROM "mUser" mu
LEFT JOIN "mUserGroup" ug ON ug."User_ID" = mu."User_ID"
LEFT JOIN "mGroup" mg ON mg."Group_ID" = ug."Group_ID" AND mg."Status_Aktif" = TRUE
GROUP BY mu."User_ID";

CREATE OR REPLACE FUNCTION "syncUserOnAuthCreate"() RETURNS TRIGGER AS $$
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

  INSERT INTO "mUser"(
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
    "Auth_UID" = COALESCE("mUser"."Auth_UID", EXCLUDED."Auth_UID"),
    "Nama_Asli" = EXCLUDED."Nama_Asli",
    "Nama_Singkat" = EXCLUDED."Nama_Singkat",
    "Tgl_Update" = NOW()
  RETURNING "User_ID" INTO v_User_ID;

  SELECT "Group_ID" INTO v_Group_ID
  FROM "mGroup"
  WHERE "Kode_Group" = 'NASABAH'
  LIMIT 1;

  IF v_Group_ID IS NOT NULL THEN
    INSERT INTO "mUserGroup"("User_ID","Group_ID")
    VALUES (v_User_ID, v_Group_ID)
    ON CONFLICT ("User_ID","Group_ID") DO NOTHING;
  END IF;

  SELECT "UnitBisnisID" INTO v_UnitBisnisID
  FROM "mUnitBisnis"
  WHERE "Kode_OPD" = 'BKPSDM'
  LIMIT 1;

  IF v_UnitBisnisID IS NOT NULL THEN
    INSERT INTO "mUserUnitBisnis"("User_ID","UnitBisnisID")
    VALUES (v_User_ID, v_UnitBisnisID)
    ON CONFLICT ("User_ID","UnitBisnisID") DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

DROP TRIGGER IF EXISTS "trg_SyncUser" ON auth.users;
CREATE TRIGGER "trg_SyncUser"
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION "syncUserOnAuthCreate"();

ALTER TABLE "mUser" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "mGroup" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "mUserGroup" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "mUserUnitBisnis" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "mUnitBisnis" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "mUser_select_self_or_admin" ON "mUser"
FOR SELECT
USING ("Auth_UID" = auth.uid() OR "currentUserIsAdmin"());

CREATE POLICY "mUser_update_admin" ON "mUser"
FOR UPDATE
USING ("currentUserIsAdmin"())
WITH CHECK ("currentUserIsAdmin"());

CREATE POLICY "mGroup_select_authenticated" ON "mGroup"
FOR SELECT
TO authenticated
USING (TRUE);

CREATE POLICY "mUserGroup_select_self_or_admin" ON "mUserGroup"
FOR SELECT
USING ("User_ID" = "currentUserID"() OR "currentUserIsAdmin"());

CREATE POLICY "mUserUnitBisnis_select_self_or_admin" ON "mUserUnitBisnis"
FOR SELECT
USING ("User_ID" = "currentUserID"() OR "currentUserIsAdmin"());

CREATE POLICY "mUnitBisnis_select_authenticated" ON "mUnitBisnis"
FOR SELECT
TO authenticated
USING (TRUE);

WITH admin_seed AS (
  INSERT INTO "mUser"(
    "Username",
    "Nama_Asli",
    "Nama_Singkat",
    "Email",
    "Status_Approval",
    "Approved_Tgl",
    "Status_Aktif"
  )
  VALUES (
    'admin.bkpsdm@example.com',
    'Admin BKPSDM',
    'Admin BKPSDM',
    'admin.bkpsdm@example.com',
    'APPROVED',
    NOW(),
    TRUE
  )
  ON CONFLICT ("Email") DO UPDATE SET
    "Status_Approval" = 'APPROVED',
    "Approved_Tgl" = COALESCE("mUser"."Approved_Tgl", NOW()),
    "Status_Aktif" = TRUE
  RETURNING "User_ID"
),
admin_group AS (
  SELECT "Group_ID" FROM "mGroup" WHERE "Kode_Group" = 'ADMIN'
)
INSERT INTO "mUserGroup"("User_ID","Group_ID")
SELECT admin_seed."User_ID", admin_group."Group_ID"
FROM admin_seed, admin_group
ON CONFLICT ("User_ID","Group_ID") DO NOTHING;

WITH admin_user AS (
  SELECT "User_ID" FROM "mUser" WHERE "Email" = 'admin.bkpsdm@example.com'
),
unit_bkpsdm AS (
  SELECT "UnitBisnisID" FROM "mUnitBisnis" WHERE "Kode_OPD" = 'BKPSDM'
)
INSERT INTO "mUserUnitBisnis"("User_ID","UnitBisnisID")
SELECT admin_user."User_ID", unit_bkpsdm."UnitBisnisID"
FROM admin_user, unit_bkpsdm
ON CONFLICT ("User_ID","UnitBisnisID") DO NOTHING;
