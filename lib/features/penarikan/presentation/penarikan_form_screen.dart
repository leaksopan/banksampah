import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../routing/route_paths.dart';
import '../providers/penarikan_provider.dart';

class PenarikanFormScreen extends ConsumerStatefulWidget {
  const PenarikanFormScreen({super.key});

  @override
  ConsumerState<PenarikanFormScreen> createState() => _PenarikanFormScreenState();
}

class _PenarikanFormScreenState extends ConsumerState<PenarikanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahController = TextEditingController();
  final _noRekController = TextEditingController();
  final _bankController = TextEditingController();
  final _atasNamaController = TextEditingController();
  final _keteranganController = TextEditingController();

  String _typePembayaran = 'C'; // C = Cash/Tunai, T = Transfer Bank
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _jumlahController.dispose();
    _noRekController.dispose();
    _bankController.dispose();
    _atasNamaController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _submit(int pegawaiId, num saldoTersedia) async {
    if (!_formKey.currentState!.validate()) return;

    final jumlah = num.tryParse(_jumlahController.text.trim());
    if (jumlah == null || jumlah <= 0) {
      setState(() {
        _errorMessage = 'Jumlah penarikan tidak valid.';
      });
      return;
    }

    if (jumlah > saldoTersedia) {
      setState(() {
        _errorMessage = 'Saldo tidak mencukupi.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(penarikanControllerProvider).create(
            pegawaiId: pegawaiId,
            jumlah: jumlah,
            typePembayaran: _typePembayaran,
            noRek: _typePembayaran == 'T' ? _noRekController.text.trim() : null,
            bank: _typePembayaran == 'T' ? _bankController.text.trim() : null,
            atasNama: _typePembayaran == 'T' ? _atasNamaController.text.trim() : null,
            keterangan: _keteranganController.text.trim().isNotEmpty
                ? _keteranganController.text.trim()
                : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan penarikan berhasil diajukan!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        context.go(RoutePaths.penarikan);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentPegawaiAsync = ref.watch(currentPegawaiProvider);
    final saldoAsync = ref.watch(currentPegawaiSaldoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tarik Tabungan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: currentPegawaiAsync.when(
        data: (pegawai) {
          if (pegawai == null) {
            return const Center(child: Text('Profil pegawai tidak ditemukan.'));
          }

          return saldoAsync.when(
            data: (saldo) {
              final saldoTersedia = saldo?.saldoTersedia ?? 0;

              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    _buildSaldoHeader(colorScheme, saldoTersedia),
                    const SizedBox(height: 24),
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded, color: colorScheme.error),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Text(
                      'Detail Penarikan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _jumlahController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Jumlah Penarikan',
                        hintText: 'Masukkan nominal...',
                        prefixText: 'Rp ',
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: colorScheme.outlineVariant),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Jumlah penarikan wajib diisi.';
                        }
                        final parsed = num.tryParse(value.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Jumlah penarikan harus lebih dari 0.';
                        }
                        if (parsed > saldoTersedia) {
                          return 'Saldo tidak mencukupi.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Metode Pembayaran',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeCard(
                            label: 'Tunai (Cash)',
                            value: 'C',
                            icon: Icons.payments_rounded,
                            selected: _typePembayaran == 'C',
                            colorScheme: colorScheme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTypeCard(
                            label: 'Transfer Bank',
                            value: 'T',
                            icon: Icons.account_balance_rounded,
                            selected: _typePembayaran == 'T',
                            colorScheme: colorScheme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_typePembayaran == 'T') ...[
                      Text(
                        'Rekening Bank Penerima',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bankController,
                        decoration: InputDecoration(
                          labelText: 'Nama Bank',
                          hintText: 'Contoh: BPD Bali, BRI, BCA...',
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        validator: (v) => _typePembayaran == 'T' && (v == null || v.trim().isEmpty)
                            ? 'Nama bank wajib diisi.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _noRekController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Nomor Rekening',
                          hintText: 'Masukkan no rekening...',
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        validator: (v) => _typePembayaran == 'T' && (v == null || v.trim().isEmpty)
                            ? 'Nomor rekening wajib diisi.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _atasNamaController,
                        decoration: InputDecoration(
                          labelText: 'Atas Nama',
                          hintText: 'Nama pemilik rekening...',
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        validator: (v) => _typePembayaran == 'T' && (v == null || v.trim().isEmpty)
                            ? 'Nama pemilik rekening wajib diisi.'
                            : null,
                      ),
                      const SizedBox(height: 20),
                    ],
                    TextFormField(
                      controller: _keteranganController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Keterangan (Opsional)',
                        hintText: 'Tulis catatan penarikan...',
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _submit(pegawai.pegawaiId, saldoTersedia),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'KIRIM PENGAJUAN',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Gagal memuat saldo: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat pegawai: $e')),
      ),
    );
  }

  Widget _buildSaldoHeader(ColorScheme colorScheme, num saldoTersedia) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: colorScheme.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                'INFO SALDO ANDA',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            AppFormatters.rupiah(saldoTersedia),
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hanya saldo berstatus Tersedia (realized) yang dapat diajukan untuk penarikan.',
            style: TextStyle(fontSize: 11, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard({
    required String label,
    required String value,
    required IconData icon,
    required bool selected,
    required ColorScheme colorScheme,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: selected ? 2 : 1,
        ),
      ),
      color: selected ? colorScheme.primary.withValues(alpha: 0.04) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _typePembayaran = value;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
