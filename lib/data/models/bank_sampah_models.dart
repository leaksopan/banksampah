class Pegawai {
  const Pegawai({
    required this.pegawaiId,
    required this.namaPegawai,
    required this.nip,
    required this.unitBisnisId,
    this.userId,
    this.noTelepon = '',
    this.email = '',
    this.statusAktif = true,
  });

  final int pegawaiId;
  final String namaPegawai;
  final String nip;
  final int unitBisnisId;
  final int? userId;
  final String noTelepon;
  final String email;
  final bool statusAktif;

  factory Pegawai.fromJson(Map<String, dynamic> json) {
    return Pegawai(
      pegawaiId: json['Pegawai_ID'] as int,
      namaPegawai: (json['Nama_Pegawai'] as String?) ?? '',
      nip: (json['NIP'] as String?) ?? '',
      unitBisnisId: json['UnitBisnisID'] as int,
      userId: json['User_ID'] as int?,
      noTelepon: (json['No_Telepon'] as String?) ?? '',
      email: (json['Email'] as String?) ?? '',
      statusAktif: (json['Status_Aktif'] as bool?) ?? true,
    );
  }
}

class Lokasi {
  const Lokasi({
    required this.lokasiId,
    required this.kodeLokasi,
    required this.namaLokasi,
    required this.unitBisnisId,
    this.tipeLokasi = '',
    this.alamat = '',
    this.gudangUtama = false,
    this.statusAktif = true,
  });

  final int lokasiId;
  final String kodeLokasi;
  final String namaLokasi;
  final int unitBisnisId;
  final String tipeLokasi;
  final String alamat;
  final bool gudangUtama;
  final bool statusAktif;

  factory Lokasi.fromJson(Map<String, dynamic> json) {
    return Lokasi(
      lokasiId: json['Lokasi_ID'] as int,
      kodeLokasi: (json['Kode_Lokasi'] as String?) ?? '',
      namaLokasi: (json['Nama_Lokasi'] as String?) ?? '',
      unitBisnisId: json['UnitBisnisID'] as int,
      tipeLokasi: (json['Tipe_Lokasi'] as String?) ?? '',
      alamat: (json['Alamat'] as String?) ?? '',
      gudangUtama: (json['Gudang_Utama'] as bool?) ?? false,
      statusAktif: (json['Status_Aktif'] as bool?) ?? true,
    );
  }
}

class Sampah {
  const Sampah({
    required this.sampahId,
    required this.kodeSampah,
    required this.namaSampah,
    required this.kodeSatuan,
    required this.hargaBeli,
    required this.stockAkhir,
    required this.unitBisnisId,
    this.kategoriId,
    this.namaKategori = '',
    this.hargaJual = 0,
    this.minStock = 0,
    this.aktif = true,
  });

  final int sampahId;
  final String kodeSampah;
  final String namaSampah;
  final String kodeSatuan;
  final num hargaBeli;
  final num stockAkhir;
  final int unitBisnisId;
  final int? kategoriId;
  final String namaKategori;
  final num hargaJual;
  final num minStock;
  final bool aktif;

  factory Sampah.fromJson(Map<String, dynamic> json) {
    final kategori = json['mKategori'];
    return Sampah(
      sampahId: json['Sampah_ID'] as int,
      kodeSampah: (json['Kode_Sampah'] as String?) ?? '',
      namaSampah: (json['Nama_Sampah'] as String?) ?? '',
      kodeSatuan: (json['Kode_Satuan'] as String?) ?? 'KG',
      hargaBeli: (json['Harga_Beli'] as num?) ?? 0,
      stockAkhir: (json['Stock_Akhir'] as num?) ?? 0,
      unitBisnisId: json['UnitBisnisID'] as int,
      kategoriId: json['Kategori_ID'] as int?,
      namaKategori:
          kategori is Map<String, dynamic>
              ? (kategori['Nama_Kategori'] as String?) ?? ''
              : '',
      hargaJual: (json['Harga_Jual'] as num?) ?? 0,
      minStock: (json['Min_Stock'] as num?) ?? 0,
      aktif: (json['Aktif'] as bool?) ?? true,
    );
  }
}

