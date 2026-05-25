# 06 — FIFO Layer & Realisasi Saldo

## Filosofi

**Layer-based FIFO dengan Owner Tracking.**

1. Tiap setoran pegawai jadi 1+ **layer** stok (per jenis sampah). Layer punya owner (`Pegawai_ID`).
2. Saat penjualan, layer dipotong **FIFO** (yang masuk duluan, keluar duluan).
3. Selisih harga jual vs harga beli per layer **otomatis dialokasikan ke owner layer itu**.
4. Saldo pegawai pakai 2 bucket:
   - **Pending**: estimasi (layer ACTIVE).
   - **Tersedia**: realized (sudah ada penjualan, bisa ditarik).
5. Pegawai cuma boleh tarik **Tersedia**.

## Why FIFO + Owner Tracking?

- **Adil**: pegawai yang setor duluan, sampahnya yang dijual duluan. Dia kena selisih harga zaman setoran dia.
- **Audit-friendly**: dari setiap layer terjual, kita tau sampai sen-an siapa yang terdampak harga turun/naik.
- **Sederhana**: lebih intuitif daripada Weighted Average Cost untuk kasus ini (pegawai paham FIFO).

## Skema Pendukung

Lihat `02-database-schema.md`:
- `BS_trStockLayer` — layer stok per setoran
- `BS_trKartuFIFO_Keluar` — audit alokasi penjualan ke layer
- `BS_trMutasiSaldo` — ledger mutasi saldo (kredit/debit Pending vs Tersedia)
- `BS_tSaldoPegawai` — snapshot saldo (rebuildable dari mutasi)

## Algoritma

### A. Saat Setoran (Input)

```
INPUT: pegawai, lokasi, [{sampah, qty, hargaBeli}, ...]

1. Generate No_Bukti (BS_GenerateNoBukti dengan Kode_Modul='BSP')
2. INSERT BS_trSetoran (header)
3. FOR each detail:
   a. INSERT BS_trSetoranDetail
   b. INSERT BS_trStockLayer (Qty_Awal=qty, Qty_Sisa=qty, Status='ACTIVE')
   c. INSERT BS_trKartuGudang (Qty_Masuk, Harga_Masuk, JTransaksi_ID=700, hitung Qty_Saldo & Harga_Persediaan dari row sebelumnya)
   d. INSERT BS_trMutasiSaldo (Pending_Kredit = qty * hargaBeli, JTransaksi_ID=700)
4. UPDATE BS_trSetoran SET Posted=TRUE, Posting_KG=TRUE, Posting_Saldo=TRUE
```

### B. Saat Penjualan ke Vendor (FIFO Alokasi)

```
INPUT: vendor, lokasi, [{sampah, qty, hargaJual}, ...]

1. Generate No_Bukti (Kode_Modul='BSJ')
2. INSERT BS_trPenjualan (header)
3. FOR each detail:
   a. INSERT BS_trPenjualanDetail
   b. CALL BS_AlokasiPenjualanFifo(detail_id):
      - Loop layer ACTIVE WHERE lokasi+sampah ORDER BY Tgl_Masuk ASC FOR UPDATE
      - Per layer:
        i. qtyAmbil = MIN(layer.Qty_Sisa, qtyDibutuhkan)
        ii. selisihPerKg = hargaJual - layer.Harga_Beli
        iii. INSERT BS_trKartuFIFO_Keluar
        iv. UPDATE layer (Qty_Sisa, Status='EXHAUSTED' if habis)
        v. INSERT BS_trMutasiSaldo (Pending_Debit=estimasi, Tersedia_Kredit=realized) untuk owner layer
        vi. qtyDibutuhkan -= qtyAmbil
      - IF qtyDibutuhkan > 0: RAISE EXCEPTION 'Stock kurang'
   c. INSERT BS_trKartuGudang (Qty_Keluar, Harga_Keluar, JTransaksi_ID=701)
4. UPDATE header: Total_HPP, Total_Selisih
5. UPDATE BS_trPenjualan SET Posted=TRUE, Posting_KG=TRUE, Posting_Saldo=TRUE
```

