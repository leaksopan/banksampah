import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../routing/route_paths.dart';
import '../providers/penjualan_provider.dart';

class PenjualanListScreen extends ConsumerWidget {
  const PenjualanListScreen({super.key});

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final current = ref.read(penjualanFilterDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2026),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      ref.read(penjualanFilterDateProvider.notifier).state = picked;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(penjualanFilterDateProvider);
    final penjualanAsync = ref.watch(penjualanListProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(penjualanListProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Kembali',
                    onPressed: () => context.go(RoutePaths.dashboard),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Penjualan',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Penjualan baru',
                    onPressed: () => context.go(RoutePaths.penjualanNew),
                    icon: const Icon(Icons.add_circle_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _DateFilter(date: date, onTap: () => _pickDate(context, ref)),
              const SizedBox(height: 16),
              penjualanAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const _EmptyState();
                  }

                  return Column(
                    children: [
                      for (final item in items) ...[
                        _PenjualanCard(
                          noBukti: item.noBukti,
                          namaVendor:
                              item.namaVendor.isEmpty
                                  ? 'Vendor'
                                  : item.namaVendor,
                          namaLokasi:
                              item.namaLokasi.isEmpty
                                  ? 'Lokasi'
                                  : item.namaLokasi,
                          totalBerat: item.totalBerat,
                          totalNilai: item.totalNilai,
                          totalSelisih: item.totalSelisih,
                          posted: item.posted,
                          statusBatal: item.statusBatal,
                          onTap:
                              () => context.go(
                                RoutePaths.penjualanDetail(item.noBukti),
                              ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                },
                error:
                    (error, _) => _ErrorBox(
                      message: error.toString(),
                      onRetry: () => ref.invalidate(penjualanListProvider),
                    ),
                loading:
                    () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 76),
        child: FloatingActionButton(
          tooltip: 'Penjualan baru',
          onPressed: () => context.go(RoutePaths.penjualanNew),
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }
}

class _DateFilter extends StatelessWidget {
  const _DateFilter({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppFormatters.shortDate(date),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.expand_more_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _PenjualanCard extends StatelessWidget {
  const _PenjualanCard({
    required this.noBukti,
    required this.namaVendor,
    required this.namaLokasi,
    required this.totalBerat,
    required this.totalNilai,
    required this.totalSelisih,
    required this.posted,
    required this.statusBatal,
    required this.onTap,
  });

  final String noBukti;
  final String namaVendor;
  final String namaLokasi;
  final num totalBerat;
  final num totalNilai;
  final num totalSelisih;
  final bool posted;
  final bool statusBatal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selisihColor =
        totalSelisih < 0 ? colorScheme.error : const Color(0xFF168A55);

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      noBukti,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            statusBatal
                                ? colorScheme.error
                                : colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StatusBadge(
                    icon:
                        statusBatal
                            ? Icons.block_rounded
                            : Icons.check_circle_rounded,
                    label: statusBatal ? 'Batal' : posted ? 'Posted' : 'Draft',
                    color:
                        statusBatal
                            ? colorScheme.error
                            : const Color(0xFF168A55),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                namaVendor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                namaLokasi,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text(AppFormatters.kg(totalBerat))),
                  Text(
                    AppFormatters.rupiah(totalNilai),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Selisih ${AppFormatters.rupiah(totalSelisih)}',
                style: TextStyle(color: selisihColor, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.local_shipping_outlined, size: 36),
          SizedBox(height: 10),
          Text('Belum ada penjualan di tanggal ini.'),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}
