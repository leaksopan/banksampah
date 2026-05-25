import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/print_helper.dart';
import '../../../data/models/bank_sampah_models.dart';
import '../../../routing/route_paths.dart';
import '../providers/setoran_provider.dart';

class SetoranPrintScreen extends ConsumerWidget {
  const SetoranPrintScreen({super.key, required this.noBukti});

  final String noBukti;

  void _printReceipt(SetoranDetailData data) {
    final setoran = data.setoran;
    final unitName = setoran.unitBisnisName.isEmpty ? 'Bank Sampah Pemda' : setoran.unitBisnisName;

    final detailsHtml = data.details.map((item) => '''
      <tr>
        <td>
          <div class="font-bold">${item.namaSampah}</div>
          <small>${AppFormatters.kg(item.qty)} x ${AppFormatters.rupiah(item.hargaBeli)}</small>
        </td>
        <td class="text-right font-bold" style="vertical-align: middle;">${AppFormatters.rupiah(item.subtotal)}</td>
      </tr>
    ''').join('\n');

    final htmlContent = '''
      <div class="header">
        <h2 style="color: #2E7D32; font-size: 22px; margin-bottom: 5px;">♻️ $unitName</h2>
        <p class="font-bold" style="font-size: 14px; letter-spacing: 1px; margin: 0;">BUKTI SETORAN SAMPAH</p>
      </div>
      <div class="divider"></div>
      <table style="width: 100%; margin-bottom: 10px;">
        <tr><td class="font-bold" style="width: 25%; padding: 3px 0;">No Bukti</td><td style="padding: 3px 0;">: ${setoran.noBukti}</td></tr>
        <tr><td class="font-bold" style="padding: 3px 0;">Tanggal</td><td style="padding: 3px 0;">: ${AppFormatters.shortDate(setoran.tglSetoran)}</td></tr>
        <tr><td class="font-bold" style="padding: 3px 0;">Pegawai</td><td style="padding: 3px 0;">: ${setoran.namaPegawai}</td></tr>
        <tr><td class="font-bold" style="padding: 3px 0;">Lokasi</td><td style="padding: 3px 0;">: ${setoran.namaLokasi}</td></tr>
        ${setoran.keterangan.isNotEmpty ? '<tr><td class="font-bold" style="padding: 3px 0;">Keterangan</td><td style="padding: 3px 0;">: ${setoran.keterangan}</td></tr>' : ''}
        ${setoran.statusBatal ? '<tr><td class="font-bold" style="color: #c62828; padding: 3px 0;">Status</td><td style="color: #c62828; font-weight: bold; padding: 3px 0;">: DIBATALKAN</td></tr>' : ''}
      </table>
      <div class="divider-dashed"></div>
      <p class="font-bold" style="margin: 15px 0 8px 0; font-size: 13px;">RINCIAN SETORAN:</p>
      <table style="width: 100%;">
        <thead>
          <tr>
            <th style="padding: 8px 4px; text-align: left;">Komponen Sampah</th>
            <th style="padding: 8px 4px; text-align: right;">Subtotal</th>
          </tr>
        </thead>
        <tbody>
          $detailsHtml
          <tr class="total-row">
            <td style="padding: 10px 4px 6px 4px;">TOTAL BERAT</td>
            <td class="text-right" style="padding: 10px 4px 6px 4px;">${AppFormatters.kg(setoran.totalBerat)}</td>
          </tr>
          <tr class="total-row">
            <td style="padding: 6px 4px 10px 4px;">TOTAL ESTIMASI NILAI</td>
            <td class="text-right" style="padding: 6px 4px 10px 4px; font-size: 14px;">${AppFormatters.rupiah(setoran.totalNilai)}</td>
          </tr>
        </tbody>
      </table>
      <div class="divider" style="margin-top: 20px;"></div>
      <div class="signature-section" style="margin-top: 30px;">
        <div class="signature-box">
          <p style="margin: 0 0 50px 0;">Operator</p>
          <div class="signature-line"></div>
        </div>
        <div class="signature-box">
          <p style="margin: 0 0 50px 0;">Pegawai / Nasabah</p>
          <div class="signature-line"></div>
        </div>
      </div>
    ''';

    AppPrintHelper.printHtml(
      title: 'Bukti Setoran - ${setoran.noBukti}',
      htmlContent: htmlContent,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(setoranDetailProvider(noBukti));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: detailAsync.when(
          data:
              (data) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Kembali',
                        onPressed:
                            () => context.go(
                              RoutePaths.setoranDetail(noBukti),
                            ),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bukti Setoran',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cetak',
                        onPressed: () => _printReceipt(data),
                        icon: const Icon(Icons.print_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Receipt(data: data),
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
                      FilledButton.icon(
                        onPressed: () => ref.invalidate(
                          setoranDetailProvider(noBukti),
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

class _Receipt extends StatelessWidget {
  const _Receipt({required this.data});

  final SetoranDetailData data;

  @override
  Widget build(BuildContext context) {
    final setoran = data.setoran;
    final unitName =
        setoran.unitBisnisName.isEmpty
            ? 'Bank Sampah Pemda'
            : setoran.unitBisnisName;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E3E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                const Icon(
                  Icons.recycling_rounded,
                  color: Color(0xFF2E7D32),
                  size: 36,
                ),
                const SizedBox(height: 8),
                Text(
                  unitName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                const Text('Bukti Setoran Sampah'),
              ],
            ),
          ),
          const Divider(height: 32),
          _InfoLine(label: 'No Bukti', value: setoran.noBukti),
          _InfoLine(
            label: 'Tanggal',
            value: AppFormatters.shortDate(setoran.tglSetoran),
          ),
          _InfoLine(label: 'Pegawai', value: setoran.namaPegawai),
          _InfoLine(label: 'Lokasi', value: setoran.namaLokasi),
          if (setoran.keterangan.isNotEmpty)
            _InfoLine(label: 'Keterangan', value: setoran.keterangan),
          if (setoran.statusBatal)
            const _VoidNotice(),
          const SizedBox(height: 16),
          Text(
            'Rincian',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in data.details) _ReceiptDetailRow(item: item),
          const Divider(height: 28),
          _TotalLine(label: 'Total Berat', value: AppFormatters.kg(setoran.totalBerat)),
          _TotalLine(
            label: 'Total Nilai Estimasi',
            value: AppFormatters.rupiah(setoran.totalNilai),
          ),
          const SizedBox(height: 28),
          const Row(
            children: [
              Expanded(child: _SignatureBox(label: 'Operator')),
              SizedBox(width: 18),
              Expanded(child: _SignatureBox(label: 'Pegawai')),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const Text(': '),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}

class _ReceiptDetailRow extends StatelessWidget {
  const _ReceiptDetailRow({required this.item});

  final SetoranDetail item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.namaSampah,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppFormatters.kg(item.qty)} x ${AppFormatters.rupiah(item.hargaBeli)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            AppFormatters.rupiah(item.subtotal),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _SignatureBox extends StatelessWidget {
  const _SignatureBox({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label),
        const SizedBox(height: 56),
        Container(height: 1, color: const Color(0xFF9EA4AA)),
      ],
    );
  }
}

class _VoidNotice extends StatelessWidget {
  const _VoidNotice();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Status: DIBATALKAN',
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}
