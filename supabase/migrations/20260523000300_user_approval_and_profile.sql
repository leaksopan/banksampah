CREATE TABLE IF NOT EXISTS "mPegawai" (
  "Pegawai_ID"        SERIAL PRIMARY KEY,
  "User_ID"           INT NOT NULL REFERENCES "mUser"("User_ID") ON DELETE CASCADE,
  "NIP"               VARCHAR(20),
  "Nama_Pegawai"      VARCHAR(200) NOT NULL,
  "No_Telepon"        VARCHAR(20),
  "Email"             VARCHAR(150),
  "Status_Aktif"      BOOLEAN NOT NULL DEFAULT TRUE,
  "UnitBisnisID"      INT NOT NULL REFERENCES "mUnitBisnis"("UnitBisnisID"),
  "Tgl_Daftar"        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "Tgl_Update"        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "User_Update"       INT REFERENCES "mUser"("User_ID"),
  UNIQUE ("User_ID")
);

CREATE INDEX IF NOT EXISTS "idx_mPegawai_Unit" ON "mPegawai"("UnitBisnisID");
CREATE INDEX IF NOT EXISTS "idx_mPegawai_User" ON "mPegawai"("User_ID");
CREATE INDEX IF NOT EXISTS "idx_mPegawai_NIP" ON "mPegawai"("NIP");

CREATE TABLE IF NOT EXISTS "BS_tSaldoPegawai" (
  "Pegawai_ID"          INT PRIMARY KEY REFERENCES "mPegawai"("Pegawai_ID") ON DELETE CASCADE,
  "Saldo_Pending"       NUMERIC(14,2) NOT NULL DEFAULT 0,
  "Saldo_Tersedia"      NUMERIC(14,2) NOT NULL DEFAULT 0,
  "Total_Ditarik"       NUMERIC(14,2) NOT NULL DEFAULT 0,
  "Total_Berat_Setor"   NUMERIC(14,3) NOT NULL DEFAULT 0,
  "Total_Berat_Terjual" NUMERIC(14,3) NOT NULL DEFAULT 0,
  "Tgl_Update"          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UnitBisnisID"        INT NOT NULL REFERENCES "mUnitBisnis"("UnitBisnisID")
);

CREATE INDEX IF NOT EXISTS "idx_BS_tSaldoPegawai_Unit" ON "BS_tSaldoPegawai"("UnitBisnisID");

ALTER TABLE "mPegawai" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "BS_tSaldoPegawai" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "mPegawai_select_self_or_admin" ON "mPegawai";
CREATE POLICY "mPegawai_select_self_or_admin" ON "mPegawai"
FOR SELECT
USING (
  "User_ID" = "private"."currentUserID"()
  OR "private"."currentUserIsAdmin"()
);

DROP POLICY IF EXISTS "mPegawai_modify_admin" ON "mPegawai";
CREATE POLICY "mPegawai_modify_admin" ON "mPegawai"
FOR ALL
USING ("private"."currentUserIsAdmin"())
WITH CHECK ("private"."currentUserIsAdmin"());

DROP POLICY IF EXISTS "BS_tSaldoPegawai_select_self_or_admin" ON "BS_tSaldoPegawai";
CREATE POLICY "BS_tSaldoPegawai_select_self_or_admin" ON "BS_tSaldoPegawai"
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM "mPegawai" mp
    WHERE mp."Pegawai_ID" = "BS_tSaldoPegawai"."Pegawai_ID"
      AND (
        mp."User_ID" = "private"."currentUserID"()
        OR "private"."currentUserIsAdmin"()
      )
  )
);

DROP POLICY IF EXISTS "BS_tSaldoPegawai_modify_admin" ON "BS_tSaldoPegawai";
CREATE POLICY "BS_tSaldoPegawai_modify_admin" ON "BS_tSaldoPegawai"
FOR ALL
USING ("private"."currentUserIsAdmin"())
WITH CHECK ("private"."currentUserIsAdmin"());

GRANT SELECT, INSERT, UPDATE ON "mPegawai" TO authenticated;
GRANT SELECT, INSERT, UPDATE ON "BS_tSaldoPegawai" TO authenticated;

