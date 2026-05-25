import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../providers/reporting_provider.dart';
import '../../../data/models/bank_sampah_models.dart';

class SaldoPegawaiReportScreen extends ConsumerStatefulWidget {
  const SaldoPegawaiReportScreen({super.key});

  @override
  ConsumerState<SaldoPegawaiReportScreen> createState() => _SaldoPegawaiReportScreenState();
}

class _SaldoPegawaiReportScreenState extends ConsumerState<SaldoPegawaiReportScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ringkasanAsync = ref.watch(ringkasanPegawaiProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rekapitulasi Saldo Pegawai',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(ringkasanPegawaiProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(ringkasanPegawaiProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSearchField(colorScheme),
            const SizedBox(height: 20),
            ringkasanAsync.when(
              data: (list) {
                var filteredList = list;
                if (_searchQuery.isNotEmpty) {
                  filteredList = filteredList
                      .where((x) => x.namaPegawai.toLowerCase().contains(_searchQuery) || x.nip.toLowerCase().contains(_searchQuery))
                      .toList();
                }

                if (filteredList.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text('Tidak ada data pegawai yang sesuai.'),
                    ),
                  );
                }

                return Column(
                  children: [
                    _buildSummaryMetrics(filteredList, colorScheme),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Nama Pegawai')),
                            DataColumn(label: Text('NIP')),
                            DataColumn(label: Text('Saldo Tersedia')),
                            DataColumn(label: Text('Saldo Pending')),
                            DataColumn(label: Text('Total Ditarik')),
                            DataColumn(label: Text('Setor (Kg)')),
                            DataColumn(label: Text('Terjual (Kg)')),
                          ],
                          rows: filteredList.map((rec) {
                            return DataRow(
                              cells: [
                                DataCell(Text(rec.namaPegawai, style: const TextStyle(fontWeight: FontWeight.w800))),
                                DataCell(Text(rec.nip.isNotEmpty ? rec.nip : '-')),
                                DataCell(Text(AppFormatters.rupiah(rec.saldoTersedia),
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2E7D32)))),
                                DataCell(Text(AppFormatters.rupiah(rec.saldoPending),
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFEF6C00)))),
                                DataCell(Text(AppFormatters.rupiah(rec.totalDitarik))),
                                DataCell(Text(AppFormatters.kg(rec.totalBeratSetor))),
                                DataCell(Text(AppFormatters.kg(rec.totalBeratTerjual))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
              error: (e, _) => Center(child: Text('Gagal memuat rekap saldo: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(ColorScheme colorScheme) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Cari nama pegawai atau NIP...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              )
            : null,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (val) {
        setState(() {
          _searchQuery = val.trim().toLowerCase();
        });
      },
    );
  }

  Widget _buildSummaryMetrics(List<RingkasanPegawai> list, ColorScheme colorScheme) {
    num totalTersedia = list.fold(0, (sum, x) => sum + x.saldoTersedia);
    num totalPending = list.fold(0, (sum, x) => sum + x.saldoPending);
    num totalDitarik = list.fold(0, (sum, x) => sum + x.totalDitarik);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Total Saldo Tersedia',
                value: AppFormatters.rupiah(totalTersedia),
                color: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.hourglass_bottom_rounded,
                label: 'Total Saldo Pending',
                value: AppFormatters.rupiah(totalPending),
                color: const Color(0xFFEF6C00),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.payments_rounded, color: Color(0xFF00A6D6)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL SALDO TLAH DITARIK PEGAWAI',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFormatters.rupiah(totalDitarik),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
