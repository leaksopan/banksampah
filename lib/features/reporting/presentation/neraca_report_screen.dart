import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/print_helper.dart';
import '../providers/reporting_provider.dart';
import '../../../data/models/bank_sampah_models.dart';

class NeracaReportScreen extends ConsumerStatefulWidget {
  const NeracaReportScreen({super.key});

  @override
  ConsumerState<NeracaReportScreen> createState() => _NeracaReportScreenState();
}

class _SaldoLabaCalculator {
  // Safe parsing helper
  static num getSaldo(List<ReportNeracaItem> list, String code) {
    final item = list.cast<ReportNeracaItem?>().firstWhere(
      (x) => x?.coaId == code,
      orElse: () => null,
    );
    return item?.saldo ?? 0.0;
  }
}

class _NeracaReportScreenState extends ConsumerState<NeracaReportScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final neracaAsync = ref.watch(reportNeracaProvider(_selectedDate));
    final unitBisnisAsync = ref.watch(currentUnitBisnisProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan Neraca (Balance Sheet)',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(reportNeracaProvider(_selectedDate)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFilterCard(colorScheme),
          const SizedBox(height: 24),
          unitBisnisAsync.when(
            data: (unit) => _buildReportHeader(unit, colorScheme),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),
          neracaAsync.when(
            data: (neracaList) {
              return _buildNeracaGrid(neracaList, colorScheme);
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text('Gagal memuat neraca: $err', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard(ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PILIH TANGGAL NERACA',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        AppFormatters.shortDate(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.date_range_rounded),
              label: const Text('Ubah Tanggal'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              icon: const Icon(Icons.print_rounded),
              tooltip: 'Cetak Laporan / Simpan PDF',
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: AppPrintHelper.printCurrentPage,
            ),

  Widget _buildReportHeader(UnitBisnis? unit, ColorScheme colorScheme) {
    if (unit == null) return const SizedBox.shrink();
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(
          'BANK SAMPAH PEGAWAI PEMERINTAH DAERAH',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: colorScheme.primary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unit.unitBisnisName.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'LAPORAN NERACA KEUANGAN (SAK-EMKM)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Per Tanggal ${AppFormatters.shortDate(_selectedDate)}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
      ],
    );
  }

  Widget _buildNeracaGrid(List<ReportNeracaItem> list, ColorScheme colorScheme) {
    final aktivaList = list.where((x) => x.kategoriCoa == 'AKTIVA_LANCAR' || x.kategoriCoa == 'AKTIVA_TETAP').toList();
    final kewajibanList = list.where((x) => x.kategoriCoa == 'KEWAJIBAN').toList();
    final ekuitasList = list.where((x) => x.kategoriCoa == 'EKUITAS').toList();

    num totalAktiva = aktivaList.fold(0, (sum, x) => sum + x.saldo);
    num totalKewajiban = kewajibanList.fold(0, (sum, x) => sum + x.saldo);
    num totalEkuitas = ekuitasList.fold(0, (sum, x) => sum + x.saldo);
    num totalPasiva = totalKewajiban + totalEkuitas;

    // Check balance
    final isBalanced = (totalAktiva - totalPasiva).abs() < 0.05;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        if (isWide) {
          // Double-column wide layout: Aktiva on Left, Pasiva on Right
          return Column(
            children: [
              _buildBalanceBanner(isBalanced, totalAktiva, totalPasiva, colorScheme),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildColumnSection(
                      title: 'AKTIVA (ASSETS)',
                      items: aktivaList,
                      total: totalAktiva,
                      colorScheme: colorScheme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildColumnSection(
                          title: 'KEWAJIBAN (LIABILITIES)',
                          items: kewajibanList,
                          total: totalKewajiban,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 16),
                        _buildColumnSection(
                          title: 'EKUITAS (EQUITY)',
                          items: ekuitasList,
                          total: totalEkuitas,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 16),
                        _buildTotalPasivaRow(totalPasiva, colorScheme),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          // Mobile single column layout: Aktiva then Pasiva
          return Column(
            children: [
              _buildBalanceBanner(isBalanced, totalAktiva, totalPasiva, colorScheme),
              const SizedBox(height: 16),
              _buildColumnSection(
                title: 'AKTIVA (ASSETS)',
                items: aktivaList,
                total: totalAktiva,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 20),
              _buildColumnSection(
                title: 'KEWAJIBAN (LIABILITIES)',
                items: kewajibanList,
                total: totalKewajiban,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 20),
              _buildColumnSection(
                title: 'EKUITAS (EQUITY)',
                items: ekuitasList,
                total: totalEkuitas,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 16),
              _buildTotalPasivaRow(totalPasiva, colorScheme),
            ],
          );
        }
      },
    );
  }

  Widget _buildBalanceBanner(bool isBalanced, num aktiva, num pasiva, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isBalanced ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBalanced ? const Color(0xFFC8E6C9) : const Color(0xFFFFCDD2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isBalanced ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            color: isBalanced ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBalanced ? 'NERACA SEIMBANG (BALANCED)' : 'NERACA TIDAK SEIMBANG (MISMATCH)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isBalanced ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isBalanced
                      ? 'Total Aktiva sama dengan total Pasiva (${AppFormatters.rupiah(aktiva)}).'
                      : 'Selisih Aktiva & Pasiva sebesar ${AppFormatters.rupiah((aktiva - pasiva).abs())}. Harap periksa pembukuan jurnal.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isBalanced ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnSection({
    required String title,
    required List<ReportNeracaItem> items,
    required num total,
    required ColorScheme colorScheme,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(),
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.coaName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.coaId,
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      AppFormatters.rupiah(item.saldo),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            const Divider(thickness: 1.5),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.between,
                children: [
                  Text(
                    'TOTAL $title',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                  Text(
                    AppFormatters.rupiah(total),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalPasivaRow(num totalPasiva, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.between,
        children: [
          const Text(
            'TOTAL PASIVA (KEWAJIBAN + EKUITAS)',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          ),
          Text(
            AppFormatters.rupiah(totalPasiva),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
