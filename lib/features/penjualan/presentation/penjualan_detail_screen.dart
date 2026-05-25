import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/bank_sampah_models.dart';
import '../../../routing/route_paths.dart';
import '../providers/penjualan_provider.dart';

class PenjualanDetailScreen extends ConsumerWidget {
  const PenjualanDetailScreen({super.key, required this.noBukti});

  final String noBukti;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(penjualanDetailProvider(noBukti));

    return Scaffold(
      body: SafeArea(
        child: detailAsync.when(
          data:
              (data) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Kembali',
                        onPressed: () => context.go(RoutePaths.penjualan),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Detail Penjualan',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _HeaderCard(data: data),
                  const SizedBox(height: 16),
                  Text(
                    'Rincian Sampah',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final detail in data.details) ...[
                    _DetailCard(detail: detail),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
          error:
              (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed:
                            () => ref.invalidate(
                              penjualanDetailProvider(noBukti),
                            ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.data});

  final PenjualanDetailData data;

  @override
  Widget build(BuildContext context) {
    final item = data.penjualan;
    final colorScheme = Theme.of(context).colorScheme;
    final selisihColor =
        item.totalSelisih < 0 ? colorScheme.error : const Color(0xFF168A55);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.noBukti,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.namaVendor.isEmpty ? 'Vendor' : item.namaVendor,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.namaLokasi.isEmpty ? 'Lokasi' : item.namaLokasi} - ${item.typePembayaran == 'T' ? 'Transfer' : 'Cash'}',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          _MetricRow(label: 'Total berat', value: AppFormatters.kg(item.totalBerat)),
          _MetricRow(
            label: 'Total penjualan',
            value: AppFormatters.rupiah(item.totalNilai),
          ),
          _MetricRow(label: 'Total HPP', value: AppFormatters.rupiah(item.totalHpp)),
          _MetricRow(
            label: 'Selisih',
            value: AppFormatters.rupiah(item.totalSelisih),
            color: selisihColor,
          ),
          const SizedBox(height: 8),
          _StatusLine(posted: item.posted, disetujui: item.disetujui),
          if (item.keterangan.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(item.keterangan),
          ],
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.posted, required this.disetujui});

  final bool posted;
  final bool disetujui;

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF168A55);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Badge(label: posted ? 'Posted' : 'Draft', color: color),
        _Badge(label: disetujui ? 'Disetujui' : 'Belum disetujui', color: color),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

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
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.detail});

  final PenjualanDetail detail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selisih = detail.subtotal - detail.totalHppDetail;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.namaSampah.isEmpty ? 'Sampah' : detail.namaSampah,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          _MetricRow(label: 'Qty', value: AppFormatters.kg(detail.qty)),
          _MetricRow(
            label: 'Harga jual',
            value: AppFormatters.rupiah(detail.hargaJual),
          ),
          _MetricRow(
            label: 'Subtotal',
            value: AppFormatters.rupiah(detail.subtotal),
          ),
          _MetricRow(
            label: 'HPP',
            value: AppFormatters.rupiah(detail.totalHppDetail),
          ),
          _MetricRow(label: 'Selisih', value: AppFormatters.rupiah(selisih)),
        ],
      ),
    );
  }
}
