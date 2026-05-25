-- 20260523001800_error_logging_table.sql

CREATE TABLE IF NOT EXISTS public."mLogError" (
  "Log_ID" BIGSERIAL PRIMARY KEY,
  "Tgl_Log" TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  "User_ID" INTEGER REFERENCES public."mUser"("User_ID"),
  "Error_Message" TEXT NOT NULL,
  "Stack_Trace" TEXT,
  "Device_Info" TEXT,
  "UnitBisnisID" INTEGER REFERENCES public."mUnitBisnis"("UnitBisnisID")
);

ALTER TABLE public."mLogError" ENABLE ROW LEVEL SECURITY;

-- Izinkan siapa saja (aplikasi client) untuk mengentri log error
CREATE POLICY "mLogError_insert" ON public."mLogError" FOR INSERT
WITH CHECK (TRUE);

-- Hanya super admin atau admin OPD terkait yang bisa melihat log error
CREATE POLICY "mLogError_select" ON public."mLogError" FOR SELECT
USING ("private"."isSuperAdmin"() OR "private"."userHasAccessToUnit"("UnitBisnisID"));

-- RPC untuk mencatat log error dari Flutter
CREATE OR REPLACE FUNCTION public."bs_log_error"(
  p_error_message TEXT,
  p_stack_trace TEXT DEFAULT NULL,
  p_device_info TEXT DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
  v_User_ID INT;
  v_UnitBisnisID INT;
BEGIN
  v_User_ID := "private"."currentUserID"();
  
  IF v_User_ID IS NOT NULL THEN
    SELECT "UnitBisnisID" INTO v_UnitBisnisID
    FROM public."mUserUnitBisnis"
    WHERE "User_ID" = v_User_ID
    LIMIT 1;
  END IF;

  INSERT INTO public."mLogError"(
    "User_ID",
    "Error_Message",
    "Stack_Trace",
    "Device_Info",
    "UnitBisnisID"
  )
  VALUES (
    v_User_ID,
    p_error_message,
    p_stack_trace,
    p_device_info,
    v_UnitBisnisID
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public."bs_log_error"(TEXT, TEXT, TEXT) TO authenticated, anon;
