import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/reporting_provider.dart';

class CoaListScreen extends ConsumerWidget {
  const CoaListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final coaAsync = ref.watch(coaListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bagan Akun Referensi (COA)',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(coaListProvider),
          ),
        ],
      ),
      body: coaAsync.when(
        data: (coaList) {
          if (coaList.isEmpty) {
            return const Center(
              child: Text('Tidak ada referensi akun yang ditemukan.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildIntroBanner(colorScheme),
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
                    columnSpacing: 28,
                    columns: const [
                      DataColumn(label: Text('Kode Akun', style: TextStyle(fontWeight: FontWeight.w800))),
                      DataColumn(label: Text('Nama Rekening/Akun', style: TextStyle(fontWeight: FontWeight.w800))),
                      DataColumn(label: Text('Kategori Akun', style: TextStyle(fontWeight: FontWeight.w800))),
                      DataColumn(label: Text('Saldo Normal', style: TextStyle(fontWeight: FontWeight.w800))),
                    ],
                    rows: coaList.map((coa) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                coa.coaId,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.primary,
                                  fontFamily: 'Courier',
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              coa.coaName,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          DataCell(
                            Text(
                              _formatKategori(coa.kategoriCoa),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: coa.normalBalance == 'D'
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                coa.normalBalance == 'D' ? 'DEBET' : 'KREDIT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: coa.normalBalance == 'D'
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFE65100),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Gagal memuat COA: $err')),
      ),
    );
  }

  Widget _buildIntroBanner(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.account_tree_rounded, color: colorScheme.primary),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chart of Accounts (COA) SAK-EMKM',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                ),
                SizedBox(height: 2),
                Text(
                  'Daftar akun standar akuntansi keuangan yang digunakan untuk merekam seluruh entri jurnal transaksi TPS secara berpasangan.',
                  style: TextStyle(fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatKategori(String raw) {
    switch (raw) {
      case 'AKTIVA_LANCAR':
        return 'Aktiva Lancar';
      case 'AKTIVA_TETAP':
        return 'Aktiva Tetap';
      case 'KEWAJIBAN':
        return 'Kewajiban / Pasiva';
      case 'EKUITAS':
        return 'Ekuitas / Modal';
      case 'PENDAPATAN':
        return 'Pendapatan';
      case 'BEBAN_HPP':
        return 'Beban Pokok Penjualan';
      default:
        return raw;
    }
  }
}
