import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/bank_sampah_models.dart';
import '../../../routing/route_paths.dart';
import '../providers/setoran_provider.dart';

class SetoranFormScreen extends ConsumerStatefulWidget {
  const SetoranFormScreen({super.key});

  @override
  ConsumerState<SetoranFormScreen> createState() => _SetoranFormScreenState();
}

class _SetoranFormScreenState extends ConsumerState<SetoranFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _keteranganController = TextEditingController();
  final List<_DetailInput> _details = [_DetailInput()];
  int? _pegawaiId;
  int? _lokasiId;

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  num _totalBerat() {
    return _details.fold<num>(0, (total, item) => total + item.qty);
  }

  num _totalNilai(List<Sampah> sampah) {
    return _details.fold<num>(0, (total, item) {
      final selected = _findSampah(sampah, item.sampahId);
      return total + (selected == null ? 0 : selected.hargaBeli * item.qty);
    });
  }

  Sampah? _findSampah(List<Sampah> sampah, int? sampahId) {
    for (final item in sampah) {
      if (item.sampahId == sampahId) {
        return item;
      }
    }
    return null;
  }

  Future<void> _submit(SetoranLookups lookups) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedSampahIds = _details.map((detail) => detail.sampahId).toList();
    if (selectedSampahIds.toSet().length != selectedSampahIds.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jenis sampah tidak boleh dobel dalam satu setoran.'),
        ),
      );
      return;
    }

    final inputDetails = <SetoranInputDetail>[
      for (final detail in _details)
        SetoranInputDetail(sampahId: detail.sampahId!, qty: detail.qty),
    ];

    final created = await ref
        .read(createSetoranControllerProvider.notifier)
        .submit(
          pegawaiId: _pegawaiId!,
          lokasiId: _lokasiId!,
          details: inputDetails,
          keterangan: _keteranganController.text,
        );

    if (!mounted || created == null) {
      return;
    }

    final openDetail = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setoran tersimpan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(created.noBukti),
            const SizedBox(height: 8),
            Text(AppFormatters.kg(created.totalBerat)),
            Text(AppFormatters.rupiah(created.totalNilai)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tutup'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Detail'),
          ),
        ],
      ),
    );

    if (mounted) {
      context.go(
        openDetail == true
            ? RoutePaths.setoranDetail(created.noBukti)
            : RoutePaths.setoran,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lookupsAsync = ref.watch(setoranLookupsProvider);
    final createState = ref.watch(createSetoranControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: lookupsAsync.when(
          data: (lookups) => Form(
            key: _formKey,
            child: ListView(
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
                        'Setoran Baru',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (!lookups.isReady) ...[
                  _LookupEmptyState(lookups: lookups),
                  const SizedBox(height: 14),
                ],
                DropdownButtonFormField<int>(
                  value: _pegawaiId,
                  decoration: const InputDecoration(
                    labelText: 'Pegawai',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final pegawai in lookups.pegawai)
                      DropdownMenuItem(
                        value: pegawai.pegawaiId,
                        child: Text(
                          pegawai.nip.isEmpty
                              ? pegawai.namaPegawai
                              : '${pegawai.namaPegawai} - ${pegawai.nip}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  validator: (value) =>
                      value == null ? 'Pegawai wajib dipilih.' : null,
                  onChanged: lookups.pegawai.isEmpty
                      ? null
                      : (value) => setState(() => _pegawaiId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _lokasiId,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi/TPS',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final lokasi in lookups.lokasi)
                      DropdownMenuItem(
                        value: lokasi.lokasiId,
                        child: Text(lokasi.namaLokasi),
                      ),
                  ],
                  validator: (value) =>
                      value == null ? 'Lokasi wajib dipilih.' : null,
                  onChanged: lookups.lokasi.isEmpty
                      ? null
                      : (value) => setState(() => _lokasiId = value),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Rincian Sampah',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tambah rincian',
                      onPressed: lookups.sampah.isEmpty
                          ? null
                          : () => setState(() => _details.add(_DetailInput())),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (var index = 0; index < _details.length; index++) ...[
                  _DetailInputCard(
                    key: ValueKey(_details[index]),
                    detail: _details[index],
                    sampah: lookups.sampah,
                    usedSampahIds: {
                      for (var i = 0; i < _details.length; i++)
                        if (i != index && _details[i].sampahId != null)
                          _details[i].sampahId!,
                    },
                    canRemove: _details.length > 1,
                    onChanged: () => setState(() {}),
                    onRemove: () => setState(() => _details.removeAt(index)),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 8),
                _TotalBox(
                  totalBerat: _totalBerat(),
                  totalNilai: _totalNilai(lookups.sampah),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _keteranganController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Keterangan',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: createState.isLoading || !lookups.isReady
                      ? null
                      : () => _submit(lookups),
                  icon: createState.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: const Text('Simpan Setoran'),
                ),
                if (createState.hasError) ...[
                  const SizedBox(height: 12),
                  Text(
                    createState.error.toString(),
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
          error: (error, _) => _LookupLoadError(
            message: error.toString(),
            onRetry: () => ref.invalidate(setoranLookupsProvider),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _LookupEmptyState extends StatelessWidget {
  const _LookupEmptyState({required this.lookups});

  final SetoranLookups lookups;

  @override
  Widget build(BuildContext context) {
    final missing = <String>[
      if (lookups.pegawai.isEmpty) 'pegawai aktif',
      if (lookups.lokasi.isEmpty) 'lokasi/TPS aktif',
      if (lookups.sampah.isEmpty) 'jenis sampah aktif',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Setoran belum bisa disimpan karena belum ada ${missing.join(', ')}.',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _LookupLoadError extends StatelessWidget {
  const _LookupLoadError({required this.message, required this.onRetry});

  final String message;
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
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailInputCard extends StatelessWidget {
  const _DetailInputCard({
    super.key,
    required this.detail,
    required this.sampah,
    required this.usedSampahIds,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final _DetailInput detail;
  final List<Sampah> sampah;
  final Set<int> usedSampahIds;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final selected = sampah.firstWhere(
      (item) => item.sampahId == detail.sampahId,
      orElse: () => const Sampah(
        sampahId: 0,
        kodeSampah: '',
        namaSampah: '',
        kodeSatuan: 'KG',
        hargaBeli: 0,
        stockAkhir: 0,
        unitBisnisId: 0,
      ),
    );
    final subtotal = selected.hargaBeli * detail.qty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: detail.sampahId,
                  decoration: const InputDecoration(
                    labelText: 'Jenis sampah',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final item in sampah)
                      if (!usedSampahIds.contains(item.sampahId) ||
                          item.sampahId == detail.sampahId)
                        DropdownMenuItem(
                          value: item.sampahId,
                          child: Text(
                            '${item.namaSampah} (${AppFormatters.rupiah(item.hargaBeli)})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                  ],
                  validator: (value) =>
                      value == null ? 'Jenis wajib dipilih.' : null,
                  onChanged: sampah.isEmpty
                      ? null
                      : (value) {
                          detail.sampahId = value;
                          onChanged();
                        },
                ),
              ),
              if (canRemove) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Hapus rincian',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: detail.qtyText,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Qty (kg)',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final parsed = _parseQty(value);
              if (parsed == null || parsed <= 0) {
                return 'Qty harus lebih dari 0.';
              }
              return null;
            },
            onChanged: (value) {
              detail.qtyText = value;
              onChanged();
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  selected.sampahId == 0
                      ? 'Harga otomatis'
                      : AppFormatters.rupiah(selected.hargaBeli),
                ),
              ),
              Text(
                AppFormatters.rupiah(subtotal),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalBox extends StatelessWidget {
  const _TotalBox({
    required this.totalBerat,
    required this.totalNilai,
  });

  final num totalBerat;
  final num totalNilai;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppFormatters.kg(totalBerat),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            AppFormatters.rupiah(totalNilai),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _DetailInput {
  int? sampahId;
  String qtyText = '';

  num get qty => _parseQty(qtyText) ?? 0;
}

num? _parseQty(String? value) {
  if (value == null) {
    return null;
  }
  return num.tryParse(value.replaceAll(',', '.'));
}
