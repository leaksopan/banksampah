import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/bank_sampah_models.dart';
import '../../../data/repositories/bank_sampah_repository.dart';
import '../../auth/providers/auth_state_provider.dart';
import '../../setoran/providers/setoran_provider.dart';

final masterPegawaiProvider = FutureProvider.autoDispose<List<Pegawai>>((
  ref,
) async {
  final appUser = await ref.watch(appUserProvider.future);
  return ref
      .watch(bankSampahRepositoryProvider)
      .listPegawaiMaster(unitBisnisId: appUser?.primaryUnitBisnisId);
});

final masterLokasiProvider = FutureProvider.autoDispose<List<Lokasi>>((
  ref,
) async {
  return ref.watch(bankSampahRepositoryProvider).listLokasiMaster();
});

final masterSampahProvider = FutureProvider.autoDispose<List<Sampah>>((
  ref,
) async {
  return ref.watch(bankSampahRepositoryProvider).listSampahMaster();
});

final masterKategoriProvider = FutureProvider.autoDispose<List<Kategori>>((
  ref,
) async {
  return ref.watch(bankSampahRepositoryProvider).listKategoriAktif();
});

final masterSatuanProvider = FutureProvider.autoDispose<List<Satuan>>((
  ref,
) async {
  return ref.watch(bankSampahRepositoryProvider).listSatuan();
});

final masterKategoriVendorProvider =
    FutureProvider.autoDispose<List<KategoriVendor>>((ref) async {
      return ref.watch(bankSampahRepositoryProvider).listKategoriVendor();
    });

final masterVendorProvider = FutureProvider.autoDispose<List<Vendor>>((
  ref,
) async {
  return ref.watch(bankSampahRepositoryProvider).listVendorMaster();
});

final masterUnitBisnisProvider = FutureProvider.autoDispose<List<UnitBisnis>>((
  ref,
) async {
  return ref.watch(bankSampahRepositoryProvider).listUnitBisnis();
});

final saveMasterControllerProvider =
    AutoDisposeAsyncNotifierProvider<SaveMasterController, void>(
      SaveMasterController.new,
    );

class SaveMasterController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> savePegawai({
    required int pegawaiId,
    required String namaPegawai,
    required String nip,
    required String noTelepon,
    required String email,
    required bool statusAktif,
  }) async {
    final appUser = await ref.read(appUserProvider.future);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(bankSampahRepositoryProvider).updatePegawai(
            pegawaiId: pegawaiId,
            namaPegawai: namaPegawai,
            nip: nip,
            noTelepon: noTelepon,
            email: email,
            statusAktif: statusAktif,
            userUpdate: appUser?.userId,
          );
    });
    state = result;
    if (!result.hasError) {
      ref.invalidate(masterPegawaiProvider);
      ref.invalidate(setoranLookupsProvider);
    }
    return !result.hasError;
  }

  Future<bool> saveLokasi({
    int? lokasiId,
    required String kodeLokasi,
    required String namaLokasi,
    required String tipeLokasi,
    required String alamat,
    required bool gudangUtama,
    required bool statusAktif,
  }) async {
    final appUser = await ref.read(appUserProvider.future);
    final unitBisnisId = appUser?.primaryUnitBisnisId;
    if (unitBisnisId == null) {
      state = AsyncError(
        StateError('Unit bisnis user belum tersedia.'),
        StackTrace.current,
      );
      return false;
    }

    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(bankSampahRepositoryProvider).upsertLokasi(
            lokasiId: lokasiId,
            unitBisnisId: unitBisnisId,
            kodeLokasi: kodeLokasi,
            namaLokasi: namaLokasi,
            tipeLokasi: tipeLokasi,
            alamat: alamat,
            gudangUtama: gudangUtama,
            statusAktif: statusAktif,
          );
    });
    state = result;
    if (!result.hasError) {
      ref.invalidate(masterLokasiProvider);
      ref.invalidate(setoranLookupsProvider);
    }
    return !result.hasError;
  }

  Future<bool> saveSampah({
    int? sampahId,
    required String kodeSampah,
    required String namaSampah,
    required int kategoriId,
    required String kodeSatuan,
    required num hargaBeli,
    required num hargaJual,
    required num minStock,
    required bool aktif,
    required num persenInsentif,
  }) async {
    final appUser = await ref.read(appUserProvider.future);
    final unitBisnisId = appUser?.primaryUnitBisnisId;
    if (unitBisnisId == null) {
      state = AsyncError(
        StateError('Unit bisnis user belum tersedia.'),
        StackTrace.current,
      );
      return false;
    }

    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(bankSampahRepositoryProvider).upsertSampah(
            sampahId: sampahId,
            unitBisnisId: unitBisnisId,
            kodeSampah: kodeSampah,
            namaSampah: namaSampah,
            kategoriId: kategoriId,
            kodeSatuan: kodeSatuan,
            hargaBeli: hargaBeli,
            hargaJual: hargaJual,
            minStock: minStock,
            aktif: aktif,
            persenInsentif: persenInsentif,
            userUpdate: appUser?.userId,
          );
    });
    state = result;
    if (!result.hasError) {
      ref.invalidate(masterSampahProvider);
      ref.invalidate(setoranLookupsProvider);
    }
    return !result.hasError;
  }

  Future<bool> saveVendor({
    int? vendorId,
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
    final appUser = await ref.read(appUserProvider.future);
    final unitBisnisId = appUser?.primaryUnitBisnisId;
    if (unitBisnisId == null) {
      state = AsyncError(
        StateError('Unit bisnis user belum tersedia.'),
        StackTrace.current,
      );
      return false;
    }

    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(bankSampahRepositoryProvider).upsertVendor(
            vendorId: vendorId,
            unitBisnisId: unitBisnisId,
            kodeVendor: kodeVendor,
            namaVendor: namaVendor,
            kodeKategori: kodeKategori,
            alamat: alamat,
            noTelepon: noTelepon,
            alamatEmail: alamatEmail,
            noNpwp: noNpwp,
            atasNama: atasNama,
            bank: bank,
            noRek: noRek,
            statusAktif: statusAktif,
          );
    });
    state = result;
    if (!result.hasError) {
      ref.invalidate(masterVendorProvider);
    }
    return !result.hasError;
  }

  Future<Map<String, dynamic>?> bulkImportPegawai({
    required int unitBisnisId,
    required List<Map<String, dynamic>> pegawaiList,
  }) async {
    state = const AsyncLoading();
    Map<String, dynamic>? response;
    final result = await AsyncValue.guard(() async {
      response = await ref.read(bankSampahRepositoryProvider).bulkImportPegawai(
            unitBisnisId: unitBisnisId,
            pegawaiList: pegawaiList,
          );
    });
    state = result;
    if (!result.hasError) {
      ref.invalidate(masterPegawaiProvider);
    }
    return response;
  }
}
