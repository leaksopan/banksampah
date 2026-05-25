import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/providers/auth_state_provider.dart';
import '../models/bank_sampah_models.dart';

final bankSampahRepositoryProvider = Provider<BankSampahRepository>((ref) {
  if (Uri.base.toString().contains('bypass_auth=true')) {
    return MockBankSampahRepository();
  }
  return BankSampahRepository(ref.watch(supabaseClientProvider));
});

class BankSampahRepository {
  const BankSampahRepository(this._client);

  final SupabaseClient _client;

  Future<List<Pegawai>> listPegawaiAktif() async {
    final response = await _client
        .from('mPegawai')
        .select(
          'Pegawai_ID, User_ID, Nama_Pegawai, NIP, No_Telepon, Email, Status_Aktif, UnitBisnisID',
        )
        .eq('Status_Aktif', true)
        .order('Nama_Pegawai');

    return _mapList(response, Pegawai.fromJson);
  }

  Future<List<Pegawai>> listPegawaiMaster({int? unitBisnisId}) async {
    var query = _client
        .from('mPegawai')
        .select(
          'Pegawai_ID, User_ID, Nama_Pegawai, NIP, No_Telepon, Email, Status_Aktif, UnitBisnisID',
        );

    if (unitBisnisId != null) {
      query = query.eq('UnitBisnisID', unitBisnisId);
    }

    final response = await query
        .order('Status_Aktif', ascending: false)
        .order('Nama_Pegawai');

    return _mapList(response, Pegawai.fromJson);
  }

  Future<Pegawai?> getPegawaiByUserId(int userId) async {
    final response =
        await _client
            .from('mPegawai')
            .select(
              'Pegawai_ID, User_ID, Nama_Pegawai, NIP, No_Telepon, Email, Status_Aktif, UnitBisnisID',
            )
            .eq('User_ID', userId)
            .eq('Status_Aktif', true)
            .maybeSingle();

    return response == null ? null : Pegawai.fromJson(response);
  }

  Future<List<Lokasi>> listLokasiAktif() async {
    final response = await _client
        .from('mLokasi')
        .select(
          'Lokasi_ID, Kode_Lokasi, Nama_Lokasi, Tipe_Lokasi, Alamat, Gudang_Utama, Status_Aktif, UnitBisnisID',
        )
        .eq('Status_Aktif', true)
        .order('Nama_Lokasi');

    return _mapList(response, Lokasi.fromJson);
  }

  Future<List<Lokasi>> listLokasiMaster() async {
    final response = await _client
        .from('mLokasi')
        .select(
          'Lokasi_ID, Kode_Lokasi, Nama_Lokasi, Tipe_Lokasi, Alamat, Gudang_Utama, Status_Aktif, UnitBisnisID',
        )
        .order('Status_Aktif', ascending: false)
        .order('Nama_Lokasi');

    return _mapList(response, Lokasi.fromJson);
  }

  Future<List<Sampah>> listSampahAktif() async {
    final response = await _client
        .from('mSampah')
        .select(
          'Sampah_ID, Kode_Sampah, Nama_Sampah, Kategori_ID, Kode_Satuan, Harga_Beli, Harga_Jual, Stock_Akhir, Min_Stock, Aktif, UnitBisnisID, mKategori(Nama_Kategori)',
        )
        .eq('Aktif', true)
        .order('Nama_Sampah');

    return _mapList(response, Sampah.fromJson);
  }

  Future<List<Sampah>> listSampahMaster() async {
    final response = await _client
        .from('mSampah')
        .select(
          'Sampah_ID, Kode_Sampah, Nama_Sampah, Kategori_ID, Kode_Satuan, Harga_Beli, Harga_Jual, Stock_Akhir, Min_Stock, Aktif, UnitBisnisID, mKategori(Nama_Kategori)',
        )
        .order('Aktif', ascending: false)
        .order('Nama_Sampah');

    return _mapList(response, Sampah.fromJson);
  }