class Kategori {
  const Kategori({
    required this.kategoriId,
    required this.kodeKategori,
    required this.namaKategori,
  });

  final int kategoriId;
  final String kodeKategori;
  final String namaKategori;

  factory Kategori.fromJson(Map<String, dynamic> json) {
    return Kategori(
      kategoriId: json['Kategori_ID'] as int,
      kodeKategori: (json['Kode_Kategori'] as String?) ?? '',
      namaKategori: (json['Nama_Kategori'] as String?) ?? '',
    );
  }
}

class Satuan {
  const Satuan({
    required this.kodeSatuan,
    required this.namaSatuan,
  });

  final String kodeSatuan;
  final String namaSatuan;

  factory Satuan.fromJson(Map<String, dynamic> json) {
    return Satuan(
      kodeSatuan: json['Kode_Satuan'] as String,
      namaSatuan: (json['Nama_Satuan'] as String?) ?? '',
    );
  }
}

class Vendor {
  const Vendor({
    required this.vendorId,
    required this.kodeVendor,
    required this.namaVendor,
    required this.statusAktif,
    required this.unitBisnisId,
    this.kodeKategori,
    this.namaKategori = '',
    this.alamat = '',
    this.noTelepon = '',
    this.alamatEmail = '',
    this.noNpwp = '',
    this.atasNama = '',
    this.bank = '',
    this.noRek = '',
  });

  final int vendorId;
  final String kodeVendor;
  final String namaVendor;
  final String? kodeKategori;
  final String namaKategori;
  final String alamat;
  final String noTelepon;
  final String alamatEmail;
  final String noNpwp;
  final String atasNama;
  final String bank;
  final String noRek;
  final bool statusAktif;
  final int unitBisnisId;

  factory Vendor.fromJson(Map<String, dynamic> json) {
    final kategori = json['mKategori_Vendor'];
    return Vendor(
      vendorId: json['Vendor_ID'] as int,
      kodeVendor: (json['Kode_Vendor'] as String?) ?? '',
      namaVendor: (json['Nama_Vendor'] as String?) ?? '',
      kodeKategori: json['Kode_Kategori'] as String?,
      namaKategori:
          kategori is Map<String, dynamic>
              ? (kategori['Kategori_Name'] as String?) ?? ''
              : '',
      alamat: (json['Alamat'] as String?) ?? '',
      noTelepon: (json['No_Telepon'] as String?) ?? '',
      alamatEmail: (json['Alamat_Email'] as String?) ?? '',
      noNpwp: (json['No_NPWP'] as String?) ?? '',
      atasNama: (json['Atas_Nama'] as String?) ?? '',
      bank: (json['Bank'] as String?) ?? '',
      noRek: (json['No_Rek'] as String?) ?? '',
      statusAktif: (json['Status_Aktif'] as bool?) ?? true,
      unitBisnisId: json['UnitBisnisID'] as int,
    );
  }
}

class KategoriVendor {
  const KategoriVendor({
    required this.kodeKategori,
    required this.kategoriName,
  });

  final String kodeKategori;
  final String kategoriName;

  factory KategoriVendor.fromJson(Map<String, dynamic> json) {
    return KategoriVendor(
      kodeKategori: json['Kode_Kategori'] as String,
      kategoriName: (json['Kategori_Name'] as String?) ?? '',
    );
  }
}

class Setoran {
  const Setoran({
    required this.noBukti,
    required this.tglSetoran,
    required this.pegawaiId,
    required this.lokasiId,
    required this.totalBerat,
    required this.totalNilai,
    required this.posted,
    required this.statusBatal,
    required this.unitBisnisId,
    this.namaPegawai = '',
    this.namaLokasi = '',
    this.keterangan = '',
    this.unitBisnisName = '',
  });