Implementasi MVP memakai RPC public `bs_create_penjualan(...)` dengan wrapper ke
`private.bs_create_penjualan_impl(...)`. Dalam MVP, simpan penjualan langsung
`Disetujui=TRUE` dan `Posted=TRUE`; approval formal ditunda ke iterasi berikutnya.
Function FIFO yang dipanggil adalah `private.BS_AlokasiPenjualanFifo(detail_id)`.

Validasi RPC:
- User harus admin dan punya akses ke `UnitBisnisID`.
- Vendor, lokasi, dan sampah harus aktif serta berada di OPD yang sama.
- Detail wajib array, tidak kosong, `Qty > 0`, `Harga_Jual >= 0`.
- Satu transaksi tidak boleh punya jenis sampah dobel.
- Stok dihitung dari `BS_trStockLayer` aktif per lokasi+sampah; stok kurang
  membatalkan seluruh transaksi.

### C. Saat Penarikan

```
INPUT: pegawai, jumlah

1. SELECT FOR UPDATE BS_tSaldoPegawai WHERE Pegawai_ID=?
2. IF Saldo_Tersedia < jumlah: RAISE EXCEPTION 'Saldo tidak cukup'
3. Generate No_Bukti (Kode_Modul='BST')
4. INSERT BS_trPenarikan (Status='PENDING')
5. (User flow approval...)
6. Saat APPROVED + PAID:
   - INSERT BS_trMutasiSaldo (Tersedia_Debit=jumlah, JTransaksi_ID=702)
   - UPDATE BS_trPenarikan SET Posting_Saldo=TRUE, Status='PAID'
```

## Implementasi PostgreSQL

### Function: `BS_AlokasiPenjualanFifo`