  Future<List<Kategori>> listKategoriAktif() async {
    final response = await _client
        .from('mKategori')
        .select('Kategori_ID, Kode_Kategori, Nama_Kategori')
        .eq('Status_Aktif', true)
        .order('Nama_Kategori');

    return _mapList(response, Kategori.fromJson);
  }

  Future<List<Satuan>> listSatuan() async {
    final response = await _client
        .from('mSatuan')
        .select('Kode_Satuan, Nama_Satuan')
        .order('Satuan_Default', ascending: false)
        .order('Nama_Satuan');

    return _mapList(response, Satuan.fromJson);
  }

  Future<List<KategoriVendor>> listKategoriVendor() async {
    final response = await _client
        .from('mKategori_Vendor')
        .select('Kode_Kategori, Kategori_Name')
        .order('Kategori_Name');

    return _mapList(response, KategoriVendor.fromJson);
  }

  Future<List<Vendor>> listVendorMaster() async {
    final response = await _client
        .from('mVendor')
        .select(
          'Vendor_ID, Kode_Vendor, Nama_Vendor, Kode_Kategori, Alamat, No_Telepon, Alamat_Email, No_NPWP, Atas_Nama, Bank, No_Rek, Status_Aktif, UnitBisnisID, mKategori_Vendor(Kategori_Name)',
        )
        .order('Status_Aktif', ascending: false)
        .order('Nama_Vendor');

    return _mapList(response, Vendor.fromJson);
  }

  Future<List<Vendor>> listVendorAktif() async {
    final response = await _client
        .from('mVendor')
        .select(
          'Vendor_ID, Kode_Vendor, Nama_Vendor, Kode_Kategori, Alamat, No_Telepon, Alamat_Email, No_NPWP, Atas_Nama, Bank, No_Rek, Status_Aktif, UnitBisnisID, mKategori_Vendor(Kategori_Name)',
        )
        .eq('Status_Aktif', true)
        .order('Nama_Vendor');

    return _mapList(response, Vendor.fromJson);
  }

  Future<void> updatePegawai({
    required int pegawaiId,
    required String namaPegawai,
    required String nip,
    required String noTelepon,
    required String email,
    required bool statusAktif,
    int? userUpdate,
  }) async {
    await _client
        .from('mPegawai')
        .update({
          'Nama_Pegawai': namaPegawai.trim(),
          'NIP': _nullIfBlank(nip),
          'No_Telepon': _nullIfBlank(noTelepon),
          'Email': _nullIfBlank(email),
          'Status_Aktif': statusAktif,
          'User_Update': userUpdate,
          'Tgl_Update': DateTime.now().toIso8601String(),
        })
        .eq('Pegawai_ID', pegawaiId);
  }

  Future<void> upsertLokasi({
    int? lokasiId,
    required int unitBisnisId,
    required String kodeLokasi,
    required String namaLokasi,
    required String tipeLokasi,
    required String alamat,
    required bool gudangUtama,
    required bool statusAktif,
  }) async {
    final payload = <String, dynamic>{
      'Kode_Lokasi': kodeLokasi.trim().toUpperCase(),
      'Nama_Lokasi': namaLokasi.trim(),
      'Tipe_Lokasi': _nullIfBlank(tipeLokasi),
      'Alamat': _nullIfBlank(alamat),
      'Gudang_Utama': gudangUtama,
      'Status_Aktif': statusAktif,
      'UnitBisnisID': unitBisnisId,
      'Tgl_Update': DateTime.now().toIso8601String(),
    };

    if (lokasiId == null) {
      await _client.from('mLokasi').insert(payload);
      return;
    }

    await _client.from('mLokasi').update(payload).eq('Lokasi_ID', lokasiId);
  }

