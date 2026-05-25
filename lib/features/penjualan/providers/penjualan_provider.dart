import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/bank_sampah_models.dart';
import '../../../data/repositories/bank_sampah_repository.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../setoran/providers/setoran_provider.dart';

final penjualanFilterDateProvider = StateProvider<DateTime>((ref) {
  return AppFormatters.startOfDay(DateTime.now());
});

final penjualanListProvider = FutureProvider.autoDispose<List<Penjualan>>((
  ref,
) async {
  final date = ref.watch(penjualanFilterDateProvider);
  final repo = ref.watch(bankSampahRepositoryProvider);
  return repo.listPenjualan(
    from: AppFormatters.startOfDay(date),
    to: AppFormatters.nextDay(date),
  );
});

final penjualanLookupsProvider = FutureProvider.autoDispose<PenjualanLookups>((
  ref,
) async {
  final repo = ref.watch(bankSampahRepositoryProvider);
  final results = await Future.wait<dynamic>([
    repo.listVendorAktif(),
    repo.listLokasiAktif(),
    repo.listSampahAktif(),
  ]);

  return PenjualanLookups(
    vendor: results[0] as List<Vendor>,
    lokasi: results[1] as List<Lokasi>,
    sampah: results[2] as List<Sampah>,
  );
});

final penjualanDetailProvider = FutureProvider.autoDispose
    .family<PenjualanDetailData, String>((ref, noBukti) async {
      final repo = ref.watch(bankSampahRepositoryProvider);
      final results = await Future.wait<dynamic>([
        repo.getPenjualan(noBukti),
        repo.listPenjualanDetail(noBukti),
      ]);

      final penjualan = results[0] as Penjualan?;
      if (penjualan == null) {
        throw StateError('Penjualan tidak ditemukan.');
      }

      return PenjualanDetailData(
        penjualan: penjualan,
        details: results[1] as List<PenjualanDetail>,
      );
    });

final createPenjualanControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      CreatePenjualanController,
      CreatedPenjualan?
    >(CreatePenjualanController.new);

class CreatePenjualanController
    extends AutoDisposeAsyncNotifier<CreatedPenjualan?> {
  @override
  Future<CreatedPenjualan?> build() async => null;

  Future<CreatedPenjualan?> submit({
    required int vendorId,
    required int lokasiId,
    required String typePembayaran,
    required List<PenjualanInputDetail> details,
    String? keterangan,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final payload =
          details
              .map(
                (detail) => <String, dynamic>{
                  'Sampah_ID': detail.sampahId,
                  'Qty': detail.qty,
                  'Harga_Jual': detail.hargaJual,
                },
              )
              .toList(growable: false);

      return ref.read(bankSampahRepositoryProvider).createPenjualan(
        vendorId: vendorId,
        lokasiId: lokasiId,
        typePembayaran: typePembayaran,
        details: payload,
        keterangan: keterangan,
      );
    });

    state = result;
    if (result.hasValue) {
      final created = result.valueOrNull;
      ref.invalidate(penjualanListProvider);
      ref.invalidate(penjualanLookupsProvider);
      ref.invalidate(setoranListProvider);
      ref.invalidate(setoranLookupsProvider);
      ref.invalidate(adminDashboardProvider);
      ref.invalidate(nasabahDashboardProvider);
      if (created != null) {
        ref.invalidate(penjualanDetailProvider(created.noBukti));
      }
    }

    return result.valueOrNull;
  }
}

class PenjualanLookups {
  const PenjualanLookups({
    required this.vendor,
    required this.lokasi,
    required this.sampah,
  });

  final List<Vendor> vendor;
  final List<Lokasi> lokasi;
  final List<Sampah> sampah;

  bool get isReady =>
      vendor.isNotEmpty && lokasi.isNotEmpty && sampah.isNotEmpty;
}

class PenjualanInputDetail {
  const PenjualanInputDetail({
    required this.sampahId,
    required this.qty,
    required this.hargaJual,
  });

  final int sampahId;
  final num qty;
  final num hargaJual;
}

class PenjualanDetailData {
  const PenjualanDetailData({
    required this.penjualan,
    required this.details,
  });

  final Penjualan penjualan;
  final List<PenjualanDetail> details;
}
