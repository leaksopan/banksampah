import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/bank_sampah_models.dart';
import '../../auth/providers/auth_state_provider.dart';
import '../providers/penarikan_provider.dart';

class PenarikanDetailScreen extends ConsumerStatefulWidget {
  const PenarikanDetailScreen({super.key, required this.noBukti});

  final String noBukti;

  @override
  ConsumerState<PenarikanDetailScreen> createState() => _PenarikanDetailScreenState();
}

class _PenarikanDetailScreenState extends ConsumerState<PenarikanDetailScreen> {
  final _noteController = TextEditingController();
  final _urlController = TextEditingController();
  bool _actionLoading = false;

  @override
  void dispose() {
    _noteController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleApprove(bool approve) async {
    setState(() {
      _actionLoading = true;
    });

    try {
      await ref.read(penarikanControllerProvider).approve(
            noBukti: widget.noBukti,
            approve: approve,
            keterangan: _noteController.text.trim().isNotEmpty
                ? _noteController.text.trim()
                : null,
          );

      if (mounted) {
        Navigator.pop(context); // Close bottom sheet / dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve
                ? 'Pengajuan penarikan disetujui!'
                : 'Pengajuan penarikan ditolak.'),
            backgroundColor: approve ? const Color(0xFF2E7D32) : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses approval: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });
      }
    }
  }

  Future<void> _handlePay() async {
    setState(() {
      _actionLoading = true;
    });

    try {
      await ref.read(penarikanControllerProvider).pay(
            noBukti: widget.noBukti,
            buktiTransferUrl: _urlController.text.trim().isNotEmpty
                ? _urlController.text.trim()
                : null,
            keterangan: _noteController.text.trim().isNotEmpty
                ? _noteController.text.trim()
                : null,
          );

      if (mounted) {
        Navigator.pop(context); // Close bottom sheet / dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran penarikan berhasil diproses!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses pembayaran: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });
      }
    }
  }

  void _showApproveSheet(BuildContext context, bool approve) {
    _noteController.clear();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                approve ? 'Konfirmasi Persetujuan' : 'Konfirmasi Penolakan',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                approve
                    ? 'Apakah Anda yakin ingin menyetujui pengajuan penarikan ini? Pegawai akan segera diberi izin penarikan.'
                    : 'Berikan alasan penolakan penarikan ini.',
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: approve ? 'Catatan (Opsional)' : 'Alasan Penolakan (Wajib)',
                  hintText: 'Tulis keterangan...',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _actionLoading
                          ? null
                          : () {
                              if (!approve && _noteController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Alasan penolakan wajib diisi.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              _handleApprove(approve);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: approve ? const Color(0xFF2E7D32) : colorScheme.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _actionLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                          : Text(approve ? 'Setujui' : 'Tolak'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPaySheet(BuildContext context) {
    _noteController.clear();
    _urlController.clear();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Proses Pembayaran Penarikan',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Tandai transaksi ini sudah dibayar (baik via tunai atau bank transfer). Saldo Tersedia pegawai akan berkurang.',
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'URL Bukti Transfer / Referensi (Opsional)',
                  hintText: 'Contoh: https://link-bukti.com atau ref-123',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Catatan Pembayaran (Opsional)',
                  hintText: 'Tulis catatan...',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _actionLoading ? null : _handlePay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _actionLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                          : const Text('Sudah Dibayar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = ref.watch(appUserProvider).valueOrNull;
    final isAdmin = user?.isAdmin ?? false;
    final detailAsync = ref.watch(penarikanDetailProvider(widget.noBukti));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Penarikan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: detailAsync.when(
        data: (item) {
          if (item == null) {
            return const Center(child: Text('Transaksi penarikan tidak ditemukan.'));
          }

          final isTransfer = item.typePembayaran == 'T';

          Color statusColor;
          IconData statusIcon;
          switch (item.status) {
            case 'PAID':
              statusColor = const Color(0xFF2E7D32);
              statusIcon = Icons.check_circle_rounded;
              break;
            case 'APPROVED':
              statusColor = const Color(0xFF0288D1);
              statusIcon = Icons.rule_rounded;
              break;
            case 'REJECTED':
              statusColor = colorScheme.error;
              statusIcon = Icons.cancel_rounded;
              break;
            default:
              statusColor = const Color(0xFFEF6C00);
              statusIcon = Icons.hourglass_empty_rounded;
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                children: [
                  _buildProgressTracker(item, statusColor, statusIcon),
                  const SizedBox(height: 24),
                  _buildReceiptCard(item, isTransfer, colorScheme),
                  const SizedBox(height: 20),
                  if (item.keterangan.isNotEmpty) ...[
                    _buildNoteSection(item, colorScheme),
                    const SizedBox(height: 20),
                  ],
                  if (item.status == 'PAID' && item.buktiTransferUrl != null) ...[
                    _buildPaymentSection(item, colorScheme),
                  ],
                ],
              ),
              if (isAdmin && item.status != 'PAID' && item.status != 'REJECTED')
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: Row(
                    children: [
                      if (item.status == 'PENDING') ...[
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () => _showApproveSheet(context, false),
                              icon: const Icon(Icons.cancel_rounded),
                              label: const Text('Tolak'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.error,
                                side: BorderSide(color: colorScheme.error),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () => _showApproveSheet(context, true),
                              icon: const Icon(Icons.check_circle_rounded),
                              label: const Text('Setujui'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0288D1),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ),
                      ] else if (item.status == 'APPROVED') ...[
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () => _showPaySheet(context),
                              icon: const Icon(Icons.payments_rounded),
                              label: const Text('Proses Pembayaran'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat detail: $e')),
      ),
    );
  }

  Widget _buildProgressTracker(Penarikan item, Color statusColor, IconData statusIcon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STATUS PENGAJUAN',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: Colors.black54),
                ),
                const SizedBox(height: 3),
                Text(
                  item.status,
                  style: TextStyle(color: statusColor, fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(Penarikan item, bool isTransfer, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'BUKTI PENARIKAN TABUNGAN',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.black54),
                ),
                Icon(Icons.recycling_rounded, color: Color(0xFF2E7D32), size: 18),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  const Text('Total Penarikan', style: TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(
                     AppFormatters.rupiah(item.jumlah),
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _buildReceiptRow('Nomor Bukti', item.noBukti, colorScheme),
            _buildReceiptRow('Tanggal Pengajuan', AppFormatters.shortDate(item.tglPenarikan), colorScheme),
            _buildReceiptRow('Pegawai', item.namaPegawai, colorScheme),
            _buildReceiptRow('Tipe Pembayaran', isTransfer ? 'Transfer Bank' : 'Tunai', colorScheme),
            if (isTransfer) ...[
              _buildReceiptRow('Nama Bank', item.namaBank ?? '-', colorScheme),
              _buildReceiptRow('Nomor Rekening', item.noRek ?? '-', colorScheme),
              _buildReceiptRow('Atas Nama Rekening', item.atasNama ?? '-', colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSection(Penarikan item, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded, color: colorScheme.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Catatan / Alasan',
                style: TextStyle(fontWeight: FontWeight.w800, color: colorScheme.primary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.keterangan,
            style: const TextStyle(fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(Penarikan item, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payments_rounded, color: Color(0xFF2E7D32), size: 16),
              const SizedBox(width: 8),
              Text(
                'Detail Realisasi Pembayaran',
                style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2E7D32), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (item.tglBayar != null)
            _buildReceiptRow('Tanggal Bayar', AppFormatters.shortDate(item.tglBayar!), colorScheme),
          if (item.buktiTransferUrl != null && item.buktiTransferUrl!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Referensi Pembayaran', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    item.buktiTransferUrl!,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF1E88E5)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