  Future<void> upsertSampah({
    int? sampahId,
    required int unitBisnisId,
    required String kodeSampah,
    required String namaSampah,
    required int kategoriId,
    required String kodeSatuan,
    required num hargaBeli,
    required num hargaJual,
    required num minStock,
    required bool aktif,
    int? userUpdate,
  }) async {
    final payload = <String, dynamic>{
      'Kode_Sampah': kodeSampah.trim().toUpperCase(),
      'Nama_Sampah': namaSampah.trim(),
      'Kategori_ID': kategoriId,
      'Kode_Satuan': kodeSatuan,
      'Harga_Beli': hargaBeli,
      'Harga_Jual': hargaJual,
      'Min_Stock': minStock,
      'Aktif': aktif,
      'UnitBisnisID': unitBisnisId,
      'User_Update': userUpdate,
      'TglBerlaku_Harga': DateTime.now().toIso8601String(),
      'Tgl_Update': DateTime.now().toIso8601String(),
    };

    if (sampahId == null) {
      await _client.from('mSampah').insert(payload);
      return;
    }

    await _client.from('mSampah').update(payload).eq('Sampah_ID', sampahId);
  }

  Future<void> upsertVendor({
    int? vendorId,
    required int unitBisnisId,
    required String kodeVendor,
    required String namaVendor,
    required String kodeKategori,
    required String alamat,
    required String noTelepon,
    required String alamatEmail,
    required String noNpwp,
    required String atasNama,
    required String bank,
    required String noRek,
    required bool statusAktif,
  }) async {
    final payload = <String, dynamic>{
      'Kode_Vendor': kodeVendor.trim().toUpperCase(),
      'Nama_Vendor': namaVendor.trim(),
      'Kode_Kategori': kodeKategori,
      'Alamat': _nullIfBlank(alamat),
      'No_Telepon': _nullIfBlank(noTelepon),
      'Alamat_Email': _nullIfBlank(alamatEmail),
      'No_NPWP': _nullIfBlank(noNpwp),
      'Atas_Nama': _nullIfBlank(atasNama),
      'Bank': _nullIfBlank(bank),
      'No_Rek': _nullIfBlank(noRek),
      'Status_Aktif': statusAktif,
      'UnitBisnisID': unitBisnisId,
      'Tgl_Update': DateTime.now().toIso8601String(),
    };

    if (vendorId == null) {
      await _client.from('mVendor').insert(payload);
      return;
    }

    await _client.from('mVendor').update(payload).eq('Vendor_ID', vendorId);
  }

  Future<List<Setoran>> listSetoran({
    DateTime? from,
    DateTime? to,
    int? pegawaiId,
    int? lokasiId,
    int? limit,
  }) async {
    var query = _client
        .from('BS_trSetoran')
        .select(
          'No_Bukti, Tgl_Setoran, Pegawai_ID, Lokasi_ID, Total_Berat, Total_Nilai, Keterangan, Posted, Status_Batal, UnitBisnisID, mPegawai(Nama_Pegawai), mLokasi(Nama_Lokasi), mUnitBisnis(UnitBisnisName)',
        );

    if (from != null) {
      query = query.gte('Tgl_Setoran', from.toIso8601String());
    }
    if (to != null) {
      query = query.lt('Tgl_Setoran', to.toIso8601String());
    }
    if (pegawaiId != null) {
      query = query.eq('Pegawai_ID', pegawaiId);
    }
    if (lokasiId != null) {
      query = query.eq('Lokasi_ID', lokasiId);
    }

    final orderedQuery = query.order('Tgl_Setoran', ascending: false);
    final response =
        limit == null ? await orderedQuery : await orderedQuery.limit(limit);
    return _mapList(response, Setoran.fromJson);
  }

  Future<Setoran?> getSetoran(String noBukti) async {
    final response =
        await _client
            .from('BS_trSetoran')
            .select(
              'No_Bukti, Tgl_Setoran, Pegawai_ID, Lokasi_ID, Total_Berat, Total_Nilai, Keterangan, Posted, Status_Batal, UnitBisnisID, mPegawai(Nama_Pegawai), mLokasi(Nama_Lokasi), mUnitBisnis(UnitBisnisName)',
            )
            .eq('No_Bukti', noBukti)
            .maybeSingle();

    return response == null ? null : Setoran.fromJson(response);
  }

