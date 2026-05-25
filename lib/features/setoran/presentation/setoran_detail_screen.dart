import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../routing/route_paths.dart';
import '../../auth/providers/auth_state_provider.dart';
import '../providers/setoran_provider.dart';

class SetoranDetailScreen extends ConsumerWidget {
  const SetoranDetailScreen({super.key, required this.noBukti});

  final String noBukti;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(setoranDetailProvider(noBukti));
    final user = ref.watch(appUserProvider).valueOrNull;
    final voidState = ref.watch(voidSetoranControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: detailAsync.when(
          data: (data) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Kembali',
                    onPressed: () => context.go(RoutePaths.setoran),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Detail Setoran',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              data.setoran.statusBatal
                  ? _StatusBanner(
                    icon: Icons.block_rounded,
                    message: 'Setoran ini sudah dibatalkan.',
                    color: Theme.of(context).colorScheme.error,
                  )
                  : _StatusBanner(
                    icon: Icons.check_circle_rounded,
                    message: 'Setoran sudah posted.',
                    color: Theme.of(context).colorScheme.primary,
                  ),
              const SizedBox(height: 12),
              _SummaryCard(data: data),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed:
                        () => context.go(RoutePaths.setoranPrint(noBukti)),
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Cetak'),
                  ),
                  if ((user?.isAdmin ?? false) && !data.setoran.statusBatal)
                    OutlinedButton.icon(
                      onPressed:
                          voidState.isLoading
                              ? null
                              : () => _confirmVoid(context, ref),
                      icon:
                          voidState.isLoading
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.block_rounded),
                      label: const Text('VOID'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Rincian',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              for (final item in data.details) ...[
                _DetailRow(
                  namaSampah: item.namaSampah,
                  qty: item.qty,
                  harga: item.hargaBeli,
                  subtotal: item.subtotal,
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
          error: (error, _) => _DetailErrorState(
            message: error.toString(),
            onBack: () => context.go(RoutePaths.setoran),
            onRetry: () => ref.invalidate(setoranDetailProvider(noBukti)),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Future<void> _confirmVoid(BuildContext context, WidgetRef ref) async {
    final keterangan = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => const _VoidSetoranDialog(),
    );

    if (keterangan == null) {
      return;
    }

    final result = await ref
        .read(voidSetoranControllerProvider.notifier)
        .submit(noBukti: noBukti, keterangan: keterangan);

    if (!context.mounted) {
      return;
    }

    final error = ref.read(voidSetoranControllerProvider).error;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Setoran berhasil dibatalkan.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error?.toString() ?? 'VOID setoran gagal.')),
    );
  }
}

class _VoidSetoranDialog extends StatefulWidget {
  const _VoidSetoranDialog();

  @override
  State<_VoidSetoranDialog> createState() => _VoidSetoranDialogState();
}

class _VoidSetoranDialogState extends State<_VoidSetoranDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('VOID Setoran'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Setoran akan dibatalkan dengan reversal saldo pending dan kartu gudang.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Keterangan',
              hintText: 'Opsional',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          icon: const Icon(Icons.block_rounded),
          label: const Text('VOID'),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailErrorState extends StatelessWidget {
  const _DetailErrorState({
    required this.message,
    required this.onBack,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Kembali'),
                ),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final SetoranDetailData data;

  @override
  Widget build(BuildContext context) {
    final setoran = data.setoran;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            setoran.noBukti,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(setoran.namaPegawai),
          const SizedBox(height: 4),
          Text(
            '${setoran.namaLokasi} - ${AppFormatters.shortDate(setoran.tglSetoran)}',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const Divider(height: 26),
          Row(
            children: [
              Expanded(child: Text(AppFormatters.kg(setoran.totalBerat))),
              Text(
                AppFormatters.rupiah(setoran.totalNilai),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.namaSampah,
    required this.qty,
    required this.harga,
    required this.subtotal,
  });

  final String namaSampah;
  final num qty;
  final num harga;
  final num subtotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaSampah,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text('${AppFormatters.kg(qty)} x ${AppFormatters.rupiah(harga)}'),
              ],
            ),
          ),
          Text(
            AppFormatters.rupiah(subtotal),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
