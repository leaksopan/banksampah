import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/reporting_provider.dart';
import '../../../data/models/bank_sampah_models.dart';

class CoaListScreen extends ConsumerStatefulWidget {
  const CoaListScreen({super.key});

  @override
  ConsumerState<CoaListScreen> createState() => _CoaListScreenState();
}

class _CoaListScreenState extends ConsumerState<CoaListScreen> {
  bool _isTreeView = true; // Default ke view visual pohon (Tree)

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 20),
              _buildViewSelector(colorScheme),
              const SizedBox(height: 20),
              _isTreeView
                  ? _buildTreeView(coaList, colorScheme)
                  : _buildTableView(coaList, colorScheme),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Gagal memuat COA: $err')),
      ),
    );
  }

  Widget _buildViewSelector(ColorScheme colorScheme) {
    return Center(
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(
            value: true,
            icon: Icon(Icons.account_tree_rounded),
            label: Text('Hierarki Pohon (Tree)', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          ButtonSegment(
            value: false,
            icon: Icon(Icons.table_chart_rounded),
            label: Text('Daftar Tabel (Flat)', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
        selected: {_isTreeView},
        onSelectionChanged: (newSelection) {
          setState(() {
            _isTreeView = newSelection.first;
          });
        },
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: colorScheme.primary.withValues(alpha: 0.15),
          selectedForegroundColor: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTreeView(List<COA> coaList, ColorScheme colorScheme) {
    // Pengelompokan hierarkis
    final aktivaLancar = coaList.where((c) => c.kategoriCoa == 'AKTIVA_LANCAR').toList();
    final aktivaTetap = coaList.where((c) => c.kategoriCoa == 'AKTIVA_TETAP').toList();
    final kewajiban = coaList.where((c) => c.kategoriCoa == 'KEWAJIBAN').toList();
    final ekuitas = coaList.where((c) => c.kategoriCoa == 'EKUITAS').toList();
    final pendapatan = coaList.where((c) => c.kategoriCoa == 'PENDAPATAN').toList();
    final bebanHpp = coaList.where((c) => c.kategoriCoa == 'BEBAN_HPP').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. AKTIVA
        _buildTreeGroupHeader('1. AKTIVA', Icons.account_balance_rounded, Colors.blue, colorScheme),
        if (aktivaLancar.isNotEmpty) ...[
          _buildTreeSubgroupHeader('1.1. Aktiva Lancar', colorScheme),
          for (final coa in aktivaLancar) _buildTreeLeaf(coa, colorScheme),
        ],
        if (aktivaTetap.isNotEmpty) ...[
          _buildTreeSubgroupHeader('1.2. Aktiva Tetap', colorScheme),
          for (final coa in aktivaTetap) _buildTreeLeaf(coa, colorScheme),
        ],
        const SizedBox(height: 16),

        // 2. KEWAJIBAN
        _buildTreeGroupHeader('2. KEWAJIBAN / PASIVA', Icons.assignment_rounded, Colors.orange, colorScheme),
        if (kewajiban.isNotEmpty) ...[
          _buildTreeSubgroupHeader('2.1. Hutang Jangka Pendek', colorScheme),
          for (final coa in kewajiban) _buildTreeLeaf(coa, colorScheme),
        ],
        const SizedBox(height: 16),

        // 3. EKUITAS
        _buildTreeGroupHeader('3. EKUITAS / PASIVA', Icons.pie_chart_rounded, Colors.teal, colorScheme),
        if (ekuitas.isNotEmpty) ...[
          _buildTreeSubgroupHeader('3.1. Modal & Saldo Laba', colorScheme),
          for (final coa in ekuitas) _buildTreeLeaf(coa, colorScheme),
        ],
        const SizedBox(height: 16),

        // 4. PENDAPATAN
        _buildTreeGroupHeader('4. PENDAPATAN', Icons.trending_up_rounded, Colors.green, colorScheme),
        if (pendapatan.isNotEmpty) ...[
          _buildTreeSubgroupHeader('4.1. Pendapatan Operasional & Penyesuaian', colorScheme),
          for (final coa in pendapatan) _buildTreeLeaf(coa, colorScheme),
        ],
        const SizedBox(height: 16),

        // 5. BEBAN HPP
        _buildTreeGroupHeader('5. BEBAN HPP', Icons.trending_down_rounded, Colors.red, colorScheme),
        if (bebanHpp.isNotEmpty) ...[
          _buildTreeSubgroupHeader('5.1. Harga Pokok & Beban Penyesuaian', colorScheme),
          for (final coa in bebanHpp) _buildTreeLeaf(coa, colorScheme),
        ],
      ],
    );
  }

  Widget _buildTreeGroupHeader(String title, IconData icon, Color badgeColor, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: badgeColor, size: 22),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: badgeColor.darken(colorScheme.brightness == Brightness.dark ? 0.0 : 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeSubgroupHeader(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, top: 8, bottom: 4),
      child: Row(
        children: [
          Icon(Icons.subdirectory_arrow_right_rounded, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4), size: 16),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeLeaf(COA coa, ColorScheme colorScheme) {
    final isDebit = coa.normalBalance == 'D';
    return Container(
      margin: const EdgeInsets.only(left: 56, top: 4, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              coa.coaName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: isDebit ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isDebit ? 'DEBET' : 'KREDIT',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: isDebit ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableView(List<COA> coaList, ColorScheme colorScheme) {
    return Card(
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
                      color: coa.normalBalance == 'D' ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      coa.normalBalance == 'D' ? 'DEBET' : 'KREDIT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: coa.normalBalance == 'D' ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
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

extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsv = HSVColor.fromColor(this);
    final hsvDark = hsv.withValue((hsv.value - amount).clamp(0.0, 1.0));
    return hsvDark.toColor();
  }
}