  Future<List<SetoranDetail>> listSetoranDetail(String noBukti) async {
    final response = await _client
        .from('BS_trSetoranDetail')
        .select(
          'Detail_ID, Sampah_ID, Kode_Satuan, Qty, Harga_Beli, Subtotal, NoUrut, mSampah(Nama_Sampah)',
        )
        .eq('No_Bukti', noBukti)
        .order('NoUrut');

    return _mapList(response, SetoranDetail.fromJson);
  }

  Future<CreatedSetoran> createSetoran({
    required int pegawaiId,
    required int lokasiId,
    required List<Map<String, dynamic>> details,
    String? keterangan,
  }) async {
    final response = await _client.rpc(
      'bs_create_setoran',
      params: <String, dynamic>{
        'p_pegawai_id': pegawaiId,
        'p_lokasi_id': lokasiId,
        'p_keterangan':
            keterangan == null || keterangan.trim().isEmpty
                ? null
                : keterangan.trim(),
        'p_details': details,
      },
    );

    return CreatedSetoran.fromJson(_mapRpcObject(response));
  }

  Future<CreatedSetoran> voidSetoran({
    required String noBukti,
    String? keterangan,
  }) async {
    final response = await _client.rpc(
      'bs_void_setoran',
      params: <String, dynamic>{
        'p_no_bukti': noBukti,
        'p_keterangan':
            keterangan == null || keterangan.trim().isEmpty
                ? null
                : keterangan.trim(),
      },
    );

    return CreatedSetoran.fromJson(_mapRpcObject(response));
  }

  Future<List<Penjualan>> listPenjualan({DateTime? from, DateTime? to}) async {
    var query = _client
        .from('BS_trPenjualan')
        .select(
          'No_Bukti, Tgl_Penjualan, Vendor_ID, Lokasi_ID, Total_Berat, Total_Nilai, Total_HPP, Total_Selisih, Type_Pembayaran, Keterangan, Posted, Disetujui, Status_Batal, UnitBisnisID, mVendor(Nama_Vendor), mLokasi(Nama_Lokasi)',
        );

    if (from != null) {
      query = query.gte('Tgl_Penjualan', from.toIso8601String());
    }
    if (to != null) {
      query = query.lt('Tgl_Penjualan', to.toIso8601String());
    }

    final response = await query.order('Tgl_Penjualan', ascending: false);
    return _mapList(response, Penjualan.fromJson);
  }

  Future<Penjualan?> getPenjualan(String noBukti) async {
    final response =
        await _client
            .from('BS_trPenjualan')
            .select(
              'No_Bukti, Tgl_Penjualan, Vendor_ID, Lokasi_ID, Total_Berat, Total_Nilai, Total_HPP, Total_Selisih, Type_Pembayaran, Keterangan, Posted, Disetujui, Status_Batal, UnitBisnisID, mVendor(Nama_Vendor), mLokasi(Nama_Lokasi)',
            )
            .eq('No_Bukti', noBukti)
            .maybeSingle();

    return response == null ? null : Penjualan.fromJson(response);
  }

  Future<List<PenjualanDetail>> listPenjualanDetail(String noBukti) async {
    final response = await _client
        .from('BS_trPenjualanDetail')
        .select(
          'Detail_ID, Sampah_ID, Kode_Satuan, Qty, Harga_Jual, Subtotal, Total_HPP_Detail, NoUrut, mSampah(Nama_Sampah)',
        )
        .eq('No_Bukti', noBukti)
        .order('NoUrut');

    return _mapList(response, PenjualanDetail.fromJson);
  }

