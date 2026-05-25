import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/bank_sampah_models.dart';
import '../../../data/repositories/bank_sampah_repository.dart';
import '../../auth/providers/auth_state_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';

final penarikanListProvider = FutureProvider.autoDispose<List<Penarikan>>((ref) async {
  final appUser = await ref.watch(appUserProvider.future);
  if (appUser == null) return [];

  final repo = ref.watch(bankSampahRepositoryProvider);

  if (appUser.isAdmin) {
    return repo.listPenarikan();
  } else {
    final pegawai = await repo.getPegawaiByUserId(appUser.userId);
    if (pegawai == null) return [];
    return repo.listPenarikan(pegawaiId: pegawai.pegawaiId);
  }
});

final penarikanDetailProvider = FutureProvider.autoDispose.family<Penarikan?, String>((ref, noBukti) async {
  final repo = ref.watch(bankSampahRepositoryProvider);
  return repo.getPenarikan(noBukti);
});

final currentPegawaiProvider = FutureProvider.autoDispose<Pegawai?>((ref) async {
  final appUser = await ref.watch(appUserProvider.future);
  if (appUser == null) return null;
  final repo = ref.watch(bankSampahRepositoryProvider);
  return repo.getPegawaiByUserId(appUser.userId);
});

final currentPegawaiSaldoProvider = FutureProvider.autoDispose<SaldoPegawai?>((ref) async {
  final pegawai = await ref.watch(currentPegawaiProvider.future);
  if (pegawai == null) return null;
  final repo = ref.watch(bankSampahRepositoryProvider);
  return repo.getSaldoPegawai(pegawai.pegawaiId);
});

class PenarikanController {
  PenarikanController(this._ref);

  final Ref _ref;

  Future<void> create({
    required int pegawaiId,
    required num jumlah,
    required String typePembayaran,
    String? noRek,
    String? bank,
    String? atasNama,
    String? keterangan,
  }) async {
    final repo = _ref.read(bankSampahRepositoryProvider);
    await repo.createPenarikan(
      pegawaiId: pegawaiId,
      jumlah: jumlah,
      typePembayaran: typePembayaran,
      noRek: noRek,
      bank: bank,
      atasNama: atasNama,
      keterangan: keterangan,
    );
    _ref.invalidate(penarikanListProvider);
    _ref.invalidate(nasabahDashboardProvider);
  }

  Future<void> approve({
    required String noBukti,
    required bool approve,
    String? keterangan,
  }) async {
    final repo = _ref.read(bankSampahRepositoryProvider);
    await repo.approvePenarikan(
      noBukti: noBukti,
      approve: approve,
      keterangan: keterangan,
    );
    _ref.invalidate(penarikanListProvider);
    _ref.invalidate(penarikanDetailProvider(noBukti));
    _ref.invalidate(adminDashboardProvider);
  }

  Future<void> pay({
    required String noBukti,
    String? buktiTransferUrl,
    String? keterangan,
  }) async {
    final repo = _ref.read(bankSampahRepositoryProvider);
    await repo.payPenarikan(
      noBukti: noBukti,
      buktiTransferUrl: buktiTransferUrl,
      keterangan: keterangan,
    );
    _ref.invalidate(penarikanListProvider);
    _ref.invalidate(penarikanDetailProvider(noBukti));
    _ref.invalidate(adminDashboardProvider);
  }
}

final penarikanControllerProvider = Provider<PenarikanController>((ref) {
  return PenarikanController(ref);
});
