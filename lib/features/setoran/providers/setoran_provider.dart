import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/bank_sampah_models.dart';
import '../../../data/repositories/bank_sampah_repository.dart';
import '../../dashboard/providers/dashboard_provider.dart';

final setoranFilterDateProvider = StateProvider<DateTime>((ref) {
  return AppFormatters.startOfDay(DateTime.now());
});

final setoranFilterPegawaiIdProvider = StateProvider<int?>((ref) => null);
final setoranFilterLokasiIdProvider = StateProvider<int?>((ref) => null);

final setoranListProvider = FutureProvider.autoDispose<List<Setoran>>((
  ref,
) async {
  final date = ref.watch(setoranFilterDateProvider);
  final pegawaiId = ref.watch(setoranFilterPegawaiIdProvider);
  final lokasiId = ref.watch(setoranFilterLokasiIdProvider);
  final repo = ref.watch(bankSampahRepositoryProvider);
  return repo.listSetoran(
    from: AppFormatters.startOfDay(date),
    to: AppFormatters.nextDay(date),
    pegawaiId: pegawaiId,
    lokasiId: lokasiId,
  );
});

final setoranLookupsProvider = FutureProvider.autoDispose<SetoranLookups>((
  ref,
) async {
  final repo = ref.watch(bankSampahRepositoryProvider);
  final results = await Future.wait<dynamic>([
    repo.listPegawaiAktif(),
    repo.listLokasiAktif(),
    repo.listSampahAktif(),
  ]);

  return SetoranLookups(
    pegawai: results[0] as List<Pegawai>,
    lokasi: results[1] as List<Lokasi>,
    sampah: results[2] as List<Sampah>,
  );
});

final setoranDetailProvider = FutureProvider.autoDispose
    .family<SetoranDetailData, String>((ref, noBukti) async {
      final repo = ref.watch(bankSampahRepositoryProvider);
      final results = await Future.wait<dynamic>([
        repo.getSetoran(noBukti),
        repo.listSetoranDetail(noBukti),
      ]);

      final setoran = results[0] as Setoran?;
      if (setoran == null) {
        throw StateError('Setoran tidak ditemukan.');
      }

      return SetoranDetailData(
        setoran: setoran,
        details: results[1] as List<SetoranDetail>,
      );
    });

final createSetoranControllerProvider =
    AutoDisposeAsyncNotifierProvider<CreateSetoranController, CreatedSetoran?>(
      CreateSetoranController.new,
    );

final voidSetoranControllerProvider =
    AutoDisposeAsyncNotifierProvider<VoidSetoranController, CreatedSetoran?>(
      VoidSetoranController.new,
    );

class CreateSetoranController
    extends AutoDisposeAsyncNotifier<CreatedSetoran?> {
  @override
  Future<CreatedSetoran?> build() async => null;

  Future<CreatedSetoran?> submit({
    required int pegawaiId,
    required int lokasiId,
    required List<SetoranInputDetail> details,
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
                },
              )
              .toList(growable: false);

      return ref.read(bankSampahRepositoryProvider).createSetoran(
        pegawaiId: pegawaiId,
        lokasiId: lokasiId,
        details: payload,
        keterangan: keterangan,
      );
    });

    state = result;
    if (result.hasValue) {
      final created = result.valueOrNull;
      ref.invalidate(setoranListProvider);
      if (created != null) {
        ref.invalidate(setoranDetailProvider(created.noBukti));
      }
      ref.invalidate(adminDashboardProvider);
      ref.invalidate(nasabahDashboardProvider);
    }

    return result.valueOrNull;
  }
}

class VoidSetoranController extends AutoDisposeAsyncNotifier<CreatedSetoran?> {
  @override
  Future<CreatedSetoran?> build() async => null;

  Future<CreatedSetoran?> submit({
    required String noBukti,
    String? keterangan,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      return ref.read(bankSampahRepositoryProvider).voidSetoran(
        noBukti: noBukti,
        keterangan: keterangan,
      );
    });

    state = result;
    if (result.hasValue) {
      ref.invalidate(setoranListProvider);
      ref.invalidate(setoranDetailProvider(noBukti));
      ref.invalidate(adminDashboardProvider);
      ref.invalidate(nasabahDashboardProvider);
    }

    return result.valueOrNull;
  }
}

class SetoranLookups {
  const SetoranLookups({
    required this.pegawai,
    required this.lokasi,
    required this.sampah,
  });

  final List<Pegawai> pegawai;
  final List<Lokasi> lokasi;
  final List<Sampah> sampah;

  bool get isReady =>
      pegawai.isNotEmpty && lokasi.isNotEmpty && sampah.isNotEmpty;
}

class SetoranInputDetail {
  const SetoranInputDetail({
    required this.sampahId,
    required this.qty,
  });

  final int sampahId;
  final num qty;
}

class SetoranDetailData {
  const SetoranDetailData({
    required this.setoran,
    required this.details,
  });

  final Setoran setoran;
  final List<SetoranDetail> details;
}