  Future<CreatedPenjualan> createPenjualan({
    required int vendorId,
    required int lokasiId,
    required String typePembayaran,
    required List<Map<String, dynamic>> details,
    String? keterangan,
  }) async {
    final response = await _client.rpc(
      'bs_create_penjualan',
      params: <String, dynamic>{
        'p_vendor_id': vendorId,
        'p_lokasi_id': lokasiId,
        'p_type_pembayaran': typePembayaran,
        'p_keterangan':
            keterangan == null || keterangan.trim().isEmpty
                ? null
                : keterangan.trim(),
        'p_details': details,
      },
    );

    return CreatedPenjualan.fromJson(_mapRpcObject(response));
  }

  Future<SaldoPegawai> getSaldoPegawai(int pegawaiId) async {
    final response =
        await _client
            .from('BS_tSaldoPegawai')
            .select(
              'Pegawai_ID, Saldo_Pending, Saldo_Tersedia, Total_Berat_Setor',
            )
            .eq('Pegawai_ID', pegawaiId)
            .maybeSingle();

    return response == null
        ? SaldoPegawai.empty(pegawaiId)
        : SaldoPegawai.fromJson(response);
  }

  Future<List<MutasiSaldo>> listMutasiPegawai(
    int pegawaiId, {
    int limit = 5,
  }) async {
    final response = await _client
        .from('BS_trMutasiSaldo')
        .select(
          'Mutasi_ID, No_Bukti_Ref, Pending_Kredit, Pending_Debit, Tersedia_Kredit, Tersedia_Debit, Tgl_Mutasi, Keterangan',
        )
        .eq('Pegawai_ID', pegawaiId)
        .order('Tgl_Mutasi', ascending: false)
        .limit(limit);

    return _mapList(response, MutasiSaldo.fromJson);
  }

  Future<int> countPendingUsers() async {
    final response = await _client
        .from('mUser')
        .select('User_ID')
        .eq('Status_Approval', 'PENDING');

    return (response as List<dynamic>).length;
  }

  Future<List<Penarikan>> listPenarikan({
    DateTime? from,
    DateTime? to,
    int? pegawaiId,
    String? status,
  }) async {
    var query = _client
        .from('BS_trPenarikan')
        .select(
          'No_Bukti, Tgl_Penarikan, Pegawai_ID, Jumlah, Type_Pembayaran, No_Rek, Nama_Bank, Atas_Nama, Status, Disetujui, DisetujuiTgl, DisetujuiUserID, Tgl_Bayar, User_Bayar, Bukti_Transfer_URL, Keterangan, Status_Batal, Posting_Saldo, UnitBisnisID, mPegawai(Nama_Pegawai)',
        );

    if (from != null) {
      query = query.gte('Tgl_Penarikan', from.toIso8601String());
    }
    if (to != null) {
      query = query.lt('Tgl_Penarikan', to.toIso8601String());
    }
    if (pegawaiId != null) {
      query = query.eq('Pegawai_ID', pegawaiId);
    }
    if (status != null) {
      query = query.eq('Status', status);
    }

    final response = await query.order('Tgl_Penarikan', ascending: false);
    return _mapList(response, Penarikan.fromJson);
  }

  Future<Penarikan?> getPenarikan(String noBukti) async {
    final response = await _client
        .from('BS_trPenarikan')
        .select(
          'No_Bukti, Tgl_Penarikan, Pegawai_ID, Jumlah, Type_Pembayaran, No_Rek, Nama_Bank, Atas_Nama, Status, Disetujui, DisetujuiTgl, DisetujuiUserID, Tgl_Bayar, User_Bayar, Bukti_Transfer_URL, Keterangan, Status_Batal, Posting_Saldo, UnitBisnisID, mPegawai(Nama_Pegawai)',
        )
        .eq('No_Bukti', noBukti)
        .maybeSingle();

    return response == null ? null : Penarikan.fromJson(response);
  }

