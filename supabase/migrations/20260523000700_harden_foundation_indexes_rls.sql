CREATE INDEX IF NOT EXISTS "idx_BS_Setoran_User" ON "BS_trSetoran"("User_ID");
CREATE INDEX IF NOT EXISTS "idx_BS_SetoranDetail_KodeSatuan" ON "BS_trSetoranDetail"("Kode_Satuan");

CREATE INDEX IF NOT EXISTS "idx_BS_StockLayer_NoBuktiSetoran" ON "BS_trStockLayer"("No_Bukti_Setoran");
CREATE INDEX IF NOT EXISTS "idx_BS_StockLayer_DetailSetoran" ON "BS_trStockLayer"("Detail_ID_Setoran");
CREATE INDEX IF NOT EXISTS "idx_BS_StockLayer_Sampah" ON "BS_trStockLayer"("Sampah_ID");

CREATE INDEX IF NOT EXISTS "idx_BS_KG_Sampah" ON "BS_trKartuGudang"("Sampah_ID");
CREATE INDEX IF NOT EXISTS "idx_BS_KG_JTransaksi" ON "BS_trKartuGudang"("JTransaksi_ID");
CREATE INDEX IF NOT EXISTS "idx_BS_KG_KodeSatuan" ON "BS_trKartuGudang"("Kode_Satuan");

CREATE INDEX IF NOT EXISTS "idx_BS_Mutasi_JTransaksi" ON "BS_trMutasiSaldo"("JTransaksi_ID");
CREATE INDEX IF NOT EXISTS "idx_BS_Mutasi_FIFORef" ON "BS_trMutasiSaldo"("FIFOKeluar_ID_Ref");
CREATE INDEX IF NOT EXISTS "idx_BS_Mutasi_User" ON "BS_trMutasiSaldo"("User_ID");

CREATE INDEX IF NOT EXISTS "idx_mSampah_KodeSatuan" ON "mSampah"("Kode_Satuan");
CREATE INDEX IF NOT EXISTS "idx_mSampah_SubKategori" ON "mSampah"("SubKategori_ID");
CREATE INDEX IF NOT EXISTS "idx_mSampah_UserUpdate" ON "mSampah"("User_Update");
CREATE INDEX IF NOT EXISTS "idx_mSampahChangePrice_User" ON "mSampah_ChangePrice"("User_ID");
CREATE INDEX IF NOT EXISTS "idx_mVendor_KodeKategori" ON "mVendor"("Kode_Kategori");

DROP POLICY IF EXISTS "mLokasi_modify_admin" ON "mLokasi";
CREATE POLICY "mLokasi_insert_admin" ON "mLokasi" FOR INSERT
WITH CHECK ("private"."currentUserIsAdmin"());
CREATE POLICY "mLokasi_update_admin" ON "mLokasi" FOR UPDATE
USING ("private"."currentUserIsAdmin"())
WITH CHECK ("private"."currentUserIsAdmin"());
CREATE POLICY "mLokasi_delete_admin" ON "mLokasi" FOR DELETE
USING ("private"."currentUserIsAdmin"());

DROP POLICY IF EXISTS "mSampah_modify_admin" ON "mSampah";
CREATE POLICY "mSampah_insert_admin" ON "mSampah" FOR INSERT
WITH CHECK ("private"."currentUserIsAdmin"());
CREATE POLICY "mSampah_update_admin" ON "mSampah" FOR UPDATE
USING ("private"."currentUserIsAdmin"())
WITH CHECK ("private"."currentUserIsAdmin"());
CREATE POLICY "mSampah_delete_admin" ON "mSampah" FOR DELETE
USING ("private"."currentUserIsAdmin"());

DROP POLICY IF EXISTS "mVendor_modify_admin" ON "mVendor";
CREATE POLICY "mVendor_insert_admin" ON "mVendor" FOR INSERT
WITH CHECK ("private"."currentUserIsAdmin"());
CREATE POLICY "mVendor_update_admin" ON "mVendor" FOR UPDATE
USING ("private"."currentUserIsAdmin"())
WITH CHECK ("private"."currentUserIsAdmin"());
CREATE POLICY "mVendor_delete_admin" ON "mVendor" FOR DELETE
USING ("private"."currentUserIsAdmin"());

