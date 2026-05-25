import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../routing/route_paths.dart';
import '../providers/setoran_provider.dart';

class SetoranListScreen extends ConsumerWidget {
  const SetoranListScreen({super.key});

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final current = ref.read(setoranFilterDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2026),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      ref.read(setoranFilterDateProvider.notifier).state = picked;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(setoranFilterDateProvider);
    final pegawaiId = ref.watch(setoranFilterPegawaiIdProvider);
    final lokasiId = ref.watch(setoranFilterLokasiIdProvider);
    final setoranAsync = ref.watch(setoranListProvider);
    final lookupsAsync = ref.watch(setoranLookupsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final hasExtraFilter = pegawaiId != null || lokasiId != null;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(setoranListProvider),
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
                      'Setoran',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Setoran baru',
                    onPressed: () => context.go(RoutePaths.setoranNew),
                    icon: const Icon(Icons.add_circle_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _FilterPanel(
                date: date,
                lookupsAsync: lookupsAsync,
                selectedPegawaiId: pegawaiId,
                selectedLokasiId: lokasiId,
                onPickDate: () => _pickDate(context, ref),
                onPegawaiChanged:
                    (value) =>
                        ref.read(setoranFilterPegawaiIdProvider.notifier).state =
                            value,
                onLokasiChanged:
                    (value) =>
                        ref.read(setoranFilterLokasiIdProvider.notifier).state =
                            value,
                onReset:
                    hasExtraFilter
                        ? () {
                          ref
                              .read(setoranFilterPegawaiIdProvider.notifier)
                              .state = null;
                          ref
                              .read(setoranFilterLokasiIdProvider.notifier)
                              .state = null;
                        }
                        : null,
              ),
              if (hasExtraFilter) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Filter pegawai/lokasi aktif',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              setoranAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const _SetoranEmptyState();
                  }

                  return Column(
                    children: [
                      for (final item in items) ...[
                        _SetoranCard(
                          noBukti: item.noBukti,
                          namaPegawai: item.namaPegawai,
                          namaLokasi: item.namaLokasi,
                          totalBerat: item.totalBerat,
                          totalNilai: item.totalNilai,
                          statusBatal: item.statusBatal,
                          onTap: () => context.go(
                            RoutePaths.setoranDetail(item.noBukti),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                },
                error: (error, _) => _ErrorBox(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(setoranListProvider),
                ),
                loading: () => const Center(
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
      floatingActionButton: FloatingActionButton(
        tooltip: 'Setoran baru',
        onPressed: () => context.go(RoutePaths.setoranNew),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _SetoranCard extends StatelessWidget {
  const _SetoranCard({
    required this.noBukti,
    required this.namaPegawai,
    required this.namaLokasi,
    required this.totalBerat,
    required this.totalNilai,
    required this.statusBatal,
    required this.onTap,
  });

  final String noBukti;
  final String namaPegawai;
  final String namaLokasi;
  final num totalBerat;
  final num totalNilai;
  final bool statusBatal;
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                noBukti,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color:
                      statusBatal
                          ? colorScheme.error
                          : colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (statusBatal) ...[
                const SizedBox(height: 6),
                _StatusBadge(
                  icon: Icons.block_rounded,
                  label: 'Dibatalkan',
                  color: colorScheme.error,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                namaPegawai.isEmpty ? 'Pegawai' : namaPegawai,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                namaLokasi.isEmpty ? 'Lokasi' : namaLokasi,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text(AppFormatters.kg(totalBerat))),
                  Text(
                    AppFormatters.rupiah(totalNilai),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.date,
    required this.lookupsAsync,
    required this.selectedPegawaiId,
    required this.selectedLokasiId,
    required this.onPickDate,
    required this.onPegawaiChanged,
    required this.onLokasiChanged,
    required this.onReset,
  });

  final DateTime date;
  final AsyncValue<SetoranLookups> lookupsAsync;
  final int? selectedPegawaiId;
  final int? selectedLokasiId;
  final VoidCallback onPickDate;
  final ValueChanged<int?> onPegawaiChanged;
  final ValueChanged<int?> onLokasiChanged;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onPickDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppFormatters.shortDate(date),
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Icon(Icons.expand_more_rounded),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          lookupsAsync.when(
            data:
                (lookups) => Column(
                  children: [
                    _FilterDropdown<int>(
                      label: 'Pegawai',
                      icon: Icons.badge_rounded,
                      value: selectedPegawaiId,
                      items: [
                        for (final pegawai in lookups.pegawai)
                          DropdownMenuItem<int>(
                            value: pegawai.pegawaiId,
                            child: Text(
                              pegawai.namaPegawai,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: onPegawaiChanged,
                    ),
                    const SizedBox(height: 10),
                    _FilterDropdown<int>(
                      label: 'Lokasi',
                      icon: Icons.warehouse_rounded,
                      value: selectedLokasiId,
                      items: [
                        for (final lokasi in lookups.lokasi)
                          DropdownMenuItem<int>(
                            value: lokasi.lokasiId,
                            child: Text(
                              lokasi.namaLokasi,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: onLokasiChanged,
                    ),
                  ],
                ),
            error:
                (error, _) => Text(
                  'Filter pegawai/lokasi gagal dimuat.',
                  style: TextStyle(color: colorScheme.error),
                ),
            loading:
                () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
          ),
          if (onReset != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('Reset filter'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: [
        DropdownMenuItem<T>(
          value: null,
          child: Text('Semua $label'),
        ),
        ...items,
      ],
      onChanged: onChanged,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
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

class _SetoranEmptyState extends StatelessWidget {
  const _SetoranEmptyState();

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
          Icon(Icons.inventory_2_outlined, size: 36),
          SizedBox(height: 10),
          Text('Belum ada setoran di tanggal ini.'),
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