```sql
CREATE OR REPLACE FUNCTION "BS_AlokasiPenjualanFifo"(
  p_DetailIDPenjualan BIGINT
) RETURNS VOID AS $$
DECLARE
  v_Detail        RECORD;
  v_Penjualan     RECORD;
  v_Layer         RECORD;
  v_QtyDibutuh    NUMERIC(14,3);
  v_QtyAmbil      NUMERIC(14,3);
  v_SelisihPerKg  NUMERIC(14,2);
  v_NilaiEst      NUMERIC(14,2);
  v_NilaiRel      NUMERIC(14,2);
  v_FIFOKeluarID  BIGINT;
  v_TotalHpp      NUMERIC(14,2) := 0;
BEGIN
  SELECT * INTO v_Detail FROM "BS_trPenjualanDetail"
  WHERE "Detail_ID" = p_DetailIDPenjualan;

  SELECT * INTO v_Penjualan FROM "BS_trPenjualan"
  WHERE "No_Bukti" = v_Detail."No_Bukti";

  v_QtyDibutuh := v_Detail."Qty";

  FOR v_Layer IN
    SELECT * FROM "BS_trStockLayer"
    WHERE "Lokasi_ID" = v_Penjualan."Lokasi_ID"
      AND "Sampah_ID" = v_Detail."Sampah_ID"
      AND "Status" = 'ACTIVE'
    ORDER BY "Tgl_Masuk" ASC, "Layer_ID" ASC
    FOR UPDATE
  LOOP
    EXIT WHEN v_QtyDibutuh <= 0;

    v_QtyAmbil     := LEAST(v_Layer."Qty_Sisa", v_QtyDibutuh);
    v_SelisihPerKg := v_Detail."Harga_Jual" - v_Layer."Harga_Beli";
    v_NilaiEst     := v_Layer."Harga_Beli"   * v_QtyAmbil;
    v_NilaiRel     := v_Detail."Harga_Jual"  * v_QtyAmbil;

    INSERT INTO "BS_trKartuFIFO_Keluar"(
      "Lokasi_ID","Sampah_ID","No_Bukti","Detail_ID_Penjualan",
      "Layer_ID","Pegawai_ID","Qty_Keluar",
      "Harga_Beli","Harga_Jual","Selisih_PerKg","Total_Selisih",
      "NoBuktiAsal","UnitBisnisID"
    ) VALUES (
      v_Penjualan."Lokasi_ID", v_Detail."Sampah_ID", v_Penjualan."No_Bukti", p_DetailIDPenjualan,
      v_Layer."Layer_ID", v_Layer."Pegawai_ID", v_QtyAmbil,
      v_Layer."Harga_Beli", v_Detail."Harga_Jual", v_SelisihPerKg, v_SelisihPerKg * v_QtyAmbil,
      v_Layer."No_Bukti_Setoran", v_Penjualan."UnitBisnisID"
    ) RETURNING "FIFOKeluar_ID" INTO v_FIFOKeluarID;

    UPDATE "BS_trStockLayer"
    SET "Qty_Sisa" = "Qty_Sisa" - v_QtyAmbil,
        "Status"   = CASE
                       WHEN ("Qty_Sisa" - v_QtyAmbil) <= 0.001 THEN 'EXHAUSTED'
                       ELSE 'ACTIVE'
                     END
    WHERE "Layer_ID" = v_Layer."Layer_ID";

    INSERT INTO "BS_trMutasiSaldo"(
      "Pegawai_ID","JTransaksi_ID","No_Bukti_Ref","FIFOKeluar_ID_Ref",
      "Pending_Debit","Tersedia_Kredit",
      "Tgl_Mutasi","Keterangan",
      "User_ID","UnitBisnisID"
    ) VALUES (
      v_Layer."Pegawai_ID", 701, v_Penjualan."No_Bukti", v_FIFOKeluarID,
      v_NilaiEst, v_NilaiRel,
      v_Penjualan."Tgl_Penjualan",
      FORMAT('Realisasi penjualan %s kg @ %s (estimasi %s, realized %s, selisih %s)',
        v_QtyAmbil, v_Detail."Harga_Jual", v_NilaiEst, v_NilaiRel, v_SelisihPerKg * v_QtyAmbil),
      v_Penjualan."User_ID", v_Penjualan."UnitBisnisID"
    );

    v_TotalHpp   := v_TotalHpp + v_NilaiEst;
    v_QtyDibutuh := v_QtyDibutuh - v_QtyAmbil;
  END LOOP;

  IF v_QtyDibutuh > 0.001 THEN
    RAISE EXCEPTION 'Stock tidak cukup. Sisa kebutuhan: % kg', v_QtyDibutuh
      USING ERRCODE = 'P0001';
  END IF;

  UPDATE "BS_trPenjualanDetail" SET "Total_HPP_Detail" = v_TotalHpp
  WHERE "Detail_ID" = p_DetailIDPenjualan;
END;
$$ LANGUAGE plpgsql;
```

### Trigger: Auto-sync Saldo Pegawai

```sql
CREATE OR REPLACE FUNCTION "BS_TrgSyncSaldoPegawai"() RETURNS TRIGGER AS $$
DECLARE
  v_NewPending   NUMERIC(14,2);
  v_NewTersedia  NUMERIC(14,2);
BEGIN
  -- Insert atau update row saldo (idempotent)
  INSERT INTO "BS_tSaldoPegawai"("Pegawai_ID","UnitBisnisID","Saldo_Pending","Saldo_Tersedia")
  VALUES (NEW."Pegawai_ID", NEW."UnitBisnisID",
          NEW."Pending_Kredit"  - NEW."Pending_Debit",
          NEW."Tersedia_Kredit" - NEW."Tersedia_Debit")
  ON CONFLICT ("Pegawai_ID") DO UPDATE
  SET "Saldo_Pending"  = "BS_tSaldoPegawai"."Saldo_Pending"  + NEW."Pending_Kredit"  - NEW."Pending_Debit",
      "Saldo_Tersedia" = "BS_tSaldoPegawai"."Saldo_Tersedia" + NEW."Tersedia_Kredit" - NEW."Tersedia_Debit",
      "Tgl_Update"     = NOW()
  RETURNING "Saldo_Pending","Saldo_Tersedia" INTO v_NewPending, v_NewTersedia;

  -- Snapshot saldo sesudah ke row mutasi
  UPDATE "BS_trMutasiSaldo"
  SET "Saldo_Pending_Sesudah"  = v_NewPending,
      "Saldo_Tersedia_Sesudah" = v_NewTersedia
  WHERE "Mutasi_ID" = NEW."Mutasi_ID";

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "trg_BS_SyncSaldo"
AFTER INSERT ON "BS_trMutasiSaldo"
FOR EACH ROW EXECUTE FUNCTION "BS_TrgSyncSaldoPegawai"();
```

