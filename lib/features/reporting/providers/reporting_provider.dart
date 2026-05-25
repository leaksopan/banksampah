import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/bank_sampah_models.dart';
import '../../../data/repositories/bank_sampah_repository.dart';
import '../../auth/providers/auth_state_provider.dart';
import '../../penarikan/providers/penarikan_provider.dart';

final currentUnitBisnisProvider = FutureProvider<UnitBisnis?>((ref) async {
  final appUser = await ref.watch(appUserProvider.future);
  if (appUser == null) return null;
  final primaryUnitId = appUser.primaryUnitBisnisId;
  if (primaryUnitId == null) return null;

  final repo = ref.watch(bankSampahRepositoryProvider);
  return repo.getUnitBisnis(primaryUnitId);
});

final stockCurrentProvider = FutureProvider.autoDispose<List<StockCurrent>>((ref) async {
  final repo = ref.watch(bankSampahRepositoryProvider);
  return repo.listStockCurrent();
});

final ringkasanPegawaiProvider = FutureProvider.autoDispose<List<RingkasanPegawai>>((ref) async {
  final repo = ref.watch(bankSampahRepositoryProvider);
  return repo.listRingkasanPegawai();
});

class KartuGudangParams {
  const KartuGudangParams({
    required this.lokasiId,
    required this.sampahId,
    this.from,
    this.to,
  });

  final int lokasiId;
  final int sampahId;
  final DateTime? from;
  final DateTime? to;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KartuGudangParams &&
          runtimeType == other.runtimeType &&
          lokasiId == other.lokasiId &&
          sampahId == other.sampahId &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => lokasiId.hashCode ^ sampahId.hashCode ^ from.hashCode ^ to.hashCode;
}

final reportKartuGudangProvider = FutureProvider.autoDispose
    .family<List<ReportKartuGudang>, KartuGudangParams>((ref, params) async {
  final repo = ref.watch(bankSampahRepositoryProvider);
  return repo.getReportKartuGudang(
    lokasiId: params.lokasiId,
    sampahId: params.sampahId,
    from: params.from,
    to: params.to,
  );
});

final reportSelisihRealisasiProvider = FutureProvider.autoDispose
    .family<List<ReportSelisihRealisasi>, int>((ref, pegawaiId) async {
  final repo = ref.watch(bankSampahRepositoryProvider);
  return repo.getReportSelisihRealisasi(pegawaiId);
});

final currentPegawaiReportSelisihProvider = FutureProvider.autoDispose<List<ReportSelisihRealisasi>>((ref) async {
  final pegawai = await ref.watch(currentPegawaiProvider.future);
  if (pegawai == null) return [];
  final repo = ref.watch(bankSampahRepositoryProvider);
  return repo.getReportSelisihRealisasi(pegawai.pegawaiId);
});

final coaListProvider = FutureProvider.autoDispose<List<COA>>((ref) async {
  final repo = ref.watch(bankSampahRepositoryProvider);
  return repo.listCOA();
});

final reportNeracaProvider = FutureProvider.autoDispose
    .family<List<ReportNeracaItem>, DateTime?>((ref, asOfDate) async {
  final repo = ref.watch(bankSampahRepositoryProvider);
  final unitBisnis = await ref.watch(currentUnitBisnisProvider.future);
  if (unitBisnis == null) return [];
  return repo.getReportNeraca(unitBisnisId: unitBisnis.unitBisnisId, asOfDate: asOfDate);
});

class HppLabaRugiParams {
  const HppLabaRugiParams({this.from, this.to});

  final DateTime? from;
  final DateTime? to;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HppLabaRugiParams &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => from.hashCode ^ to.hashCode;
}

final reportHppLabaRugiProvider = FutureProvider.autoDispose
    .family<ReportHppLabaRugi, HppLabaRugiParams>((ref, params) async {
  final repo = ref.watch(bankSampahRepositoryProvider);
  final unitBisnis = await ref.watch(currentUnitBisnisProvider.future);
  if (unitBisnis == null) {
    throw Exception('OPD / Unit Bisnis tidak ditemukan');
  }
  return repo.getReportHppLabaRugi(
    unitBisnisId: unitBisnis.unitBisnisId,
    from: params.from,
    to: params.to,
  );
});

