import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/bank_sampah_models.dart';
import '../../../data/repositories/bank_sampah_repository.dart';
import '../../../routing/route_paths.dart';
import '../../auth/providers/auth_state_provider.dart';
import '../providers/penarikan_provider.dart';

final sesamaPegawaiProvider = FutureProvider.autoDispose<List<Pegawai>>((ref) async {
  final repo = ref.watch(bankSampahRepositoryProvider);
  final currentPegawai = await ref.watch(currentPegawaiProvider.future);
  if (currentPegawai == null) return [];
  return repo.listSesamaPegawai(
    unitBisnisId: currentPegawai.unitBisnisId,
    excludePegawaiId: currentPegawai.pegawaiId,
  );
});

final currentPegawaiSaldoProvider = FutureProvider.autoDispose<SaldoPegawai>((ref) async {
  final repo = ref.watch(bankSampahRepositoryProvider);
  final currentPegawai = await ref.watch(currentPegawaiProvider.future);
  if (currentPegawai == null) return SaldoPegawai.empty(0);
  return repo.getSaldoPegawai(currentPegawai.pegawaiId);
});

class TransferSaldoScreen extends ConsumerStatefulWidget {
  const TransferSaldoScreen({super.key});

  @override
  ConsumerState<TransferSaldoScreen> createState() => _TransferSaldoScreenState();
}

class _TransferScreenStateController {
  bool isLoading = false;
  String? errorMessage;
}

final transferStateProvider = StateProvider.autoDispose<_TransferScreenStateController>((ref) {
  return _TransferScreenStateController();
});

class _TransferSaldoScreenState extends ConsumerState<TransferSaldoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahController = TextEditingController();
  final _keteranganController = TextEditingController();
  Pegawai? _selectedPenerima;

  @override
  void dispose() {
    _jumlahController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _executeTransfer(num saldoTersedia, Pegawai pengirim, WidgetRef ref) async {
    if (!_formKey.currentState!.validate() || _selectedPenerima == null) {
      return;
    }

    final double jumlah = double.tryParse(_jumlahController.text) ?? 0.0;
    if (jumlah > saldoTersedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saldo tersedia tidak mencukupi untuk transfer.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Transfer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Apakah Anda yakin ingin melakukan transfer saldo ini?'),
            const SizedBox(height: 14),
            Text('Penerima: ${_selectedPenerima!.namaPegawai}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Jumlah: ${AppFormatters.rupiah(jumlah)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            if (_keteranganController.text.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Keterangan: ${_keteranganController.text}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      ref.read(transferStateProvider.notifier).state.isLoading = true;
      ref.read(transferStateProvider.notifier).state.errorMessage = null;
    });

    try {
      final appUser = await ref.read(appUserProvider.future);
      await ref.read(bankSampahRepositoryProvider).executeTransferSaldo(
            pengirimPegawaiId: pengirim.pegawaiId,
            penerimaPegawaiId: _selectedPenerima!.pegawaiId,
            jumlah: jumlah,
            keterangan: _keteranganController.text,
            unitBisnisId: pengirim.unitBisnisId,
            userId: appUser?.userId,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Berhasil transfer ke ${_selectedPenerima!.namaPegawai}!')),
        );
        ref.invalidate(currentPegawaiSaldoProvider);
        context.go(RoutePaths.dashboard);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          ref.read(transferStateProvider.notifier).state.isLoading = false;
          ref.read(transferStateProvider.notifier).state.errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sesamaAsync = ref.watch(sesamaPegawaiProvider);
    final saldoAsync = ref.watch(currentPegawaiSaldoProvider);
    final currentPegawaiAsync = ref.watch(currentPegawaiProvider);
    final transferState = ref.watch(transferStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transfer Saldo',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(RoutePaths.dashboard),
        ),
      ),
      body: currentPegawaiAsync.when(
        data: (pengirim) {
          if (pengirim == null) {
            return const Center(child: Text('Profil nasabah tidak ditemukan.'));
          }

          return saldoAsync.when(
            data: (saldo) {
              final saldoTersedia = saldo.saldoTersedia;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
                children: [
                  _buildSaldoCard(saldoTersedia, colorScheme),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FORM TRANSFER SALDO INTERNAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 18),
                            sesamaAsync.when(
                              data: (penerimaList) {
                                if (penerimaList.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      'Tidak ada nasabah penerima sesama OPD yang terdaftar.',
                                      style: TextStyle(color: Colors.red, fontSize: 12),
                                    ),
                                  );
                                }

                                return DropdownButtonFormField<Pegawai>(
                                  decoration: InputDecoration(
                                    labelText: 'Pilih Penerima',
                                    prefixIcon: const Icon(Icons.person_outline_rounded),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  value: _selectedPenerima,
                                  validator: (value) => value == null ? 'Penerima wajib dipilih.' : null,
                                  items: [
                                    for (final item in penerimaList)
                                      DropdownMenuItem(
                                        value: item,
                                        child: Text(item.namaPegawai),
                                      ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedPenerima = value;
                                    });
                                  },
                                );
                              },
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) => Text('Gagal memuat penerima: $e', style: const TextStyle(color: Colors.red)),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _jumlahController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Jumlah Transfer (Rp)',
                                prefixIcon: const Icon(Icons.payments_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Jumlah transfer wajib diisi.';
                                }
                                final parsed = double.tryParse(value);
                                if (parsed == null || parsed <= 0) {
                                  return 'Jumlah transfer wajib lebih dari Rp 0.';
                                }
                                if (parsed > saldoTersedia) {
                                  return 'Saldo tidak mencukupi (Tersedia: ${AppFormatters.rupiah(saldoTersedia)}).';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _keteranganController,
                              decoration: InputDecoration(
                                labelText: 'Keterangan (Opsional)',
                                prefixIcon: const Icon(Icons.chat_bubble_outline_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              maxLength: 200,
                            ),
                            if (transferState.errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Gagal transfer: ${transferState.errorMessage}',
                                style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: FilledButton.icon(
                                onPressed: transferState.isLoading
                                    ? null
                                    : () => _executeTransfer(saldoTersedia, pengirim, ref),
                                icon: transferState.isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.send_rounded),
                                label: const Text(
                                  'Kirim Transfer',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                ),
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Gagal memuat saldo: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat profil: $e')),
      ),
    );
  }

  Widget _buildSaldoCard(num saldoTersedia, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF55CFA1)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Saldo Tersedia Anda',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AppFormatters.rupiah(saldoTersedia),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hanya saldo tersedia yang dapat ditransfer ke sesama nasabah.',
            style: TextStyle(color: Colors.white60, fontSize: 10, height: 1.3),
          ),
        ],
      ),
    );
  }
}