  final String noBukti;
  final DateTime tglSetoran;
  final int pegawaiId;
  final int lokasiId;
  final num totalBerat;
  final num totalNilai;
  final bool posted;
  final bool statusBatal;
  final int unitBisnisId;
  final String namaPegawai;
  final String namaLokasi;
  final String keterangan;
  final String unitBisnisName;

  factory Setoran.fromJson(Map<String, dynamic> json) {
    final pegawai = json['mPegawai'];
    final lokasi = json['mLokasi'];
    final unitBisnis = json['mUnitBisnis'];
    return Setoran(
      noBukti: json['No_Bukti'] as String,
      tglSetoran: DateTime.parse(json['Tgl_Setoran'] as String),
      pegawaiId: json['Pegawai_ID'] as int,
      lokasiId: json['Lokasi_ID'] as int,
      totalBerat: (json['Total_Berat'] as num?) ?? 0,
      totalNilai: (json['Total_Nilai'] as num?) ?? 0,
      posted: (json['Posted'] as bool?) ?? false,
      statusBatal: (json['Status_Batal'] as bool?) ?? false,
      unitBisnisId: json['UnitBisnisID'] as int,
      namaPegawai:
          pegawai is Map<String, dynamic>
              ? (pegawai['Nama_Pegawai'] as String?) ?? ''
              : '',
      namaLokasi:
          lokasi is Map<String, dynamic>
              ? (lokasi['Nama_Lokasi'] as String?) ?? ''
              : '',
      keterangan: (json['Keterangan'] as String?) ?? '',
      unitBisnisName:
          unitBisnis is Map<String, dynamic>
              ? (unitBisnis['UnitBisnisName'] as String?) ?? ''
              : '',
    );
  }
}

class SetoranDetail {
  const SetoranDetail({
    required this.detailId,
    required this.sampahId,
    required this.kodeSatuan,
    required this.qty,
    required this.hargaBeli,
    required this.subtotal,
    required this.noUrut,
    this.namaSampah = '',
  });

  final int detailId;
  final int sampahId;
  final String kodeSatuan;
  final num qty;
  final num hargaBeli;
  final num subtotal;
  final int noUrut;
  final String namaSampah;

  factory SetoranDetail.fromJson(Map<String, dynamic> json) {
    final sampah = json['mSampah'];
    return SetoranDetail(
      detailId: json['Detail_ID'] as int,
      sampahId: json['Sampah_ID'] as int,
      kodeSatuan: (json['Kode_Satuan'] as String?) ?? 'KG',
      qty: (json['Qty'] as num?) ?? 0,
      hargaBeli: (json['Harga_Beli'] as num?) ?? 0,
      subtotal: (json['Subtotal'] as num?) ?? 0,
      noUrut: json['NoUrut'] as int,
      namaSampah:
          sampah is Map<String, dynamic>
              ? (sampah['Nama_Sampah'] as String?) ?? ''
              : '',
    );
  }
}

class Penjualan {
  const Penjualan({
    required this.noBukti,
    required this.tglPenjualan,
    required this.vendorId,
    required this.lokasiId,
    required this.totalBerat,
    required this.totalNilai,
    required this.totalHpp,
    required this.totalSelisih,
    required this.typePembayaran,
    required this.posted,
    required this.disetujui,
    required this.statusBatal,
    required this.unitBisnisId,
    this.namaVendor = '',
    this.namaLokasi = '',
    this.keterangan = '',
  });

  final String noBukti;
  final DateTime tglPenjualan;
  final int vendorId;
  final int lokasiId;
  final num totalBerat;
  final num totalNilai;
  final num totalHpp;
  final num totalSelisih;
  final String typePembayaran;
  final bool posted;
  final bool disetujui;
  final bool statusBatal;
  final int unitBisnisId;
  final String namaVendor;
  final String namaLokasi;
  final String keterangan;

