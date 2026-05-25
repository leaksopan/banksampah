CREATE INDEX IF NOT EXISTS "idx_BS_Penjualan_Lokasi" ON "BS_trPenjualan"("Lokasi_ID");
CREATE INDEX IF NOT EXISTS "idx_BS_Penjualan_User" ON "BS_trPenjualan"("User_ID");
CREATE INDEX IF NOT EXISTS "idx_BS_Penjualan_DisetujuiUser" ON "BS_trPenjualan"("DisetujuiUserID");

CREATE INDEX IF NOT EXISTS "idx_BS_PenjualanDetail_KodeSatuan" ON "BS_trPenjualanDetail"("Kode_Satuan");

CREATE INDEX IF NOT EXISTS "idx_BS_FIFOKeluar_Lokasi" ON "BS_trKartuFIFO_Keluar"("Lokasi_ID");
CREATE INDEX IF NOT EXISTS "idx_BS_FIFOKeluar_Sampah" ON "BS_trKartuFIFO_Keluar"("Sampah_ID");
CREATE INDEX IF NOT EXISTS "idx_BS_FIFOKeluar_DetailPenjualan" ON "BS_trKartuFIFO_Keluar"("Detail_ID_Penjualan");

DROP POLICY IF EXISTS "BS_trPenjualan_modify_admin_unposted" ON "BS_trPenjualan";
CREATE POLICY "BS_trPenjualan_insert_admin" ON "BS_trPenjualan" FOR INSERT
WITH CHECK ("private"."currentUserIsAdmin"());
CREATE POLICY "BS_trPenjualan_update_admin_unposted" ON "BS_trPenjualan" FOR UPDATE
USING ("private"."currentUserIsAdmin"() AND "Posted" = FALSE)
WITH CHECK ("private"."currentUserIsAdmin"());
CREATE POLICY "BS_trPenjualan_delete_admin_unposted" ON "BS_trPenjualan" FOR DELETE
USING ("private"."currentUserIsAdmin"() AND "Posted" = FALSE);

DROP POLICY IF EXISTS "BS_trPenjualanDetail_modify_admin_parent_unposted" ON "BS_trPenjualanDetail";
CREATE POLICY "BS_trPenjualanDetail_insert_admin" ON "BS_trPenjualanDetail" FOR INSERT
WITH CHECK ("private"."currentUserIsAdmin"());
CREATE POLICY "BS_trPenjualanDetail_update_admin_parent_unposted" ON "BS_trPenjualanDetail" FOR UPDATE
USING (
  "private"."currentUserIsAdmin"()
  AND EXISTS (
    SELECT 1 FROM "BS_trPenjualan" h
    WHERE h."No_Bukti" = "BS_trPenjualanDetail"."No_Bukti"
      AND h."Posted" = FALSE
  )
)
WITH CHECK ("private"."currentUserIsAdmin"());
CREATE POLICY "BS_trPenjualanDetail_delete_admin_parent_unposted" ON "BS_trPenjualanDetail" FOR DELETE
USING (
  "private"."currentUserIsAdmin"()
  AND EXISTS (
    SELECT 1 FROM "BS_trPenjualan" h
    WHERE h."No_Bukti" = "BS_trPenjualanDetail"."No_Bukti"
      AND h."Posted" = FALSE
  )
);
