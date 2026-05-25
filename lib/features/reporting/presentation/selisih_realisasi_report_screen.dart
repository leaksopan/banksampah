import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/bank_sampah_models.dart';
import '../../../data/repositories/bank_sampah_repository.dart';
import '../../auth/providers/auth_state_provider.dart';
import '../providers/reporting_provider.dart';

final reportPegawaiListProvider = FutureProvider.autoDispose<List<Pegawai>>((ref) {
  return ref.watch(bankSampahRepositoryProvider).listPegawaiAktif();
});

class SelisihRealisasiReportScreen extends ConsumerStatefulWidget {
  const SelisihRealisasiReportScreen({super.key});

  @override
  ConsumerState<SelisihRealisasiReportScreen> createState() => _SelisihRealisasiReportScreenState();
}

class _SelisihRealisasiReportScreenState extends ConsumerState<SelisihRealisasiReportScreen> {
  int? _selectedPegawaiId;
  bool _hasSearched = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = ref.watch(appUserProvider).valueOrNull;
    final isAdmin = user?.isAdmin ?? false;
    final pegawaiListAsync = ref.watch(reportPegawaiListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transparansi Selisih Realisasi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          if (isAdmin) ...[
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Pilih Pegawai untuk Audit',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    pegawaiListAsync.when(
                      data: (pegawais) {
                        return DropdownButtonFormField<int>(
                          value: _selectedPegawaiId,
                          decoration: InputDecoration(
                            labelText: 'Pegawai (Nasabah)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          items: pegawais.map((p) {
                            return DropdownMenuItem(
                              value: p.pegawaiId,
                              child: Text('${p.namaPegawai} (${p.nip})'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedPegawaiId = val;
                              _hasSearched = false;
                            });
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Gagal memuat pegawai: $e'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _selectedPegawaiId == null
                          ? null
                          : () {
                              setState(() {
                                _hasSearched = true;
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('AUDIT DETAIL', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (!isAdmin) ...[
            _buildExplanationBanner(colorScheme),
            const SizedBox(height: 20),
            Text(
              'Rincian Pembagian Margin Anda',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _buildNasabahResults(colorScheme),
          ] else if (_hasSearched && _selectedPegawaiId != null) ...[
            Text(
              'Rincian Alokasi Penjualan FIFO',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _buildAdminResults(colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildExplanationBanner(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user_rounded, color: Color(0xFF2E7D32), size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prinsip Transparansi FIFO',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1B5E20)),
                ),
                SizedBox(height: 3),
                Text(
                  'Setiap kali sampah yang Anda setorkan berhasil dijual ke vendor, selisih harga jual vs estimasi beli langsung dialokasikan ke saldo Tersedia Anda secara otomatis dan adil.',
                  style: TextStyle(fontSize: 11, height: 1.3, color: Color(0xFF2E7D32)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNasabahResults(ColorScheme colorScheme) {
    final reportAsync = ref.watch(currentPegawaiReportSelisihProvider);

    return reportAsync.when(
      data: (records) => _buildRecordsList(records, colorScheme),
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (e, _) => Center(child: Text('Gagal memuat transparansi: $e')),
    );
  }

  Widget _buildAdminResults(ColorScheme colorScheme) {
    final reportAsync = ref.watch(reportSelisihRealisasiProvider(_selectedPegawaiId!));

    return reportAsync.when(
      data: (records) => _buildRecordsList(records, colorScheme),
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (e, _) => Center(child: Text('Gagal memuat transparansi: $e')),
    );
  }

  Widget _buildRecordsList(List<ReportSelisihRealisasi> records, ColorScheme colorScheme) {
    if (records.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text('Belum ada pembagian selisih realisasi penjualan.'),
        ),
      );
    }

    num totalSelisih = records.fold(0, (sum, x) => sum + x.totalSelisih);

    return Column(
      children: [
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
              Icon(Icons.add_chart_rounded, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL AKUMULASI SELISIH TEREALISASI',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFormatters.rupiah(totalSelisih),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: totalSelisih >= 0 ? const Color(0xFF2E7D32) : colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final rec = records[index];
            final profit = rec.totalSelisih >= 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          rec.namaSampah,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        Text(
                          AppFormatters.rupiah(rec.totalSelisih),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: profit ? const Color(0xFF2E7D32) : colorScheme.error,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                    const SizedBox(height: 8),
                    _buildRowDetail('No. Bukti Penjualan', rec.noBukti, colorScheme),
                    _buildRowDetail('Tanggal Penjualan', AppFormatters.shortDate(rec.tglPenjualan), colorScheme),
                    _buildRowDetail('Qty Terjual', AppFormatters.kg(rec.qtyKeluar), colorScheme),
                    _buildRowDetail('Harga Estimasi (Setor)', AppFormatters.rupiah(rec.hargaBeli), colorScheme),
                    _buildRowDetail('Harga Realisasi (Jual)', AppFormatters.rupiah(rec.hargaJual), colorScheme),
                    _buildRowDetail('Selisih per Kg', AppFormatters.rupiah(rec.selisihPerKg), colorScheme),
                    _buildRowDetail('No. Bukti Setoran Asal', rec.noBuktiAsal, colorScheme),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRowDetail(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }
}
