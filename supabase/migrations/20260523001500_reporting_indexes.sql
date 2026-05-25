-- 20260523001500_reporting_indexes.sql

-- Indeks performa tinggi untuk Mutasi Saldo (Laporan Kartu Saldo Pegawai)
CREATE INDEX IF NOT EXISTS "idx_BS_trMutasiSaldo_Pegawai_Tgl" 
ON public."BS_trMutasiSaldo"("Pegawai_ID", "Tgl_Mutasi" DESC);

-- Indeks performa tinggi untuk Kartu Gudang (Laporan Kartu Gudang per TPS)
CREATE INDEX IF NOT EXISTS "idx_BS_trKartuGudang_Lokasi_Sampah_Tgl" 
ON public."BS_trKartuGudang"("Lokasi_ID", "Sampah_ID", "Tgl_Transaksi" DESC);

-- Indeks performa tinggi untuk Transaksi Setoran
CREATE INDEX IF NOT EXISTS "idx_BS_trSetoran_Pegawai_Tgl" 
ON public."BS_trSetoran"("Pegawai_ID", "Tgl_Setoran" DESC);
CREATE INDEX IF NOT EXISTS "idx_BS_trSetoran_UnitBisnis_Tgl" 
ON public."BS_trSetoran"("UnitBisnisID", "Tgl_Setoran" DESC);

-- Indeks performa tinggi untuk Transaksi Penjualan
CREATE INDEX IF NOT EXISTS "idx_BS_trPenjualan_Vendor_Tgl" 
ON public."BS_trPenjualan"("Vendor_ID", "Tgl_Penjualan" DESC);
CREATE INDEX IF NOT EXISTS "idx_BS_trPenjualan_UnitBisnis_Tgl" 
ON public."BS_trPenjualan"("UnitBisnisID", "Tgl_Penjualan" DESC);

-- Indeks performa tinggi untuk Transaksi Penarikan (Workflow Approval)
CREATE INDEX IF NOT EXISTS "idx_BS_trPenarikan_Pegawai_Tgl" 
ON public."BS_trPenarikan"("Pegawai_ID", "Tgl_Penarikan" DESC);
CREATE INDEX IF NOT EXISTS "idx_BS_trPenarikan_UnitBisnis_Tgl" 
ON public."BS_trPenarikan"("UnitBisnisID", "Tgl_Penarikan" DESC);

-- Indeks performa tinggi untuk Stock Layer (Pencocokan FIFO realisasi cepat)
CREATE INDEX IF NOT EXISTS "idx_BS_trStockLayer_Sampah_Sisa" 
ON public."BS_trStockLayer"("Sampah_ID", "Qty_Sisa") 
WHERE "Qty_Sisa" > 0;