### Trigger: Auto-update Posisi Kartu Gudang

```sql
CREATE OR REPLACE FUNCTION "BS_TrgKartuGudangSaldo"() RETURNS TRIGGER AS $$
DECLARE
  v_PrevSaldo   NUMERIC(14,3);
  v_PrevHarga   NUMERIC(14,2);
  v_NewSaldo    NUMERIC(14,3);
  v_NewWAC      NUMERIC(14,2);
  v_TotalNilaiAwal NUMERIC(14,2);
BEGIN
  -- Cari row terakhir
  SELECT "Qty_Saldo","Harga_Persediaan" INTO v_PrevSaldo, v_PrevHarga
  FROM "BS_trKartuGudang"
  WHERE "Lokasi_ID" = NEW."Lokasi_ID"
    AND "Sampah_ID" = NEW."Sampah_ID"
    AND "RowTerakhir" = TRUE
  LIMIT 1;

  v_PrevSaldo := COALESCE(v_PrevSaldo, 0);
  v_PrevHarga := COALESCE(v_PrevHarga, 0);

  -- Hitung saldo + WAC baru
  v_NewSaldo := v_PrevSaldo + NEW."Qty_Masuk" - NEW."Qty_Keluar";

  IF NEW."Qty_Masuk" > 0 THEN
    -- WAC formula: ((SaldoLama * HargaLama) + (QtyMasuk * HargaMasuk)) / SaldoBaru
    v_TotalNilaiAwal := (v_PrevSaldo * v_PrevHarga) + (NEW."Qty_Masuk" * NEW."Harga_Masuk");
    v_NewWAC := CASE WHEN v_NewSaldo > 0 THEN v_TotalNilaiAwal / v_NewSaldo ELSE 0 END;
  ELSE
    v_NewWAC := v_PrevHarga;
  END IF;

  NEW."Qty_Saldo"        := v_NewSaldo;
  NEW."Harga_Persediaan" := v_NewWAC;

  -- Reset RowTerakhir di row sebelumnya
  UPDATE "BS_trKartuGudang"
  SET "RowTerakhir" = FALSE
  WHERE "Lokasi_ID" = NEW."Lokasi_ID"
    AND "Sampah_ID" = NEW."Sampah_ID"
    AND "RowTerakhir" = TRUE;

  NEW."RowTerakhir" := TRUE;

  -- Sync Stock_Akhir & HRataRata di mSampah (denormalisasi untuk performa)
  UPDATE "mSampah"
  SET "Stock_Akhir" = v_NewSaldo,
      "HRataRata"   = v_NewWAC
  WHERE "Sampah_ID" = NEW."Sampah_ID"
    AND "UnitBisnisID" = NEW."UnitBisnisID";

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "trg_BS_KartuGudangSaldo"
BEFORE INSERT ON "BS_trKartuGudang"
FOR EACH ROW EXECUTE FUNCTION "BS_TrgKartuGudangSaldo"();
```

## Contoh Skenario End-to-End

### Skenario 1: Multi-Owner, Harga Turun

State awal: layer kosong.

**Hari 1**: Pegawai A setor 30kg botol PET @ Rp 3.000/kg.
```
Layer A: { Pegawai=A, Qty_Awal=30, Qty_Sisa=30, Harga_Beli=3000, Status=ACTIVE }
Mutasi:  Pegawai A: Pending_Kredit = 90.000
Saldo A: Pending=90.000, Tersedia=0
```