  factory Penjualan.fromJson(Map<String, dynamic> json) {
    final vendor = json['mVendor'];
    final lokasi = json['mLokasi'];
    return Penjualan(
      noBukti: json['No_Bukti'] as String,
      tglPenjualan: DateTime.parse(json['Tgl_Penjualan'] as String),
      vendorId: json['Vendor_ID'] as int,
      lokasiId: json['Lokasi_ID'] as int,
      totalBerat: (json['Total_Berat'] as num?) ?? 0,
      totalNilai: (json['Total_Nilai'] as num?) ?? 0,
      totalHpp: (json['Total_HPP'] as num?) ?? 0,
      totalSelisih: (json['Total_Selisih'] as num?) ?? 0,
      typePembayaran: (json['Type_Pembayaran'] as String?) ?? 'C',
      posted: (json['Posted'] as bool?) ?? false,
      disetujui: (json['Disetujui'] as bool?) ?? false,
      statusBatal: (json['Status_Batal'] as bool?) ?? false,
      unitBisnisId: json['UnitBisnisID'] as int,
      namaVendor:
          vendor is Map<String, dynamic>
              ? (vendor['Nama_Vendor'] as String?) ?? ''
              : '',
      namaLokasi:
          lokasi is Map<String, dynamic>
              ? (lokasi['Nama_Lokasi'] as String?) ?? ''
              : '',
      keterangan: (json['Keterangan'] as String?) ?? '',
    );
  }
}

class PenjualanDetail {
  const PenjualanDetail({
    required this.detailId,
    required this.sampahId,
    required this.kodeSatuan,
    required this.qty,
    required this.hargaJual,
    required this.subtotal,
    required this.totalHppDetail,
    required this.noUrut,
    this.namaSampah = '',
  });

  final int detailId;
  final int sampahId;
  final String kodeSatuan;
  final num qty;
  final num hargaJual;
  final num subtotal;
  final num totalHppDetail;
  final int noUrut;
  final String namaSampah;

  factory PenjualanDetail.fromJson(Map<String, dynamic> json) {
    final sampah = json['mSampah'];
    return PenjualanDetail(
      detailId: json['Detail_ID'] as int,
      sampahId: json['Sampah_ID'] as int,
      kodeSatuan: (json['Kode_Satuan'] as String?) ?? 'KG',
      qty: (json['Qty'] as num?) ?? 0,
      hargaJual: (json['Harga_Jual'] as num?) ?? 0,
      subtotal: (json['Subtotal'] as num?) ?? 0,
      totalHppDetail: (json['Total_HPP_Detail'] as num?) ?? 0,
      noUrut: json['NoUrut'] as int,
      namaSampah:
          sampah is Map<String, dynamic>
              ? (sampah['Nama_Sampah'] as String?) ?? ''
              : '',
    );
  }
}

class SaldoPegawai {
  const SaldoPegawai({
    required this.pegawaiId,
    required this.saldoPending,
    required this.saldoTersedia,
    required this.totalBeratSetor,
    this.totalDitarik = 0,
  });

  final int pegawaiId;
  final num saldoPending;
  final num saldoTersedia;
  final num totalBeratSetor;
  final num totalDitarik;

  factory SaldoPegawai.empty(int pegawaiId) {
    return SaldoPegawai(
      pegawaiId: pegawaiId,
      saldoPending: 0,
      saldoTersedia: 0,
      totalBeratSetor: 0,
      totalDitarik: 0,
    );
  }

  factory SaldoPegawai.fromJson(Map<String, dynamic> json) {
    return SaldoPegawai(
      pegawaiId: json['Pegawai_ID'] as int,
      saldoPending: (json['Saldo_Pending'] as num?) ?? 0,
      saldoTersedia: (json['Saldo_Tersedia'] as num?) ?? 0,
      totalBeratSetor: (json['Total_Berat_Setor'] as num?) ?? 0,
      totalDitarik: (json['Total_Ditarik'] as num?) ?? 0,
    );
  }
}