  Future<void> createPenarikan({
    required int pegawaiId,
    required num jumlah,
    required String typePembayaran,
    String? noRek,
    String? bank,
    String? atasNama,
    String? keterangan,
  }) async {
    await _client.rpc(
      'bs_create_penarikan',
      params: <String, dynamic>{
        'p_pegawai_id': pegawaiId,
        'p_jumlah': jumlah,
        'p_type_pembayaran': typePembayaran,
        'p_no_rek': _nullIfBlank(noRek ?? ''),
        'p_nama_bank': _nullIfBlank(bank ?? ''),
        'p_atas_nama': _nullIfBlank(atasNama ?? ''),
        'p_keterangan': _nullIfBlank(keterangan ?? ''),
      },
    );
  }

  Future<void> approvePenarikan({
    required String noBukti,
    required bool approve,
    String? keterangan,
  }) async {
    await _client.rpc(
      'bs_approve_penarikan',
      params: <String, dynamic>{
        'p_no_bukti': noBukti,
        'p_approve': approve,
        'p_keterangan': _nullIfBlank(keterangan ?? ''),
      },
    );
  }

  Future<void> payPenarikan({
    required String noBukti,
    String? buktiTransferUrl,
    String? keterangan,
  }) async {
    await _client.rpc(
      'bs_pay_penarikan',
      params: <String, dynamic>{
        'p_no_bukti': noBukti,
        'p_bukti_transfer_url': _nullIfBlank(buktiTransferUrl ?? ''),
        'p_keterangan': _nullIfBlank(keterangan ?? ''),
      },
    );
  }

  Future<List<StockCurrent>> listStockCurrent() async {
    final response = await _client
        .from('vBS_StockCurrent')
        .select(
          'Lokasi_ID, Nama_Lokasi, Sampah_ID, Nama_Sampah, Kode_Sampah, Stock_Akhir, Harga_Rata, UnitBisnisID',
        )
        .order('Nama_Lokasi')
        .order('Nama_Sampah');
    return _mapList(response, StockCurrent.fromJson);
  }

  Future<List<RingkasanPegawai>> listRingkasanPegawai() async {
    final response = await _client
        .from('vBS_RingkasanPegawai')
        .select(
          'Pegawai_ID, Nama_Pegawai, NIP, UnitBisnisID, UnitBisnisName, Saldo_Pending, Saldo_Tersedia, Total_Ditarik, Total_Berat_Setor, Total_Berat_Terjual',
        )
        .order('Nama_Pegawai');
    return _mapList(response, RingkasanPegawai.fromJson);
  }

  Future<List<ReportKartuGudang>> getReportKartuGudang({
    required int lokasiId,
    required int sampahId,
    DateTime? from,
    DateTime? to,
  }) async {
    final response = await _client.rpc(
      'bs_report_kartu_gudang',
      params: <String, dynamic>{
        'p_lokasi_id': lokasiId,
        'p_sampah_id': sampahId,
        'p_from': from?.toIso8601String(),
        'p_to': to?.toIso8601String(),
      },
    );
    return _mapList(response, ReportKartuGudang.fromJson);
  }

  Future<List<ReportSelisihRealisasi>> getReportSelisihRealisasi(
    int pegawaiId,
  ) async {
    final response = await _client.rpc(
      'bs_report_selisih_realisasi',
      params: <String, dynamic>{
        'p_pegawai_id': pegawaiId,
      },
    );
    return _mapList(response, ReportSelisihRealisasi.fromJson);
  }

  Future<UnitBisnis?> getUnitBisnis(int unitBisnisId) async {
    final response = await _client
        .from('mUnitBisnis')
        .select(
          'UnitBisnisID, UnitBisnisName, Kode_OPD, Tipe_OPD, Warna_Primary, Logo_URL, Status_Aktif',
        )
        .eq('UnitBisnisID', unitBisnisId)
        .maybeSingle();

    return response == null ? null : UnitBisnis.fromJson(response);
  }