**Hari 5**: Pegawai B setor 20kg botol PET @ Rp 3.000/kg.
```
Layer B: { Pegawai=B, Qty_Awal=20, Qty_Sisa=20, Harga_Beli=3000 }
Mutasi:  Pegawai B: Pending_Kredit = 60.000
Saldo B: Pending=60.000, Tersedia=0
```

**Hari 10**: Admin jual 40kg botol PET ke vendor @ Rp 2.500/kg (turun).

Eksekusi FIFO:
- Layer A diambil 30kg:
  - selisihPerKg = 2500 − 3000 = −500
  - estimasi = 30 × 3000 = 90.000
  - realized = 30 × 2500 = 75.000
  - Mutasi A: Pending_Debit=90.000, Tersedia_Kredit=75.000 → Pending 0, Tersedia 75.000
- Layer B diambil 10kg:
  - selisihPerKg = −500
  - estimasi = 10 × 3000 = 30.000
  - realized = 10 × 2500 = 25.000
  - Mutasi B: Pending_Debit=30.000, Tersedia_Kredit=25.000 → Pending 30.000 (sisa 10kg), Tersedia 25.000

**Hasil**:
- Saldo A: Pending=0, Tersedia=75.000 (bisa tarik)
- Saldo B: Pending=30.000, Tersedia=25.000

Selisih harga turun (-500/kg) **otomatis nyangkut ke A & B** sesuai kontribusi mereka.

### Skenario 2: Harga Naik

Sama dengan di atas tapi harga jual Rp 3.500/kg:
- Layer A: estimasi 90.000, realized 105.000 → Pegawai A dapet bonus 15.000.
- Layer B: estimasi 30.000, realized 35.000 → Pegawai B dapet bonus 5.000.

## Reversal & Adjustment

### VOID Setoran (sebelum dijual sebagian)
- Cek: SUM `BS_trKartuFIFO_Keluar` WHERE NoBuktiAsal=No_Bukti_Setoran. Kalau 0, bisa VOID.
- Insert reversal:
  - `BS_trKartuGudang` JTransaksi_ID=705 (Qty_Keluar = qty asli, untuk balikin stok)
  - `BS_trMutasiSaldo` Pending_Debit = subtotal asli
  - UPDATE `BS_trStockLayer` SET Status='EXHAUSTED' (atau soft delete via flag)
  - UPDATE `BS_trSetoran` SET Status_Batal=TRUE

### VOID Penjualan
- Insert reversal:
  - `BS_trKartuGudang` JTransaksi_ID=706 (Qty_Masuk = qty asli)
  - Untuk tiap row di `BS_trKartuFIFO_Keluar`:
    - INSERT layer baru (atau revive layer lama) dengan Qty_Awal/Qty_Sisa = qty yang dialokasikan
    - INSERT `BS_trMutasiSaldo` reversal: Tersedia_Debit, Pending_Kredit
  - UPDATE `BS_trPenjualan` SET Status_Batal=TRUE
- **Restriction**: gak boleh VOID kalau pegawai owner sudah tarik saldo > current Tersedia.

### Adjustment Manual (704)
Kasus: kesalahan input qty, kehilangan stok, dll. Wajib `Keterangan` dan `Disetujui` admin OPD.

## Hal Penting

1. **`FOR UPDATE`** wajib di loop layer untuk prevent race condition concurrent penjualan.
2. **`saldo` tabel snapshot bisa di-rebuild** dari `BS_trMutasiSaldo` kapan saja (audit + recovery friendly).
3. **`Posting_KG` & `Posting_Saldo`** flag transaksi 2-stage. Kalau insert detail tapi posting belum, bisa di-VOID langsung tanpa reversal entry.
4. **Selisih sub-rupiah** tetap dicatat. Pakai NUMERIC(14,2). Total dibulatkan saat display di UI.
5. **Notifikasi pegawai** saat realisasi: trigger AFTER INSERT di `BS_trMutasiSaldo` WHERE JTransaksi_ID=701 → push notification atau in-app feed.
