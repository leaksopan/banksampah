import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/bank_sampah_models.dart';
import '../../../data/repositories/bank_sampah_repository.dart';
import '../../auth/providers/auth_state_provider.dart';

final adminDashboardProvider = FutureProvider.autoDispose<AdminDashboardData>((
  ref,
) async {
  final repo = ref.watch(bankSampahRepositoryProvider);
  final today = AppFormatters.startOfDay(DateTime.now());
  final results = await Future.wait<dynamic>([
    repo.listSetoran(from: today, to: AppFormatters.nextDay(today)),
    repo.countPendingUsers(),
  ]);

  final setoranHariIni = results[0] as List<Setoran>;
  return AdminDashboardData(
    jumlahSetoranHariIni: setoranHariIni.length,
    totalBeratHariIni: setoranHariIni.fold<num>(
      0,
      (total, item) => total + item.totalBerat,
    ),
    pendingApproval: results[1] as int,
  );
});

final nasabahDashboardProvider =
    FutureProvider.autoDispose<NasabahDashboardData>((ref) async {
      final appUser = await ref.watch(appUserProvider.future);
      if (appUser == null) {
        throw StateError('Profil user belum tersedia.');
      }

      final repo = ref.watch(bankSampahRepositoryProvider);
      final pegawai = await repo.getPegawaiByUserId(appUser.userId);
      if (pegawai == null) {
        throw StateError('Profil pegawai belum tersedia.');
      }

      final results = await Future.wait<dynamic>([
        repo.getSaldoPegawai(pegawai.pegawaiId),
        repo.listMutasiPegawai(pegawai.pegawaiId),
        repo.listSetoran(pegawaiId: pegawai.pegawaiId, limit: 5),
      ]);

      return NasabahDashboardData(
        pegawai: pegawai,
        saldo: results[0] as SaldoPegawai,
        mutasiTerakhir: results[1] as List<MutasiSaldo>,
        setoranTerakhir: results[2] as List<Setoran>,
      );
    });

class AdminDashboardData {
  const AdminDashboardData({
    required this.jumlahSetoranHariIni,
    required this.totalBeratHariIni,
    required this.pendingApproval,
  });

  final int jumlahSetoranHariIni;
  final num totalBeratHariIni;
  final int pendingApproval;
}

class NasabahDashboardData {
  const NasabahDashboardData({
    required this.pegawai,
    required this.saldo,
    required this.mutasiTerakhir,
    required this.setoranTerakhir,
  });

  final Pegawai pegawai;
  final SaldoPegawai saldo;
  final List<MutasiSaldo> mutasiTerakhir;
  final List<Setoran> setoranTerakhir;
}
