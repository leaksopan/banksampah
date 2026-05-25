import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/env.dart';
import '../core/constants/role.dart';
import '../features/approval/presentation/approval_detail_screen.dart';
import '../features/approval/presentation/approval_list_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/pending_screen.dart';
import '../features/auth/providers/auth_state_provider.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/master/presentation/master_screen.dart';
import '../features/penjualan/presentation/penjualan_detail_screen.dart';
import '../features/penjualan/presentation/penjualan_form_screen.dart';
import '../features/penjualan/presentation/penjualan_list_screen.dart';
import '../features/penarikan/presentation/penarikan_detail_screen.dart';
import '../features/penarikan/presentation/penarikan_form_screen.dart';
import '../features/penarikan/presentation/penarikan_list_screen.dart';
import '../features/penarikan/presentation/transfer_saldo_screen.dart';
import '../features/reporting/presentation/reporting_screen.dart';
import '../features/reporting/presentation/kartu_gudang_report_screen.dart';
import '../features/reporting/presentation/saldo_pegawai_report_screen.dart';
import '../features/reporting/presentation/selisih_realisasi_report_screen.dart';
import '../features/reporting/presentation/neraca_report_screen.dart';
import '../features/reporting/presentation/hpp_report_screen.dart';
import '../features/reporting/presentation/coa_list_screen.dart';
import '../features/setoran/presentation/setoran_detail_screen.dart';
import '../features/setoran/presentation/setoran_form_screen.dart';
import '../features/setoran/presentation/setoran_list_screen.dart';
import '../features/setoran/presentation/setoran_print_screen.dart';
import '../shared/layouts/main_layout.dart';
import 'route_paths.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: RoutePaths.dashboard,
    refreshListenable: refreshListenable,
    routes: [
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.pending,
        builder: (context, state) => const PendingScreen(),
      ),
      GoRoute(
        path: '${RoutePaths.setoranPrintBase}/:noBukti',
        builder: (context, state) {
          final noBukti = state.pathParameters['noBukti'];
          if (noBukti == null || noBukti.isEmpty) {
            return const _InvalidSetoranScreen();
          }

          return SetoranPrintScreen(
            noBukti: Uri.decodeComponent(noBukti),
          );
        },
      ),
      ShellRoute(
        builder:
            (context, state, child) =>
                MainLayout(child: child, currentLocation: state.matchedLocation),
        routes: [
          GoRoute(
            path: RoutePaths.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: RoutePaths.approval,
            builder: (context, state) => const ApprovalListScreen(),
          ),
          GoRoute(
            path: RoutePaths.master,
            builder: (context, state) => const MasterScreen(),
          ),
          GoRoute(
            path: RoutePaths.setoran,
            builder: (context, state) => const SetoranListScreen(),
          ),
          GoRoute(
            path: RoutePaths.setoranNew,
            builder: (context, state) => const SetoranFormScreen(),
          ),
          GoRoute(
            path: RoutePaths.penjualan,
            builder: (context, state) => const PenjualanListScreen(),
          ),
          GoRoute(
            path: RoutePaths.penjualanNew,
            builder: (context, state) => const PenjualanFormScreen(),
          ),
          GoRoute(
            path: '${RoutePaths.penjualanDetailBase}/:noBukti',
            builder: (context, state) {
              final noBukti = state.pathParameters['noBukti'];
              if (noBukti == null || noBukti.isEmpty) {
                return const _InvalidPenjualanScreen();
              }

              return PenjualanDetailScreen(
                noBukti: Uri.decodeComponent(noBukti),
              );
            },
          ),
          GoRoute(
            path: '${RoutePaths.setoranDetailBase}/:noBukti',
            builder: (context, state) {
              final noBukti = state.pathParameters['noBukti'];
              if (noBukti == null || noBukti.isEmpty) {
                return const _InvalidSetoranScreen();
              }

              return SetoranDetailScreen(
                noBukti: Uri.decodeComponent(noBukti),
              );
            },
          ),
          GoRoute(
            path: RoutePaths.penarikan,
            builder: (context, state) => const PenarikanListScreen(),
          ),
          GoRoute(
            path: RoutePaths.penarikanNew,
            builder: (context, state) => const PenarikanFormScreen(),
          ),
          GoRoute(
            path: '${RoutePaths.penarikanDetailBase}/:noBukti',
            builder: (context, state) {
              final noBukti = state.pathParameters['noBukti'];
              if (noBukti == null || noBukti.isEmpty) {
                return const _InvalidPenarikanScreen();
              }

              return PenarikanDetailScreen(
                noBukti: Uri.decodeComponent(noBukti),
              );
            },
          ),
          GoRoute(
            path: RoutePaths.transferSaldo,
            builder: (context, state) => const TransferSaldoScreen(),
          ),
          GoRoute(
            path: RoutePaths.reporting,
            builder: (context, state) => const ReportingScreen(),
          ),
          GoRoute(
            path: RoutePaths.reportKartuGudang,
            builder: (context, state) => const KartuGudangReportScreen(),
          ),
          GoRoute(
            path: RoutePaths.reportSaldoPegawai,
            builder: (context, state) => const SaldoPegawaiReportScreen(),
          ),
          GoRoute(
            path: RoutePaths.reportSelisihRealisasi,
            builder: (context, state) => const SelisihRealisasiReportScreen(),
          ),
          GoRoute(
            path: RoutePaths.reportNeraca,
            builder: (context, state) => const NeracaReportScreen(),
          ),
          GoRoute(
            path: RoutePaths.reportHppLabaRugi,
            builder: (context, state) => const HppReportScreen(),
          ),
          GoRoute(
            path: RoutePaths.reportCoaList,
            builder: (context, state) => const CoaListScreen(),
          ),
          GoRoute(
            path: '${RoutePaths.approvalDetailBase}/:userId',
            builder: (context, state) {
              final userIdRaw = state.pathParameters['userId'];
              final userId = int.tryParse(userIdRaw ?? '');
              if (userId == null) {
                return const _InvalidApprovalScreen();
              }

              return ApprovalDetailScreen(userId: userId);
            },
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      if (Uri.base.toString().contains('bypass_auth=true')) {
        return null;
      }

      if (!Env.hasSupabaseConfig) {
        return state.matchedLocation == RoutePaths.login
            ? null
            : RoutePaths.login;
      }

      final profile = ref.read(appUserProvider);
      final authUser = ref.read(supabaseClientProvider).auth.currentUser;
      final isLogin = state.matchedLocation == RoutePaths.login;
      final isPending = state.matchedLocation == RoutePaths.pending;
      final isApprovalRoute = state.matchedLocation.startsWith(
        RoutePaths.approval,
      );
      final isSetoranRoute = state.matchedLocation.startsWith(
        RoutePaths.setoran,
      );
      final isPenjualanRoute = state.matchedLocation.startsWith(
        RoutePaths.penjualan,
      );
      final isMasterRoute = state.matchedLocation.startsWith(
        RoutePaths.master,
      );
      final isReportingRoute = state.matchedLocation.startsWith(
        RoutePaths.reporting,
      );
      final isRestrictedReporting = isReportingRoute && !state.matchedLocation.startsWith(
        RoutePaths.reportSelisihRealisasi,
      );

      if (authUser == null) {
        return isLogin ? null : RoutePaths.login;
      }

      if (profile.isLoading) {
        return null;
      }

      final appUser = profile.valueOrNull;
      final isApproved = appUser?.isApproved ?? false;
      final isAdmin = appUser?.roles.contains(AppRole.admin) ?? false;

      if (!isApproved) {
        return isPending ? null : RoutePaths.pending;
      }

      if ((isApprovalRoute || isSetoranRoute || isPenjualanRoute || isMasterRoute || isRestrictedReporting) &&
          !isAdmin) {
        return RoutePaths.dashboard;
      }

      if (isLogin || isPending) {
        return RoutePaths.dashboard;
      }

      return null;
    },
  );
});

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this._ref) {
    _subscriptions = [
      _ref.listen(authStateChangesProvider, (_, __) => notifyListeners()),
      _ref.listen(appUserProvider, (_, __) => notifyListeners()),
    ];
  }

  final Ref _ref;
  late final List<ProviderSubscription<dynamic>> _subscriptions;

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.close();
    }
    super.dispose();
  }
}

class _InvalidApprovalScreen extends StatelessWidget {
  const _InvalidApprovalScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('User approval tidak valid.'),
      ),
    );
  }
}

class _InvalidSetoranScreen extends StatelessWidget {
  const _InvalidSetoranScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Setoran tidak valid.'),
      ),
    );
  }
}

class _InvalidPenjualanScreen extends StatelessWidget {
  const _InvalidPenjualanScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Penjualan tidak valid.'),
      ),
    );
  }
}

class _InvalidPenarikanScreen extends StatelessWidget {
  const _InvalidPenarikanScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Penarikan tidak valid.'),
      ),
    );
  }
}