class MutasiSaldo {
  const MutasiSaldo({
    required this.mutasiId,
    required this.noBuktiRef,
    required this.pendingKredit,
    required this.pendingDebit,
    required this.tersediaKredit,
    required this.tersediaDebit,
    required this.tglMutasi,
    required this.keterangan,
  });

  final int mutasiId;
  final String noBuktiRef;
  final num pendingKredit;
  final num pendingDebit;
  final num tersediaKredit;
  final num tersediaDebit;
  final DateTime tglMutasi;
  final String keterangan;

  factory MutasiSaldo.fromJson(Map<String, dynamic> json) {
    return MutasiSaldo(
      mutasiId: json['Mutasi_ID'] as int,
      noBuktiRef: (json['No_Bukti_Ref'] as String?) ?? '',
      pendingKredit: (json['Pending_Kredit'] as num?) ?? 0,
      pendingDebit: (json['Pending_Debit'] as num?) ?? 0,
      tersediaKredit: (json['Tersedia_Kredit'] as num?) ?? 0,
      tersediaDebit: (json['Tersedia_Debit'] as num?) ?? 0,
      tglMutasi: DateTime.parse(json['Tgl_Mutasi'] as String),
      keterangan: (json['Keterangan'] as String?) ?? '',
    );
  }
}

class CreatedSetoran {
  const CreatedSetoran({
    required this.noBukti,
    required this.totalBerat,
    required this.totalNilai,
    required this.detailCount,
  });

  final String noBukti;
  final num totalBerat;
  final num totalNilai;
  final int detailCount;