CREATE OR REPLACE FUNCTION "private"."approve_user_impl"(
  p_user_id INT,
  p_role TEXT,
  p_nama_pegawai TEXT,
  p_nip TEXT DEFAULT NULL,
  p_no_telepon TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_target_user RECORD;
  v_group_id INT;
  v_admin_user_id INT;
  v_unit_id INT;
  v_pegawai_id INT;
BEGIN
  IF NOT "private"."currentUserIsAdmin"() THEN
    RAISE EXCEPTION 'unauthorized: hanya admin yang dapat approve user';
  END IF;

  IF p_role NOT IN ('ADMIN', 'NASABAH') THEN
    RAISE EXCEPTION 'invalid role: %', p_role;
  END IF;

  SELECT *
  INTO v_target_user
  FROM "mUser"
  WHERE "User_ID" = p_user_id
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'user not found: %', p_user_id;
  END IF;

  IF COALESCE(TRIM(p_nama_pegawai), '') = '' THEN
    RAISE EXCEPTION 'nama_pegawai wajib diisi';
  END IF;

  v_admin_user_id := "private"."currentUserID"();
  v_unit_id := "private"."currentUserUnitBisnis"();
  IF v_unit_id IS NULL THEN
    SELECT "UnitBisnisID"
    INTO v_unit_id
    FROM "mUnitBisnis"
    WHERE "Kode_OPD" = 'BKPSDM'
    LIMIT 1;
  END IF;

  UPDATE "mUser"
  SET
    "Status_Approval" = 'APPROVED',
    "Approved_Tgl" = COALESCE("Approved_Tgl", NOW()),
    "Approved_User_ID" = COALESCE("Approved_User_ID", v_admin_user_id),
    "Tgl_Update" = NOW(),
    "Status_Aktif" = TRUE
  WHERE "User_ID" = p_user_id;

  SELECT "Group_ID"
  INTO v_group_id
  FROM "mGroup"
  WHERE "Kode_Group" = p_role
  LIMIT 1;

  IF v_group_id IS NULL THEN
    RAISE EXCEPTION 'role not found in mGroup: %', p_role;
  END IF;

  INSERT INTO "mUserGroup"("User_ID", "Group_ID")
  VALUES (p_user_id, v_group_id)
  ON CONFLICT ("User_ID", "Group_ID") DO NOTHING;

  INSERT INTO "mPegawai"(
    "User_ID",
    "NIP",
    "Nama_Pegawai",
    "No_Telepon",
    "Email",
    "Status_Aktif",
    "UnitBisnisID",
    "Tgl_Update",
    "User_Update"
  )
  VALUES (
    p_user_id,
    NULLIF(TRIM(p_nip), ''),
    TRIM(p_nama_pegawai),
    NULLIF(TRIM(p_no_telepon), ''),
    v_target_user."Email",
    TRUE,
    v_unit_id,
    NOW(),
    v_admin_user_id
  )
  ON CONFLICT ("User_ID") DO UPDATE SET
    "NIP" = COALESCE(NULLIF(TRIM(EXCLUDED."NIP"), ''), "mPegawai"."NIP"),
    "Nama_Pegawai" = EXCLUDED."Nama_Pegawai",
    "No_Telepon" = COALESCE(NULLIF(TRIM(EXCLUDED."No_Telepon"), ''), "mPegawai"."No_Telepon"),
    "Email" = COALESCE(EXCLUDED."Email", "mPegawai"."Email"),
    "Status_Aktif" = TRUE,
    "UnitBisnisID" = EXCLUDED."UnitBisnisID",
    "Tgl_Update" = NOW(),
    "User_Update" = v_admin_user_id
  RETURNING "Pegawai_ID" INTO v_pegawai_id;

  INSERT INTO "BS_tSaldoPegawai"(
    "Pegawai_ID",
    "Saldo_Pending",
    "Saldo_Tersedia",
    "Total_Ditarik",
    "Total_Berat_Setor",
    "Total_Berat_Terjual",
    "Tgl_Update",
    "UnitBisnisID"
  )
  VALUES (
    v_pegawai_id,
    0,
    0,
    0,
    0,
    0,
    NOW(),
    v_unit_id
  )
  ON CONFLICT ("Pegawai_ID") DO UPDATE SET
    "UnitBisnisID" = EXCLUDED."UnitBisnisID",
    "Tgl_Update" = NOW();

  RETURN jsonb_build_object(
    'ok', TRUE,
    'user_id', p_user_id,
    'role', p_role,
    'pegawai_id', v_pegawai_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

REVOKE ALL ON FUNCTION "private"."approve_user_impl"(INT, TEXT, TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "private"."approve_user_impl"(INT, TEXT, TEXT, TEXT, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public."approve_user"(
  p_user_id INT,
  p_role TEXT,
  p_nama_pegawai TEXT,
  p_nip TEXT DEFAULT NULL,
  p_no_telepon TEXT DEFAULT NULL
) RETURNS JSONB AS $$
  SELECT "private"."approve_user_impl"(p_user_id, p_role, p_nama_pegawai, p_nip, p_no_telepon);
$$ LANGUAGE sql SECURITY INVOKER SET search_path = public, private;

GRANT EXECUTE ON FUNCTION public."approve_user"(INT, TEXT, TEXT, TEXT, TEXT) TO authenticated;
