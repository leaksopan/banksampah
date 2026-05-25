import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/print_helper.dart';
import '../providers/reporting_provider.dart';
import '../../../data/models/bank_sampah_models.dart';

class HppReportScreen extends ConsumerStatefulWidget {
  const HppReportScreen({super.key});

  @override
  ConsumerState<HppReportScreen> createState() => _HppReportScreenState();
}

class _HppReportScreenState extends ConsumerState<HppReportScreen> {
  late DateTime _fromDate;
  late DateTime _toDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = DateTime(now.year, now.month, now.day + 1);
  }

  void _printLabaRugi(ReportHppLabaRugi report, UnitBisnis? unit) {
    final unitName = unit?.unitBisnisName ?? 'Bank Sampah Pemda';
    final unitNameFull = unit?.unitBisnisName ?? 'Bank Sampah Pemda';
    final formattedFrom = AppFormatters.shortDate(_fromDate);
    final formattedTo = AppFormatters.shortDate(_toDate.subtract(const Duration(days: 1)));

    final htmlContent = '''
      <div class="header">
        <h2 style="color: #2E7D32; font-size: 20px; margin: 0 0 2px 0;">$unitName</h2>
        <p class="font-bold" style="font-size: 11px; margin: 0 0 12px 0; color: #555;">$unitNameFull</p>
        <h3 class="font-bold" style="font-size: 15px; margin: 0 0 4px 0; letter-spacing: 0.5px;">LAPORAN LABA RUGI & HARGA POKOK PENJUALAN (HPP)</h3>
        <p class="font-bold" style="margin: 0; font-size: 12px; color: #333;">Periode: $formattedFrom s.d $formattedTo</p>
      </div>
      <div class="divider"></div>
      
      <table style="width: 100%; border: 1px solid #000; margin-bottom: 20px;">
        <thead>
          <tr style="background-color: #f4f6f8;">
            <th style="padding: 8px 10px; border-bottom: 1px solid #000; text-align: left;">DESKRIPSI AKUN</th>
            <th style="padding: 8px 10px; border-bottom: 1px solid #000; text-align: left; width: 15%;">COA</th>
            <th style="padding: 8px 10px; border-bottom: 1px solid #000; text-align: right; width: 25%;">NOMINAL (RP)</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td colspan="3" class="font-bold" style="padding: 10px 4px 5px 4px; color: #2E7D32; font-size: 12px;">I. PENDAPATAN OPERASIONAL</td>
          </tr>
          <tr>
            <td style="padding: 5px 10px;">Pendapatan Penjualan Sampah ke Pengepul</td>
            <td>4101</td>
            <td class="text-right">${AppFormatters.rupiah(report.totalPendapatan)}</td>
          </tr>
          <tr class="font-bold" style="border-top: 1px dashed #ccc;">
            <td style="padding: 8px 10px;">TOTAL PENDAPATAN OPERASIONAL</td>
            <td></td>
            <td class="text-right" style="border-bottom: 1px solid #000;">${AppFormatters.rupiah(report.totalPendapatan)}</td>
          </tr>
          
          <tr>
            <td colspan="3" class="font-bold" style="padding: 15px 4px 5px 4px; color: #2E7D32; font-size: 12px;">II. HARGA POKOK PENJUALAN (HPP) FIFO</td>
          </tr>
          <tr>
            <td style="padding: 5px 10px;">HPP Sampah Terjual (Pembelian dari Nasabah - FIFO)</td>
            <td>5101</td>
            <td class="text-right">(${AppFormatters.rupiah(report.totalHpp)})</td>
          </tr>
          <tr class="font-bold" style="border-top: 1px dashed #ccc;">
            <td style="padding: 8px 10px;">TOTAL HARGA POKOK PENJUALAN (HPP)</td>
            <td></td>
            <td class="text-right" style="border-bottom: 1px solid #000;">(${AppFormatters.rupiah(report.totalHpp)})</td>
          </tr>
          
          <tr class="total-row" style="background-color: #f4f6f8; font-size: 14px;">
            <td style="padding: 10px; font-weight: bold;">LABA RUGI BERSIH TPS</td>
            <td></td>
            <td class="text-right" style="font-weight: bold; color: ${report.labaRugiBersih >= 0 ? '#2E7D32' : '#c62828'}">
              ${AppFormatters.rupiah(report.labaRugiBersih)}
            </td>
          </tr>
        </tbody>
      </table>

      <div style="margin-top: 15px; padding: 12px; border: 1px solid #78909c; background-color: #f4f6f8; border-radius: 6px; font-size: 11px; line-height: 1.4; color: #445;">
        <strong>Catatan Akuntansi Perdagangan:</strong><br>
        Laporan Laba Rugi ini menyajikan selisih bersih dari hasil penjualan sampah ke pengepul dikurangi harga beli dari nasabah (HPP FIFO). Keuntungan/kerugian harga ditanggung oleh TPS sebagai unit bisnis mandiri.
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
      title: 'Laporan Laba Rugi - $formattedFrom s.d $formattedTo',
      htmlContent: htmlContent,
    );
  }

  void _exportLabaRugiCsv(ReportHppLabaRugi report, UnitBisnis? unit) {
    final unitName = unit?.unitBisnisName ?? 'Bank Sampah Pemda';
    final formattedFrom = AppFormatters.shortDate(_fromDate);
    final formattedTo = AppFormatters.shortDate(_toDate.subtract(const Duration(days: 1)));

    // Helper to sanitize CSV fields (handling commas and quotes)
    String esc(dynamic val) {
      final str = val.toString().replaceAll('"', '""');
      if (str.contains(',') || str.contains('\n') || str.contains('"')) {
        return '"$str"';
      }
      return str;
    }

    final csv = StringBuffer();
    csv.writeln('\uFEFF${esc('LAPORAN LABA RUGI & HARGA POKOK PENJUALAN (HPP)')},,'); // UTF-8 BOM
    csv.writeln('${esc(unitName)},,');
    csv.writeln('${esc('Periode: $formattedFrom s.d $formattedTo')},,');
    csv.writeln(',,');

    csv.writeln('${esc('DESKRIPSI AKUN')},${esc('COA')},${esc('NOMINAL (RP)')}');

    // I. Pendapatan
    csv.writeln('${esc('I. PENDAPATAN OPERASIONAL')},,');
    csv.writeln('${esc('Pendapatan Penjualan Sampah ke Pengepul')},4101,${esc(report.totalPendapatan)}');
    csv.writeln('${esc('TOTAL PENDAPATAN OPERASIONAL')},,${esc(report.totalPendapatan)}');
    csv.writeln(',,');

    // II. HPP
    csv.writeln('${esc('II. HARGA POKOK PENJUALAN (HPP) FIFO')},,');
    csv.writeln('${esc('HPP Sampah Terjual (Pembelian dari Nasabah - FIFO)')},5101,${esc(-report.totalHpp)}');
    csv.writeln('${esc('TOTAL HARGA POKOK PENJUALAN (HPP)')},,${esc(-report.totalHpp)}');
    csv.writeln(',,');

    // Total Laba Rugi
    csv.writeln('${esc('LABA RUGI BERSIH TPS')},,${esc(report.labaRugiBersih)}');

    AppPrintHelper.exportCsv(
      filename: 'LabaRugi_${unitName.replaceAll(' ', '_')}_${formattedFrom}_to_$formattedTo.csv',
      csvContent: csv.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final params = HppLabaRugiParams(from: _fromDate, to: _toDate);
    final hppAsync = ref.watch(reportHppLabaRugiProvider(params));
    final unitBisnisAsync = ref.watch(currentUnitBisnisProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan HPP & Laba Rugi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(reportHppLabaRugiProvider(params)),
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
          hppAsync.when(
            data: (report) {
              return _buildReportContent(report, colorScheme);
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
                child: Text('Gagal memuat laporan: $err', style: const TextStyle(color: Colors.red)),
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
                    'PERIODE LAPORAN',
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
                      const Icon(Icons.date_range_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${AppFormatters.shortDate(_fromDate)} - ${AppFormatters.shortDate(_toDate.subtract(const Duration(days: 1)))}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.date_range_rounded),
              label: const Text('Pilih Periode'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (range != null) {
                  setState(() {
                    _fromDate = range.start;
                    _toDate = range.end;
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
                final params = HppLabaRugiParams(from: _fromDate, to: _toDate);
                final report = ref.read(reportHppLabaRugiProvider(params)).valueOrNull;
                final unit = ref.read(currentUnitBisnisProvider).valueOrNull;
                if (report != null) {
                  _printLabaRugi(report, unit);
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
                final params = HppLabaRugiParams(from: _fromDate, to: _toDate);
                final report = ref.read(reportHppLabaRugiProvider(params)).valueOrNull;
                final unit = ref.read(currentUnitBisnisProvider).valueOrNull;
                if (report != null) {
                  _exportLabaRugiCsv(report, unit);
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
          'LAPORAN LABA RUGI & HARGA POKOK PENJUALAN (HPP)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Periode ${AppFormatters.shortDate(_fromDate)} s.d ${AppFormatters.shortDate(_toDate.subtract(const Duration(days: 1)))}',
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

  Widget _buildReportContent(ReportHppLabaRugi report, ColorScheme colorScheme) {
    return Column(
      children: [
        _buildCoopAccountingNotice(colorScheme),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderRow('PENDAPATAN OPERASIONAL', colorScheme),
                _buildItemRow('Pendapatan Penjualan Sampah ke Pengepul', '4101', report.totalPendapatan, false),
                const Divider(),
                _buildTotalRow('TOTAL PENDAPATAN OPERASIONAL', report.totalPendapatan, colorScheme),
                const SizedBox(height: 24),
                
                _buildHeaderRow('HARGA POKOK PENJUALAN (HPP) FIFO', colorScheme),
                _buildItemRow('HPP Sampah Terjual (Pembelian dari Nasabah - FIFO)', '5101', report.totalHpp, true),
                const Divider(),
                _buildTotalRow('TOTAL HARGA POKOK PENJUALAN (HPP)', report.totalHpp, colorScheme),
                
                const SizedBox(height: 20),
                const Divider(thickness: 2),
                _buildTotalRow('LABA RUGI BERSIH TPS', report.labaRugiBersih, colorScheme, isPrimary: true, forceHighlight: true),
                const Divider(thickness: 2),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoopAccountingNotice(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: colorScheme.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catatan Akuntansi Perdagangan:',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                ),
                SizedBox(height: 2),
                Text(
                  'Laporan Laba Rugi ini menyajikan selisih bersih dari hasil penjualan sampah ke pengepul dikurangi harga beli dari nasabah (HPP FIFO). Keuntungan/kerugian harga ditanggung oleh TPS sebagai unit bisnis mandiri.',
                  style: TextStyle(fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildItemRow(String name, String coa, num value, bool isNegative) {
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
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  coa,
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isNegative ? "(" : ""}${AppFormatters.rupiah(value.abs())}${isNegative ? ")" : ""}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String title,
    num total,
    ColorScheme colorScheme, {
    bool isPrimary = false,
    bool forceHighlight = false,
  }) {
    final showNegativeBrackets = total < 0;
    Color textColor = colorScheme.onSurface;
    if (isPrimary) {
      textColor = colorScheme.primary;
    }
    if (forceHighlight) {
      textColor = const Color(0xFF2E7D32); // Green for net profit
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: isPrimary ? FontWeight.w900 : FontWeight.w800,
              fontSize: isPrimary ? 13 : 12,
            ),
          ),
          Text(
            '${showNegativeBrackets ? "(" : ""}${AppFormatters.rupiah(total.abs())}${showNegativeBrackets ? ")" : ""}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: isPrimary ? 15 : 13,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