  Future<List<UnitBisnis>> listUnitBisnis() async {
    final response = await _client
        .from('mUnitBisnis')
        .select(
          'UnitBisnisID, UnitBisnisName, Kode_OPD, Tipe_OPD, Warna_Primary, Logo_URL, Status_Aktif',
        )
        .eq('Status_Aktif', true)
        .order('UnitBisnisName');

    return _mapList(response, UnitBisnis.fromJson);
  }

  Future<Map<String, dynamic>> bulkImportPegawai({
    required int unitBisnisId,
    required List<Map<String, dynamic>> pegawaiList,
  }) async {
    final response = await _client.rpc(
      'bs_bulk_import_pegawai',
      params: <String, dynamic>{
        'p_unit_bisnis_id': unitBisnisId,
        'p_pegawai_list': pegawaiList,
      },
    );

    return _mapRpcObject(response);
  }

  Future<void> logError({
    required String errorMessage,
    String? stackTrace,
    String? deviceInfo,
  }) async {
    try {
      await _client.rpc(
        'bs_log_error',
        params: <String, dynamic>{
          'p_error_message': errorMessage,
          'p_stack_trace': stackTrace,
          'p_device_info': deviceInfo,
        },
      );
    } catch (_) {
      // Fail silently to avoid infinite error logging loops
    }
  }

  List<T> _mapList<T>(
    dynamic response,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }

  Map<String, dynamic> _mapRpcObject(dynamic response) {
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    if (response is List && response.isNotEmpty && response.first is Map) {
      return Map<String, dynamic>.from(response.first as Map);
    }

    throw const FormatException('Response RPC tidak valid.');
  }

