import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/route_paths.dart';

class ReportingScreen extends ConsumerWidget {
  const ReportingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan Operasional',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
        children: [
          _buildInfoBanner(colorScheme),
          const SizedBox(height: 24),
          Text(
            'Laporan Inventaris & Gudang',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _buildReportMenuItem(
            context: context,
            title: 'Laporan Kartu Gudang',
            subtitle: 'Alur persediaan sampah, penerimaan, penjualan, dan penyesuaian.',
            icon: Icons.inventory_rounded,
            color: colorScheme.primary,
            path: RoutePaths.reportKartuGudang,
          ),
          const SizedBox(height: 20),
          Text(
            'Laporan Keuangan & Saldo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _buildReportMenuItem(
            context: context,
            title: 'Rekap Saldo Pegawai',
            subtitle: 'Daftar saldo pending, saldo tersedia, rekap setor, dan total ditarik pegawai.',
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFF00A6D6),
            path: RoutePaths.reportSaldoPegawai,
          ),
          const SizedBox(height: 12),
          _buildReportMenuItem(
            context: context,
            title: 'Laporan Selisih Realisasi FIFO',
            subtitle: 'Log pembagian selisih penjualan sampah ke vendor per pegawai.',
            icon: Icons.history_rounded,
            color: const Color(0xFF55CFA1),
            path: RoutePaths.reportSelisihRealisasi,
          ),
          const SizedBox(height: 20),
          Text(
            'Akuntansi & HPP SAK-EMKM',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _buildReportMenuItem(
            context: context,
            title: 'Laporan Neraca Keuangan',
            subtitle: 'Laporan neraca keseimbangan Aktiva dan Pasiva SAK-EMKM.',
            icon: Icons.account_balance_rounded,
            color: const Color(0xFF7E57C2),
            path: RoutePaths.reportNeraca,
          ),
          const SizedBox(height: 12),
          _buildReportMenuItem(
            context: context,
            title: 'Laporan Laba Rugi & HPP',
            subtitle: 'Rincian pendapatan penjualan, HPP FIFO, dan penyesuaian nilai.',
            icon: Icons.analytics_rounded,
            color: const Color(0xFFEC407A),
            path: RoutePaths.reportHppLabaRugi,
          ),
          const SizedBox(height: 12),
          _buildReportMenuItem(
            context: context,
            title: 'Bagan Akun Referensi (COA)',
            subtitle: 'Daftar rekening bagan akun akuntansi standar SAK-EMKM.',
            icon: Icons.account_tree_rounded,
            color: const Color(0xFF78909C),
            path: RoutePaths.reportCoaList,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.analytics_rounded, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard Laporan',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                SizedBox(height: 2),
                Text(
                  'Pilih menu laporan di bawah untuk meninjau log operasional TPS.',
                  style: TextStyle(fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportMenuItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String path,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.go(path),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
