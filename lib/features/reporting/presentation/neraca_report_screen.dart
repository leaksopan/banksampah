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

  void _printNeraca(List<ReportNeracaItem> list, UnitBisnis? unit) {
    final unitName = unit?.unitBisnisName ?? 'Bank Sampah Pemda';
    final unitNameFull = unit?.unitBisnisName ?? 'Bank Sampah Pemda';
    final formattedDate = AppFormatters.shortDate(_selectedDate);

    final aktivaList = list.where((x) => x.kategoriCoa == 'AKTIVA_LANCAR' || x.kategoriCoa == 'AKTIVA_TETAP').toList();
    final kewajibanList = list.where((x) => x.kategoriCoa == 'KEWAJIBAN').toList();
    final ekuitasList = list.where((x) => x.kategoriCoa == 'EKUITAS').toList();

    num totalAktiva = aktivaList.fold(0, (sum, x) => sum + x.saldo);
    num totalKewajiban = kewajibanList.fold(0, (sum, x) => sum + x.saldo);
    num totalEkuitas = ekuitasList.fold(0, (sum, x) => sum + x.saldo);
    num totalPasiva = totalKewajiban + totalEkuitas;

    String buildRows(List<ReportNeracaItem> items) {
      if (items.isEmpty) {
        return '<tr><td colspan="2" style="font-style: italic; color: #888; padding: 4px;">(Tidak ada saldo)</td></tr>';
      }
      return items.map((x) => '''
        <tr>
          <td style="padding: 5px 4px;">${x.coaId} - ${x.coaName}</td>
          <td class="text-right font-bold" style="padding: 5px 4px;">${AppFormatters.rupiah(x.saldo)}</td>
        </tr>
      ''').join('\n');
    }

    final isBalanced = (totalAktiva - totalPasiva).abs() < 0.05;

    final htmlContent = '''
      <div class="header">
        <h2 style="color: #2E7D32; font-size: 20px; margin: 0 0 2px 0;">$unitName</h2>
        <p class="font-bold" style="font-size: 11px; margin: 0 0 12px 0; color: #555;">$unitNameFull</p>
        <h3 class="font-bold" style="font-size: 16px; margin: 0 0 4px 0; letter-spacing: 0.5px;">LAPORAN NERACA KEUANGAN</h3>
        <p class="font-bold" style="margin: 0; font-size: 12px; color: #333;">Per Tanggal: $formattedDate</p>
      </div>
      <div class="divider"></div>
      
      <table style="width: 100%; border: 1px solid #000; margin-bottom: 20px;">
        <thead>
          <tr style="background-color: #f4f6f8;">
            <th style="width: 50%; padding: 8px 10px; border-bottom: 1px solid #000; border-right: 1px solid #000; text-align: left;">AKTIVA (ASSETS)</th>
            <th style="width: 50%; padding: 8px 10px; border-bottom: 1px solid #000; text-align: left;">PASIVA (LIABILITIES & EQUITY)</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td style="vertical-align: top; border-right: 1px solid #000; padding: 10px;">
              <table style="width: 100%; margin: 0;">
                ${buildRows(aktivaList)}
                <tr class="total-row">
                  <td style="padding: 8px 4px; border-top: 1px solid #000;">TOTAL AKTIVA</td>
                  <td class="text-right" style="padding: 8px 4px; border-top: 1px solid #000;">${AppFormatters.rupiah(totalAktiva)}</td>
                </tr>
              </table>
            </td>
            <td style="vertical-align: top; padding: 10px;">
              <table style="width: 100%; margin: 0;">
                <tr><td colspan="2" class="font-bold" style="padding: 3px 4px; border-bottom: 1px dashed #ccc; font-size: 11px; color: #555;">KEWAJIBAN</td></tr>
                ${buildRows(kewajibanList)}
                <tr class="font-bold">
                  <td style="padding: 8px 4px; padding-left: 10px;">Subtotal Kewajiban</td>
                  <td class="text-right" style="padding: 8px 4px;">${AppFormatters.rupiah(totalKewajiban)}</td>
                </tr>
                <tr><td colspan="2" class="font-bold" style="padding: 12px 4px 3px 4px; border-bottom: 1px dashed #ccc; font-size: 11px; color: #555;">EKUITAS</td></tr>
                ${buildRows(ekuitasList)}
                <tr class="font-bold">
                  <td style="padding: 8px 4px; padding-left: 10px;">Subtotal Ekuitas</td>
                  <td class="text-right" style="padding: 8px 4px;">${AppFormatters.rupiah(totalEkuitas)}</td>
                </tr>
                <tr class="total-row">
                  <td style="padding: 8px 4px; border-top: 1px solid #000;">TOTAL PASIVA</td>
                  <td class="text-right" style="padding: 8px 4px; border-top: 1px solid #000;">${AppFormatters.rupiah(totalPasiva)}</td>
                </tr>
              </table>
            </td>
          </tr>
        </tbody>
      </table>

      <div style="margin-top: 15px; padding: 12px; border: 1px solid ${isBalanced ? '#2E7D32' : '#c62828'}; background-color: ${isBalanced ? '#e8f5e9' : '#ffebee'}; border-radius: 6px; text-align: center; font-weight: bold; font-size: 13px;">
        Status Neraca: ${isBalanced ? 'SEIMBANG (BALANCED)' : 'TIDAK SEIMBANG (UNBALANCED)'}
      </div>

      <div class="signature-section" style="margin-top: 40px;">
        <div class="signature-box">
          <p style="margin: 0 0 50px 0;">Disiapkan Oleh,<br>Operator TPS</p>
          <div class="signature-line"></div>
        </div>
        <div class="signature-box">
          <p style="margin: 0 0 50px 0;">Disetujui Oleh,<br>Ketua Unit Bisnis / Kepala OPD</p>
          <div class="signature-line"></div>
        </div>
      </div>
    ''';

    AppPrintHelper.printHtml(
      title: 'Laporan Neraca - $formattedDate',
      htmlContent: htmlContent,
    );
  }

  void _exportNeracaCsv(List<ReportNeracaItem> list, UnitBisnis? unit) {
    final unitName = unit?.unitBisnisName ?? 'Bank Sampah Pemda';
    final formattedDate = AppFormatters.shortDate(_selectedDate);

    final aktivaList = list.where((x) => x.kategoriCoa == 'AKTIVA_LANCAR' || x.kategoriCoa == 'AKTIVA_TETAP').toList();
    final kewajibanList = list.where((x) => x.kategoriCoa == 'KEWAJIBAN').toList();
    final ekuitasList = list.where((x) => x.kategoriCoa == 'EKUITAS').toList();

    num totalAktiva = aktivaList.fold(0, (sum, x) => sum + x.saldo);
    num totalKewajiban = kewajibanList.fold(0, (sum, x) => sum + x.saldo);
    num totalEkuitas = ekuitasList.fold(0, (sum, x) => sum + x.saldo);
    num totalPasiva = totalKewajiban + totalEkuitas;

    final isBalanced = (totalAktiva - totalPasiva).abs() < 0.05;

    // Helper to sanitize CSV fields (handling commas and quotes)
    String esc(dynamic val) {
      final str = val.toString().replaceAll('"', '""');
      if (str.contains(',') || str.contains('\n') || str.contains('"')) {
        return '"$str"';
      }
      return str;
    }

    final csv = StringBuffer();
    csv.writeln('\uFEFF${esc('LAPORAN NERACA KEUANGAN (SAK-EMKM)')},,'); // UTF-8 BOM so Excel opens it with correct encoding
    csv.writeln('${esc(unitName)},,');
    csv.writeln('${esc('Per Tanggal: $formattedDate')},,');
    csv.writeln(',,');

    csv.writeln('${esc('AKTIVA (ASSETS)')},,,${esc('PASIVA (LIABILITIES & EQUITY)')}');
    csv.writeln('${esc('Kode & Nama Akun')},${esc('Saldo (Rp)')},,${esc('Kode & Nama Akun')},${esc('Saldo (Rp)')}');

    // We will align rows side-by-side
    final int maxRows = aktivaList.length > (kewajibanList.length + ekuitasList.length + 4) 
        ? aktivaList.length 
        : (kewajibanList.length + ekuitasList.length + 4);

    // Build lists for pasiva layout
    final List<String> pasivaRowsCoa = [];
    final List<num> pasivaRowsSaldo = [];

    // Add Kewajiban Section
    pasivaRowsCoa.add('KEWAJIBAN');
    pasivaRowsSaldo.add(0); // divider placeholder
    for (var x in kewajibanList) {
      pasivaRowsCoa.add('${x.coaId} - ${x.coaName}');
      pasivaRowsSaldo.add(x.saldo);
    }
    pasivaRowsCoa.add('Subtotal Kewajiban');
    pasivaRowsSaldo.add(totalKewajiban);

    // Spacer
    pasivaRowsCoa.add('');
    pasivaRowsSaldo.add(0);

    // Add Ekuitas Section
    pasivaRowsCoa.add('EKUITAS');
    pasivaRowsSaldo.add(0);
    for (var x in ekuitasList) {
      pasivaRowsCoa.add('${x.coaId} - ${x.coaName}');
      pasivaRowsSaldo.add(x.saldo);
    }
    pasivaRowsCoa.add('Subtotal Ekuitas');
    pasivaRowsSaldo.add(totalEkuitas);

    for (int i = 0; i < maxRows; i++) {
      String aktivaCoa = '';
      String aktivaSaldo = '';
      if (i < aktivaList.length) {
        final x = aktivaList[i];
        aktivaCoa = '${x.coaId} - ${x.coaName}';
        aktivaSaldo = x.saldo.toString();
      }

      String pasivaCoa = '';
      String pasivaSaldo = '';
      if (i < pasivaRowsCoa.length) {
        pasivaCoa = pasivaRowsCoa[i];
        final s = pasivaRowsSaldo[i];
        // Don't print saldo for section dividers
        if (pasivaCoa != 'KEWAJIBAN' && pasivaCoa != 'EKUITAS' && pasivaCoa.isNotEmpty) {
          pasivaSaldo = s.toString();
        }
      }

      csv.writeln('${esc(aktivaCoa)},${esc(aktivaSaldo)},,${esc(pasivaCoa)},${esc(pasivaSaldo)}');
    }

    // Totals Row
    csv.writeln(',,');
    csv.writeln('${esc('TOTAL AKTIVA')},${esc(totalAktiva)},,${esc('TOTAL PASIVA')},${esc(totalPasiva)}');
    csv.writeln(',,');
    csv.writeln('${esc('Status Neraca: ${isBalanced ? 'SEIMBANG (BALANCED)' : 'TIDAK SEIMBANG (UNBALANCED)'}')},,');

    AppPrintHelper.exportCsv(
      filename: 'Neraca_${unitName.replaceAll(' ', '_')}_$formattedDate.csv',
      csvContent: csv.toString(),
    );
  }

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
              onPressed: () {
                final neracaList = ref.read(reportNeracaProvider(_selectedDate)).valueOrNull;
                final unit = ref.read(currentUnitBisnisProvider).valueOrNull;
                if (neracaList != null) {
                  _printNeraca(neracaList, unit);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Laporan belum dimuat sepenuhnya.')),
                  );
                }
              },
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              icon: const Icon(Icons.table_view_rounded),
              tooltip: 'Unduh Excel/CSV',
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
              ),
              onPressed: () {
                final neracaList = ref.read(reportNeracaProvider(_selectedDate)).valueOrNull;
                final unit = ref.read(currentUnitBisnisProvider).valueOrNull;
                if (neracaList != null) {
                  _exportNeracaCsv(neracaList, unit);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Laporan belum dimuat sepenuhnya.')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
