import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/bank_sampah_models.dart';
import '../../../routing/route_paths.dart';
import '../../auth/providers/auth_state_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).valueOrNull;
    final colorScheme = Theme.of(context).colorScheme;
    final isAdmin = user?.isAdmin ?? false;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF23A8F2), Color(0xFF64DFA5)],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.recycling_rounded,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user == null
                            ? 'Bank Sampah Pemda'
                            : 'Halo, ${user.namaAsli}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user == null
                            ? 'Memuat profil...'
                            : user.isAdmin
                            ? 'Admin BKPSDM'
                            : 'Nasabah BKPSDM',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  child: Icon(
                    Icons.person_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: isAdmin ? Icons.add_rounded : Icons.swap_horiz_rounded,
                  label: isAdmin ? 'Setoran' : 'Transfer',
                  color: colorScheme.primary,
                  onTap: isAdmin ? () => context.go(RoutePaths.setoran) : () => context.go(RoutePaths.transferSaldo),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickAction(
                  icon:
                      isAdmin
                          ? Icons.local_shipping_rounded
                          : Icons.account_balance_wallet_rounded,
                  label: isAdmin ? 'Jual' : 'Saldo',
                  color: const Color(0xFF00A6D6),
                  onTap:
                      isAdmin ? () => context.go(RoutePaths.penjualan) : () => context.go(RoutePaths.penarikan),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickAction(
                  icon: Icons.receipt_long_rounded,
                  label: isAdmin ? 'Approval' : 'Riwayat',
                  color: const Color(0xFF55CFA1),
                  onTap:
                      isAdmin ? () => context.go(RoutePaths.approval) : () => context.go(RoutePaths.penarikan),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickAction(
                  icon: Icons.analytics_rounded,
                  label: 'Laporan',
                  color: const Color(0xFFEF6C00),
                  onTap:
                      isAdmin ? () => context.go(RoutePaths.reporting) : () => context.go(RoutePaths.reportSelisihRealisasi),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Dashboard',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (isAdmin)
            ref
                .watch(adminDashboardProvider)
                .when(
                  data: (data) => _AdminDashboardCards(data: data),
                  error:
                      (error, _) => _DashboardError(message: error.toString()),
                  loading: () => const _DashboardLoading(),
                )
          else
            ref
                .watch(nasabahDashboardProvider)
                .when(
                  data: (data) => _NasabahDashboardCards(data: data),
                  error:
                      (error, _) => _DashboardError(message: error.toString()),
                  loading: () => const _DashboardLoading(),
                ),
        ],
      ),
    );
  }
}

class _AdminDashboardCards extends StatelessWidget {
  const _AdminDashboardCards({required this.data});

  final AdminDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.receipt_long_rounded,
                label: 'Setoran hari ini',
                value: data.jumlahSetoranHariIni.toString(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Icons.scale_rounded,
                label: 'Berat hari ini',
                value: AppFormatters.kg(data.totalBeratHariIni),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _MetricCard(
          icon: Icons.fact_check_rounded,
          label: 'User pending approval',
          value: data.pendingApproval.toString(),
          wide: true,
        ),
      ],
    );
  }
}

class _NasabahDashboardCards extends StatelessWidget {
  const _NasabahDashboardCards({required this.data});

  final NasabahDashboardData data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.hourglass_top_rounded,
                label: 'Pending',
                value: AppFormatters.rupiah(data.saldo.saldoPending),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Tersedia',
                value: AppFormatters.rupiah(data.saldo.saldoTersedia),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _MetricCard(
          icon: Icons.scale_rounded,
          label: 'Total berat setor',
          value: AppFormatters.kg(data.saldo.totalBeratSetor),
          wide: true,
        ),
        const SizedBox(height: 18),
        _SectionTitle(title: 'Setoran terakhir'),
        const SizedBox(height: 10),
        if (data.setoranTerakhir.isEmpty)
          _EmptyPanel(message: 'Belum ada riwayat setoran.')
        else
          for (final item in data.setoranTerakhir) ...[
            _SetoranHistoryItem(item: item),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 18),
        _SectionTitle(title: 'Mutasi terakhir'),
        const SizedBox(height: 10),
        if (data.mutasiTerakhir.isEmpty)
          _EmptyPanel(message: 'Belum ada mutasi saldo.')
        else
          for (final item in data.mutasiTerakhir) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.payments_rounded, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.noBuktiRef.isEmpty ? 'Mutasi' : item.noBuktiRef,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppFormatters.shortDate(item.tglMutasi),
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    AppFormatters.rupiah(
                      item.pendingKredit +
                          item.tersediaKredit -
                          item.pendingDebit -
                          item.tersediaDebit,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _SetoranHistoryItem extends StatelessWidget {
  const _SetoranHistoryItem({required this.item});

  final Setoran item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            item.statusBatal ? Icons.block_rounded : Icons.inventory_2_rounded,
            color: item.statusBatal ? colorScheme.error : colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.noBukti,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppFormatters.shortDate(item.tglSetoran)} - ${AppFormatters.kg(item.totalBerat)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppFormatters.rupiah(item.totalNilai),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (item.statusBatal) ...[
                const SizedBox(height: 2),
                Text(
                  'VOID',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.wide = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.86),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          height: 82,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