  factory CreatedSetoran.fromJson(Map<String, dynamic> json) {
    return CreatedSetoran(
      noBukti: json['no_bukti'] as String,
      totalBerat: (json['total_berat'] as num?) ?? 0,
      totalNilai: (json['total_nilai'] as num?) ?? 0,
      detailCount: (json['detail_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class CreatedPenjualan {
  const CreatedPenjualan({
    required this.noBukti,
    required this.totalBerat,
    required this.totalNilai,
    required this.totalHpp,
    required this.totalSelisih,
    required this.detailCount,
  });

  final String noBukti;
  final num totalBerat;
  final num totalNilai;
  final num totalHpp;
  final num totalSelisih;
  final int detailCount;

  factory CreatedPenjualan.fromJson(Map<String, dynamic> json) {
    return CreatedPenjualan(
      noBukti: json['no_bukti'] as String,
      totalBerat: (json['total_berat'] as num?) ?? 0,
      totalNilai: (json['total_nilai'] as num?) ?? 0,
      totalHpp: (json['total_hpp'] as num?) ?? 0,
      totalSelisih: (json['total_selisih'] as num?) ?? 0,
      detailCount: (json['detail_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class Penarikan {
  const Penarikan({
    required this.noBukti,
    required this.tglPenarikan,
    required this.pegawaiId,
    required this.jumlah,
    required this.typePembayaran,
    this.noRek,
    this.namaBank,
    this.atasNama,
    required this.status,
    required this.disetujui,
    this.disetujuiTgl,
    this.disetujuiUserId,
    this.tglBayar,
    this.userBayar,
    this.buktiTransferUrl,
    this.keterangan = '',
    required this.statusBatal,
    required this.postingSaldo,
    required this.unitBisnisId,
    this.namaPegawai = '',
  });

  final String noBukti;
  final DateTime tglPenarikan;
  final int pegawaiId;
  final num jumlah;
  final String typePembayaran;
  final String? noRek;
  final String? namaBank;
  final String? atasNama;
  final String status;
  final bool disetujui;
  final DateTime? disetujuiTgl;
  final int? disetujuiUserId;
  final DateTime? tglBayar;
  final int? userBayar;
  final String? buktiTransferUrl;
  final String keterangan;
  final bool statusBatal;
  final bool postingSaldo;
  final int unitBisnisId;
  final String namaPegawai;

  factory Penarikan.fromJson(Map<String, dynamic> json) {
    final pegawai = json['mPegawai'];
    return Penarikan(
      noBukti: json['No_Bukti'] as String,
      tglPenarikan: DateTime.parse(json['Tgl_Penarikan'] as String),
      pegawaiId: json['Pegawai_ID'] as int,
      jumlah: (json['Jumlah'] as num?) ?? 0,
      typePembayaran: (json['Type_Pembayaran'] as String?) ?? 'C',
      noRek: json['No_Rek'] as String?,
      namaBank: json['Nama_Bank'] as String?,
      atasNama: json['Atas_Nama'] as String?,
      status: (json['Status'] as String?) ?? 'PENDING',
      disetujui: (json['Disetujui'] as bool?) ?? false,
      disetujuiTgl: json['DisetujuiTgl'] != null
          ? DateTime.parse(json['DisetujuiTgl'] as String)
          : null,
      disetujuiUserId: json['DisetujuiUserID'] as int?,
      tglBayar: json['Tgl_Bayar'] != null
          ? DateTime.parse(json['Tgl_Bayar'] as String)
          : null,
      userBayar: json['User_Bayar'] as int?,
      buktiTransferUrl: json['Bukti_Transfer_URL'] as String?,
      keterangan: (json['Keterangan'] as String?) ?? '',
      statusBatal: (json['Status_Batal'] as bool?) ?? false,
      postingSaldo: (json['Posting_Saldo'] as bool?) ?? false,
      unitBisnisId: json['UnitBisnisID'] as int,
      namaPegawai:
          pegawai is Map<String, dynamic>
              ? (pegawai['Nama_Pegawai'] as String?) ?? ''
              : '',
    );
  }
}

class StockCurrent {
  const StockCurrent({
    required this.lokasiId,
    required this.namaLokasi,
    required this.sampahId,
    required this.namaSampah,
    required this.kodeSampah,
    required this.stockAkhir,
    required this.hargaRata,
    required this.unitBisnisId,
  });

  final int lokasiId;
  final String namaLokasi;
  final int sampahId;
  final String namaSampah;
  final String kodeSampah;
  final num stockAkhir;
  final num hargaRata;
  final int unitBisnisId;

  factory StockCurrent.fromJson(Map<String, dynamic> json) {
    return StockCurrent(
      lokasiId: json['Lokasi_ID'] as int,
      namaLokasi: (json['Nama_Lokasi'] as String?) ?? '',
      sampahId: json['Sampah_ID'] as int,
      namaSampah: (json['Nama_Sampah'] as String?) ?? '',
      kodeSampah: (json['Kode_Sampah'] as String?) ?? '',
      stockAkhir: (json['Stock_Akhir'] as num?) ?? 0,
      hargaRata: (json['Harga_Rata'] as num?) ?? 0,
      unitBisnisId: json['UnitBisnisID'] as int,
    );
  }
}

class RingkasanPegawai {
  const RingkasanPegawai({
    required this.pegawaiId,
    required this.namaPegawai,
    required this.nip,
    required this.unitBisnisId,
    required this.unitBisnisName,
    required this.saldoPending,
    required this.saldoTersedia,
    required this.totalDitarik,
    required this.totalBeratSetor,
    required this.totalBeratTerjual,
  });

  final int pegawaiId;
  final String namaPegawai;
  final String nip;
  final int unitBisnisId;
  final String unitBisnisName;
  final num saldoPending;
  final num saldoTersedia;
  final num totalDitarik;
  final num totalBeratSetor;
  final num totalBeratTerjual;

  factory RingkasanPegawai.fromJson(Map<String, dynamic> json) {
    return RingkasanPegawai(
      pegawaiId: json['Pegawai_ID'] as int,
      namaPegawai: (json['Nama_Pegawai'] as String?) ?? '',
      nip: (json['NIP'] as String?) ?? '',
      unitBisnisId: json['UnitBisnisID'] as int,
      unitBisnisName: (json['UnitBisnisName'] as String?) ?? '',
      saldoPending: (json['Saldo_Pending'] as num?) ?? 0,
      saldoTersedia: (json['Saldo_Tersedia'] as num?) ?? 0,
      totalDitarik: (json['Total_Ditarik'] as num?) ?? 0,
      totalBeratSetor: (json['Total_Berat_Setor'] as num?) ?? 0,
      totalBeratTerjual: (json['Total_Berat_Terjual'] as num?) ?? 0,
    );
  }
}

class ReportKartuGudang {
  const ReportKartuGudang({
    required this.kartuId,
    required this.lokasiId,
    required this.namaLokasi,
    required this.sampahId,
    required this.namaSampah,
    required this.noBukti,
    required this.namaTransaksi,
    required this.tglTransaksi,
    required this.qtyMasuk,
    required this.hargaMasuk,
    required this.qtyKeluar,
    required this.hargaKeluar,
    required this.qtySaldo,
    required this.hargaPersediaan,
    required this.unitBisnisId,
  });

  final int kartuId;
  final int lokasiId;
  final String namaLokasi;
  final int sampahId;
  final String namaSampah;
  final String noBukti;
  final String namaTransaksi;
  final DateTime tglTransaksi;
  final num qtyMasuk;
  final num hargaMasuk;
  final num qtyKeluar;
  final num hargaKeluar;
  final num qtySaldo;
  final num hargaPersediaan;
  final int unitBisnisId;

  factory ReportKartuGudang.fromJson(Map<String, dynamic> json) {
    return ReportKartuGudang(
      kartuId: (json['Kartu_ID'] as num).toInt(),
      lokasiId: json['Lokasi_ID'] as int,
      namaLokasi: (json['Nama_Lokasi'] as String?) ?? '',
      sampahId: json['Sampah_ID'] as int,
      namaSampah: (json['Nama_Sampah'] as String?) ?? '',
      noBukti: (json['No_Bukti'] as String?) ?? '',
      namaTransaksi: (json['Nama_Transaksi'] as String?) ?? '',
      tglTransaksi: DateTime.parse(json['Tgl_Transaksi'] as String),
      qtyMasuk: (json['Qty_Masuk'] as num?) ?? 0,
      hargaMasuk: (json['Harga_Masuk'] as num?) ?? 0,
      qtyKeluar: (json['Qty_Keluar'] as num?) ?? 0,
      hargaKeluar: (json['Harga_Keluar'] as num?) ?? 0,
      qtySaldo: (json['Qty_Saldo'] as num?) ?? 0,
      hargaPersediaan: (json['Harga_Persediaan'] as num?) ?? 0,
      unitBisnisId: json['UnitBisnisID'] as int,
    );
  }
}

class ReportSelisihRealisasi {
  const ReportSelisihRealisasi({
    required this.fifoKeluarId,
    required this.noBukti,
    required this.tglPenjualan,
    required this.namaSampah,
    required this.qtyKeluar,
    required this.hargaBeli,
    required this.hargaJual,
    required this.selisihPerKg,
    required this.totalSelisih,
    required this.noBuktiAsal,
  });

  final int fifoKeluarId;
  final String noBukti;
  final DateTime tglPenjualan;
  final String namaSampah;
  final num qtyKeluar;
  final num hargaBeli;
  final num hargaJual;
  final num selisihPerKg;
  final num totalSelisih;
  final String noBuktiAsal;

  factory ReportSelisihRealisasi.fromJson(Map<String, dynamic> json) {
    return ReportSelisihRealisasi(
      fifoKeluarId: (json['FIFOKeluar_ID'] as num).toInt(),
      noBukti: (json['No_Bukti'] as String?) ?? '',
      tglPenjualan: DateTime.parse(json['Tgl_Penjualan'] as String),
      namaSampah: (json['Nama_Sampah'] as String?) ?? '',
      qtyKeluar: (json['Qty_Keluar'] as num?) ?? 0,
      hargaBeli: (json['Harga_Beli'] as num?) ?? 0,
      hargaJual: (json['Harga_Jual'] as num?) ?? 0,
      selisihPerKg: (json['Selisih_PerKg'] as num?) ?? 0,
      totalSelisih: (json['Total_Selisih'] as num?) ?? 0,
      noBuktiAsal: (json['NoBuktiAsal'] as String?) ?? '',
    );
  }
}

class UnitBisnis {
  const UnitBisnis({
    required this.unitBisnisId,
    required this.unitBisnisName,
    required this.kodeOpd,
    required this.tipeOpd,
    this.warnaPrimary,
    this.logoUrl,
    required this.statusAktif,
  });

  final int unitBisnisId;
  final String unitBisnisName;
  final String kodeOpd;
  final String tipeOpd;
  final String? warnaPrimary;
  final String? logoUrl;
  final bool statusAktif;

  factory UnitBisnis.fromJson(Map<String, dynamic> json) {
    return UnitBisnis(
      unitBisnisId: json['UnitBisnisID'] as int,
      unitBisnisName: (json['UnitBisnisName'] as String?) ?? '',
      kodeOpd: (json['Kode_OPD'] as String?) ?? '',
      tipeOpd: (json['Tipe_OPD'] as String?) ?? '',
      warnaPrimary: json['Warna_Primary'] as String?,
      logoUrl: json['Logo_URL'] as String?,
      statusAktif: (json['Status_Aktif'] as bool?) ?? true,
    );
  }
}

class COA {
  const COA({
    required this.coaId,
    required this.coaName,
    required this.kategoriCoa,
    required this.normalBalance,
  });

  final String coaId;
  final String coaName;
  final String kategoriCoa;
  final String normalBalance;

  factory COA.fromJson(Map<String, dynamic> json) {
    return COA(
      coaId: json['COA_ID'] as String,
      coaName: (json['COA_Name'] as String?) ?? '',
      kategoriCoa: (json['Kategori_COA'] as String?) ?? '',
      normalBalance: (json['Normal_Balance'] as String?) ?? 'D',
    );
  }
}

class ReportNeracaItem {
  const ReportNeracaItem({
    required this.coaId,
    required this.coaName,
    required this.kategoriCoa,
    required this.saldo,
  });

  final String coaId;
  final String coaName;
  final String kategoriCoa;
  final num saldo;

  factory ReportNeracaItem.fromJson(Map<String, dynamic> json) {
    return ReportNeracaItem(
      coaId: json['COA_ID'] as String,
      coaName: (json['COA_Name'] as String?) ?? '',
      kategoriCoa: (json['Kategori_COA'] as String?) ?? '',
      saldo: (json['Saldo'] as num?) ?? 0.0,
    );
  }
}

class ReportHppLabaRugi {
  const ReportHppLabaRugi({
    required this.totalPendapatan,
    required this.totalHpp,
    required this.totalPenyesuaianPendapatan,
    required this.totalPenyesuaianBeban,
    required this.labaRugiBersih,
  });

  final num totalPendapatan;
  final num totalHpp;
  final num totalPenyesuaianPendapatan;
  final num totalPenyesuaianBeban;
  final num labaRugiBersih;

  factory ReportHppLabaRugi.fromJson(Map<String, dynamic> json) {
    return ReportHppLabaRugi(
      totalPendapatan: (json['Total_Pendapatan'] as num?) ?? 0.0,
      totalHpp: (json['Total_HPP'] as num?) ?? 0.0,
      totalPenyesuaianPendapatan: (json['Total_Penyesuaian_Pendapatan'] as num?) ?? 0.0,
      totalPenyesuaianBeban: (json['Total_Penyesuaian_Beban'] as num?) ?? 0.0,
      labaRugiBersih: (json['Laba_Rugi_Bersih'] as num?) ?? 0.0,
    );
  }
}