DROP POLICY IF EXISTS "BS_trSetoran_modify_admin_unposted" ON "BS_trSetoran";
CREATE POLICY "BS_trSetoran_insert_admin" ON "BS_trSetoran" FOR INSERT
WITH CHECK ("private"."currentUserIsAdmin"());
CREATE POLICY "BS_trSetoran_update_admin_unposted" ON "BS_trSetoran" FOR UPDATE
USING ("private"."currentUserIsAdmin"() AND "Posted" = FALSE)
WITH CHECK ("private"."currentUserIsAdmin"());
CREATE POLICY "BS_trSetoran_delete_admin_unposted" ON "BS_trSetoran" FOR DELETE
USING ("private"."currentUserIsAdmin"() AND "Posted" = FALSE);

DROP POLICY IF EXISTS "BS_trSetoranDetail_modify_admin_parent_unposted" ON "BS_trSetoranDetail";
CREATE POLICY "BS_trSetoranDetail_insert_admin" ON "BS_trSetoranDetail" FOR INSERT
WITH CHECK ("private"."currentUserIsAdmin"());
CREATE POLICY "BS_trSetoranDetail_update_admin_parent_unposted" ON "BS_trSetoranDetail" FOR UPDATE
USING (
  "private"."currentUserIsAdmin"()
  AND EXISTS (
    SELECT 1 FROM "BS_trSetoran" h
    WHERE h."No_Bukti" = "BS_trSetoranDetail"."No_Bukti"
      AND h."Posted" = FALSE
  )
)
WITH CHECK ("private"."currentUserIsAdmin"());
CREATE POLICY "BS_trSetoranDetail_delete_admin_parent_unposted" ON "BS_trSetoranDetail" FOR DELETE
USING (
  "private"."currentUserIsAdmin"()
  AND EXISTS (
    SELECT 1 FROM "BS_trSetoran" h
    WHERE h."No_Bukti" = "BS_trSetoranDetail"."No_Bukti"
      AND h."Posted" = FALSE
  )
);

DROP POLICY IF EXISTS "BS_trStockLayer_modify_admin" ON "BS_trStockLayer";
CREATE POLICY "BS_trStockLayer_insert_admin" ON "BS_trStockLayer" FOR INSERT
WITH CHECK ("private"."currentUserIsAdmin"());
CREATE POLICY "BS_trStockLayer_update_admin" ON "BS_trStockLayer" FOR UPDATE
USING ("private"."currentUserIsAdmin"())
WITH CHECK ("private"."currentUserIsAdmin"());
CREATE POLICY "BS_trStockLayer_delete_admin" ON "BS_trStockLayer" FOR DELETE
USING ("private"."currentUserIsAdmin"());

DROP POLICY IF EXISTS "BS_trKartuGudang_modify_admin" ON "BS_trKartuGudang";
CREATE POLICY "BS_trKartuGudang_insert_admin" ON "BS_trKartuGudang" FOR INSERT
WITH CHECK ("private"."currentUserIsAdmin"());
CREATE POLICY "BS_trKartuGudang_update_admin" ON "BS_trKartuGudang" FOR UPDATE
USING ("private"."currentUserIsAdmin"())
WITH CHECK ("private"."currentUserIsAdmin"());
CREATE POLICY "BS_trKartuGudang_delete_admin" ON "BS_trKartuGudang" FOR DELETE
USING ("private"."currentUserIsAdmin"());

DROP POLICY IF EXISTS "BS_trMutasiSaldo_modify_admin" ON "BS_trMutasiSaldo";
CREATE POLICY "BS_trMutasiSaldo_insert_admin" ON "BS_trMutasiSaldo" FOR INSERT
WITH CHECK ("private"."currentUserIsAdmin"());
CREATE POLICY "BS_trMutasiSaldo_update_admin" ON "BS_trMutasiSaldo" FOR UPDATE
USING ("private"."currentUserIsAdmin"())
WITH CHECK ("private"."currentUserIsAdmin"());
CREATE POLICY "BS_trMutasiSaldo_delete_admin" ON "BS_trMutasiSaldo" FOR DELETE
USING ("private"."currentUserIsAdmin"());
