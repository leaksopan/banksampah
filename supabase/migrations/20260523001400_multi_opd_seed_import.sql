-- 20260523001400_multi_opd_seed_import.sql

-- Seed DLH Badung
INSERT INTO public."mUnitBisnis"(
  "UnitBisnisID",
  "UnitBisnisName",
  "Kode_OPD",
  "Tipe_OPD",
  "NomorBukti",
  "Warna_Primary",
  "Config",
  "Status_Aktif"
)
VALUES (
  2,
  'Dinas Lingkungan Hidup Badung',
  'DLH',
  'DINAS',
  'DLH',
  '#2E7D32',
  '{"min_penarikan": 50000}'::jsonb,
  TRUE
)
ON CONFLICT ("UnitBisnisID") DO NOTHING;

-- RPC Bulk Import Pegawai
CREATE OR REPLACE FUNCTION "private"."bs_bulk_import_pegawai_impl"(
  p_unit_bisnis_id INT,
  p_pegawai_list JSONB
) RETURNS JSONB AS $$
DECLARE
  v_User_ID INT;
  v_AdminUserID INT;
  v_Group_ID INT;
  v_Count INT := 0;
  v_EmpUserID INT;
  v_PegawaiID INT;
  v_EmpJSON JSONB;
  v_NamaPegawai TEXT;
  v_NIP TEXT;
  v_Email TEXT;
  v_NoTelepon TEXT;
  i INT;
  v_Len INT;
BEGIN
  IF NOT "private"."currentUserIsAdmin"() THEN
    RAISE EXCEPTION 'unauthorized: hanya admin yang dapat melakukan bulk import'
      USING ERRCODE = 'P0001';
  END IF;

  v_AdminUserID := "private"."currentUserID"();

  IF NOT "private"."userHasAccessToUnit"(p_unit_bisnis_id) THEN
    RAISE EXCEPTION 'unauthorized: tidak punya akses ke OPD target'
      USING ERRCODE = 'P0001';
  END IF;

  IF jsonb_typeof(p_pegawai_list) IS DISTINCT FROM 'array' OR jsonb_array_length(p_pegawai_list) = 0 THEN
    RAISE EXCEPTION 'list pegawai wajib berupa array tidak kosong'
      USING ERRCODE = 'P0001';
  END IF;

  -- Get NASABAH group ID
  SELECT "Group_ID" INTO v_Group_ID FROM public."mGroup" WHERE "Kode_Group" = 'NASABAH' LIMIT 1;

  i := 0;
  v_Len := jsonb_array_length(p_pegawai_list);
  
  WHILE i < v_Len
  LOOP
    v_EmpJSON := p_pegawai_list -> i;
    v_NamaPegawai := (v_EmpJSON ->> 'nama_pegawai');
    v_NIP := (v_EmpJSON ->> 'nip');
    v_Email := (v_EmpJSON ->> 'email');
    v_NoTelepon := (v_EmpJSON ->> 'no_telepon');

    IF COALESCE(TRIM(v_Email), '') = '' OR COALESCE(TRIM(v_NamaPegawai), '') = '' THEN
      i := i + 1;
      CONTINUE; -- skip invalid rows
    END IF;

    -- Check if user exists by email
    SELECT "User_ID" INTO v_EmpUserID
    FROM public."mUser"
    WHERE "Email" = TRIM(v_Email)
    LIMIT 1;

    -- Create user if not exists
    IF v_EmpUserID IS NULL THEN
      INSERT INTO public."mUser"(
        "Username",
        "Nama_Asli",
        "Email",
        "Status_Aktif",
        "Status_Approval",
        "Tgl_Daftar",
        "Tgl_Update"
      )
      VALUES (
        TRIM(v_Email),
        TRIM(v_NamaPegawai),
        TRIM(v_Email),
        TRUE,
        'APPROVED',
        NOW(),
        NOW()
      )
      RETURNING "User_ID" INTO v_EmpUserID;

      -- Map to NASABAH group
      IF v_Group_ID IS NOT NULL THEN
        INSERT INTO public."mUserGroup"("User_ID", "Group_ID")
        VALUES (v_EmpUserID, v_Group_ID)
        ON CONFLICT DO NOTHING;
      END IF;

      -- Map to Unit Bisnis
      INSERT INTO public."mUserUnitBisnis"("User_ID", "UnitBisnisID")
      VALUES (v_EmpUserID, p_unit_bisnis_id)
      ON CONFLICT DO NOTHING;
    END IF;

    -- Create/Update Pegawai
    INSERT INTO public."mPegawai"(
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
      v_EmpUserID,
      NULLIF(TRIM(v_NIP), ''),
      TRIM(v_NamaPegawai),
      NULLIF(TRIM(v_NoTelepon), ''),
      TRIM(v_Email),
      TRUE,
      p_unit_bisnis_id,
      NOW(),
      v_AdminUserID
    )
    ON CONFLICT ("User_ID") DO UPDATE SET
      "NIP" = COALESCE(NULLIF(TRIM(EXCLUDED."NIP"), ''), public."mPegawai"."NIP"),
      "Nama_Pegawai" = EXCLUDED."Nama_Pegawai",
      "No_Telepon" = COALESCE(NULLIF(TRIM(EXCLUDED."No_Telepon"), ''), public."mPegawai"."No_Telepon"),
      "Email" = EXCLUDED."Email",
      "Status_Aktif" = TRUE,
      "UnitBisnisID" = EXCLUDED."UnitBisnisID",
      "Tgl_Update" = NOW(),
      "User_Update" = v_AdminUserID
    RETURNING "Pegawai_ID" INTO v_PegawaiID;

    -- Initialize Saldo
    INSERT INTO public."BS_tSaldoPegawai"(
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
      v_PegawaiID,
      0,
      0,
      0,
      0,
      0,
      NOW(),
      p_unit_bisnis_id
    )
    ON CONFLICT ("Pegawai_ID") DO UPDATE SET
      "UnitBisnisID" = EXCLUDED."UnitBisnisID",
      "Tgl_Update" = NOW();

    v_Count := v_Count + 1;
    i := i + 1;
  END LOOP;

  RETURN jsonb_build_object(
    'ok', TRUE,
    'imported_count', v_Count,
    'unit_bisnis_id', p_unit_bisnis_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

REVOKE ALL ON FUNCTION "private"."bs_bulk_import_pegawai_impl"(INT, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "private"."bs_bulk_import_pegawai_impl"(INT, JSONB) TO authenticated;

CREATE OR REPLACE FUNCTION public."bs_bulk_import_pegawai"(
  p_unit_bisnis_id INT,
  p_pegawai_list JSONB
) RETURNS JSONB AS $$
  SELECT "private"."bs_bulk_import_pegawai_impl"(p_unit_bisnis_id, p_pegawai_list);
$$ LANGUAGE sql SECURITY INVOKER SET search_path = public, private;

GRANT EXECUTE ON FUNCTION public."bs_bulk_import_pegawai"(INT, JSONB) TO authenticated;