  String? _nullIfBlank(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class MockBankSampahRepository extends BankSampahRepository {
  MockBankSampahRepository() : super(_MockSupabaseClient());

  @override
  Future<List<Pegawai>> listPegawaiAktif() async => const [
    Pegawai(pegawaiId: 1, userId: 1, namaPegawai: 'Pegawai DLH Playwright', nip: '199707072026051009', noTelepon: '089988776655', email: 'playwright.test@dlh.badung.go.id', statusAktif: true, unitBisnisId: 1)
  ];

  @override
  Future<List<Pegawai>> listPegawaiMaster({int? unitBisnisId}) async => const [
    Pegawai(pegawaiId: 1, userId: 1, namaPegawai: 'Pegawai DLH Playwright', nip: '199707072026051009', noTelepon: '089988776655', email: 'playwright.test@dlh.badung.go.id', statusAktif: true, unitBisnisId: 1)
  ];

  @override
  Future<Pegawai?> getPegawaiByUserId(int userId) async => const
    Pegawai(pegawaiId: 1, userId: 1, namaPegawai: 'Pegawai DLH Playwright', nip: '199707072026051009', noTelepon: '089988776655', email: 'playwright.test@dlh.badung.go.id', statusAktif: true, unitBisnisId: 1);

  @override
  Future<List<Lokasi>> listLokasiAktif() async => const [
    Lokasi(lokasiId: 1, kodeLokasi: 'TPS-01', namaLokasi: 'TPS Utama BKPSDM', tipeLokasi: 'TPS', alamat: 'Mangupura', gudangUtama: true, statusAktif: true, unitBisnisId: 1)
  ];

  @override
  Future<List<Lokasi>> listLokasiMaster() async => const [
    Lokasi(lokasiId: 1, kodeLokasi: 'TPS-01', namaLokasi: 'TPS Utama BKPSDM', tipeLokasi: 'TPS', alamat: 'Mangupura', gudangUtama: true, statusAktif: true, unitBisnisId: 1)
  ];

  @override
  Future<List<Sampah>> listSampahAktif() async => const [
    Sampah(sampahId: 1, kodeSampah: 'BTL-PET', namaSampah: 'Botol PET', kategoriId: 1, kodeSatuan: 'KG', hargaBeli: 3000, hargaJual: 3500, stockAkhir: 15.0, minStock: 5.0, aktif: true, unitBisnisId: 1, namaKategori: 'Anorganik')
  ];

  @override
  Future<List<Sampah>> listSampahMaster() async => const [
    Sampah(sampahId: 1, kodeSampah: 'BTL-PET', namaSampah: 'Botol PET', kategoriId: 1, kodeSatuan: 'KG', hargaBeli: 3000, hargaJual: 3500, stockAkhir: 15.0, minStock: 5.0, aktif: true, unitBisnisId: 1, namaKategori: 'Anorganik')
  ];

  @override
  Future<List<Kategori>> listKategoriAktif() async => const [
    Kategori(kategoriId: 1, kodeKategori: 'ANO', namaKategori: 'Anorganik')
  ];

  @override
  Future<List<Satuan>> listSatuan() async => const [
    Satuan(kodeSatuan: 'KG', namaSatuan: 'Kilogram')
  ];

  @override
  Future<List<Vendor>> listVendorAktif() async => const [
    Vendor(vendorId: 1, kodeVendor: 'VND-01', namaVendor: 'Pengepul Bali Bersih', statusAktif: true, unitBisnisId: 1, kodeKategori: 'PGPL', namaKategori: 'Pengepul', noTelepon: '081234')
  ];

  @override
  Future<List<Vendor>> listVendorMaster() async => const [
    Vendor(vendorId: 1, kodeVendor: 'VND-01', namaVendor: 'Pengepul Bali Bersih', statusAktif: true, unitBisnisId: 1, kodeKategori: 'PGPL', namaKategori: 'Pengepul', noTelepon: '081234')
  ];

  @override
  Future<List<KategoriVendor>> listKategoriVendor() async => const [
    KategoriVendor(kodeKategori: 'PGPL', kategoriName: 'Pengepul')
  ];

  @override
  Future<List<Setoran>> listSetoran({int? pegawaiId, int? lokasiId, int? limit, DateTime? from, DateTime? to}) async => const [];

  @override
  Future<List<Penjualan>> listPenjualan({DateTime? from, DateTime? to}) async => const [];

  @override
  Future<List<Penarikan>> listPenarikan({int? pegawaiId, String? status, DateTime? from, DateTime? to}) async => const [];

  @override
  Future<List<RingkasanPegawai>> getLaporanSaldoPegawai() async => const [];

  @override
  Future<List<ReportKartuGudang>> getReportKartuGudang({required int lokasiId, required int sampahId, DateTime? from, DateTime? to}) async => const [];

  @override
  Future<List<ReportSelisihRealisasi>> getReportSelisihRealisasi(int pegawaiId) async => const [];

  @override
  Future<UnitBisnis?> getUnitBisnis(int unitBisnisId) async => const
    UnitBisnis(unitBisnisId: 1, unitBisnisName: 'Badan Kepegawaian dan Pengembangan SDM', kodeOpd: 'BKPSDM', tipeOpd: 'BADAN', warnaPrimary: '#2E7D32', statusAktif: true);

  @override
  Future<List<UnitBisnis>> listUnitBisnis() async => const [
    UnitBisnis(unitBisnisId: 1, unitBisnisName: 'Badan Kepegawaian dan Pengembangan SDM', kodeOpd: 'BKPSDM', tipeOpd: 'BADAN', warnaPrimary: '#2E7D32', statusAktif: true)
  ];

  @override
  Future<Map<String, dynamic>> bulkImportPegawai({required int unitBisnisId, required List<Map<String, dynamic>> pegawaiList}) async =>
    {'ok': true, 'imported_count': pegawaiList.length};

  @override
  Future<void> logError({required String errorMessage, String? stackTrace, String? deviceInfo}) async {}
}

class _MockSupabaseClient extends SupabaseClient {
  _MockSupabaseClient() : super('https://jtxquskrulvjafrusbcq.supabase.co', 'dummy_key');
}

