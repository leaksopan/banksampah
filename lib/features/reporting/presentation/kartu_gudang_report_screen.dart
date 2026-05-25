import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/bank_sampah_models.dart';
import '../../../data/repositories/bank_sampah_repository.dart';
import '../providers/reporting_provider.dart';

final reportLocationsProvider = FutureProvider.autoDispose<List<Lokasi>>((ref) {
  return ref.watch(bankSampahRepositoryProvider).listLokasiAktif();
});

final reportTrashProvider = FutureProvider.autoDispose<List<Sampah>>((ref) {
  return ref.watch(bankSampahRepositoryProvider).listSampahAktif();
});

class KartuGudangReportScreen extends ConsumerStatefulWidget {
  const KartuGudangReportScreen({super.key});

  @override
  ConsumerState<KartuGudangReportScreen> createState() => _KartuGudangReportScreenState();
}

class _KartuGudangReportScreenState extends ConsumerState<KartuGudangReportScreen> {
  int? _selectedLokasiId;
  int? _selectedSampahId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _hasSearched = false;

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final locationsAsync = ref.watch(reportLocationsProvider);
    final trashAsync = ref.watch(reportTrashProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan Kartu Gudang',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
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
                    'Filter Pencarian',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  locationsAsync.when(
                    data: (locs) {
                      return DropdownButtonFormField<int>(
                        value: _selectedLokasiId,
                        decoration: InputDecoration(
                          labelText: 'Lokasi/TPS',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        items: locs.map((loc) {
                          return DropdownMenuItem(
                            value: loc.lokasiId,
                            child: Text(loc.namaLokasi),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedLokasiId = val;
                          });
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Gagal memuat lokasi: $e'),
                  ),
                  const SizedBox(height: 12),
                  trashAsync.when(
                    data: (trashList) {
                      return DropdownButtonFormField<int>(
                        value: _selectedSampahId,
                        decoration: InputDecoration(
                          labelText: 'Jenis Sampah',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        items: trashList.map((sampah) {
                          return DropdownMenuItem(
                            value: sampah.sampahId,
                            child: Text('${sampah.namaSampah} (${sampah.kodeSampah})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedSampahId = val;
                          });
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Gagal memuat jenis sampah: $e'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _selectDateRange(context),
                    icon: const Icon(Icons.date_range_rounded),
                    label: Text(
                      _startDate == null || _endDate == null
                          ? 'Pilih Periode Tanggal (Opsional)'
                          : '${AppFormatters.shortDate(_startDate!)} - ${AppFormatters.shortDate(_endDate!)}',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _selectedLokasiId == null || _selectedSampahId == null
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
                    child: const Text('PROSES LAPORAN', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_hasSearched && _selectedLokasiId != null && _selectedSampahId != null) ...[
            Text(
              'Rincian Buku Mutasi',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _buildReportResults(colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildReportResults(ColorScheme colorScheme) {
    final params = KartuGudangParams(
      lokasiId: _selectedLokasiId!,
      sampahId: _selectedSampahId!,
      from: _startDate,
      to: _endDate,
    );

    final reportAsync = ref.watch(reportKartuGudangProvider(params));

    return reportAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text('Tidak ada log mutasi persediaan pada kriteria ini.'),
            ),
          );
        }

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Tanggal')),
                DataColumn(label: Text('Transaksi')),
                DataColumn(label: Text('No Bukti')),
                DataColumn(label: Text('Masuk (Kg)')),
                DataColumn(label: Text('Harga Masuk')),
                DataColumn(label: Text('Keluar (Kg)')),
                DataColumn(label: Text('Harga Keluar')),
                DataColumn(label: Text('Stok Saldo')),
                DataColumn(label: Text('Harga WAC')),
              ],
              rows: records.map((rec) {
                return DataRow(
                  cells: [
                    DataCell(Text(AppFormatters.shortDate(rec.tglTransaksi))),
                    DataCell(Text(rec.namaTransaksi)),
                    DataCell(Text(rec.noBukti, style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(rec.qtyMasuk > 0 ? AppFormatters.kg(rec.qtyMasuk) : '-')),
                    DataCell(Text(rec.qtyMasuk > 0 ? AppFormatters.rupiah(rec.hargaMasuk) : '-')),
                    DataCell(Text(rec.qtyKeluar > 0 ? AppFormatters.kg(rec.qtyKeluar) : '-')),
                    DataCell(Text(rec.qtyKeluar > 0 ? AppFormatters.rupiah(rec.hargaKeluar) : '-')),
                    DataCell(Text(AppFormatters.kg(rec.qtySaldo), style: const TextStyle(fontWeight: FontWeight.w800))),
                    DataCell(Text(AppFormatters.rupiah(rec.hargaPersediaan))),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (e, _) => Center(child: Text('Gagal memuat laporan: $e')),
    );
  }
}
