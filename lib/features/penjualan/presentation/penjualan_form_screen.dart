import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/bank_sampah_models.dart';
import '../../../routing/route_paths.dart';
import '../providers/penjualan_provider.dart';

class PenjualanFormScreen extends ConsumerStatefulWidget {
  const PenjualanFormScreen({super.key});

  @override
  ConsumerState<PenjualanFormScreen> createState() => _PenjualanFormScreenState();
}

class _PenjualanFormScreenState extends ConsumerState<PenjualanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _keteranganController = TextEditingController();
  final List<_DetailInput> _details = [_DetailInput()];
  int? _vendorId;
  int? _lokasiId;
  String _typePembayaran = 'C';

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  num _totalBerat() => _details.fold<num>(0, (total, item) => total + item.qty);

  num _totalNilai() {
    return _details.fold<num>(
      0,
      (total, item) => total + (item.qty * item.hargaJual),
    );
  }

  Future<void> _submit(PenjualanLookups lookups) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedSampahIds = _details.map((detail) => detail.sampahId).toList();
    if (selectedSampahIds.toSet().length != selectedSampahIds.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jenis sampah tidak boleh dobel dalam satu penjualan.'),
        ),
      );
      return;
    }

    final inputDetails = <PenjualanInputDetail>[
      for (final detail in _details)
        PenjualanInputDetail(
          sampahId: detail.sampahId!,
          qty: detail.qty,
          hargaJual: detail.hargaJual,
        ),
    ];

    final created = await ref
        .read(createPenjualanControllerProvider.notifier)
        .submit(
          vendorId: _vendorId!,
          lokasiId: _lokasiId!,
          typePembayaran: _typePembayaran,
          details: inputDetails,
          keterangan: _keteranganController.text,
        );

    if (!mounted || created == null) {
      return;
    }

    final openDetail = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Penjualan terposting'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(created.noBukti),
                const SizedBox(height: 8),
                Text(AppFormatters.kg(created.totalBerat)),
                Text(AppFormatters.rupiah(created.totalNilai)),
                Text('Selisih ${AppFormatters.rupiah(created.totalSelisih)}'),
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
            ? RoutePaths.penjualanDetail(created.noBukti)
            : RoutePaths.penjualan,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lookupsAsync = ref.watch(penjualanLookupsProvider);
    final createState = ref.watch(createPenjualanControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: lookupsAsync.when(
          data:
              (lookups) => Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Kembali',
                          onPressed: () => context.go(RoutePaths.penjualan),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Penjualan Baru',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
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
                      value: _vendorId,
                      decoration: const InputDecoration(
                        labelText: 'Vendor',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final vendor in lookups.vendor)
                          DropdownMenuItem(
                            value: vendor.vendorId,
                            child: Text(
                              vendor.namaVendor,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      validator:
                          (value) => value == null ? 'Vendor wajib dipilih.' : null,
                      onChanged:
                          lookups.vendor.isEmpty
                              ? null
                              : (value) => setState(() => _vendorId = value),
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
                      validator:
                          (value) => value == null ? 'Lokasi wajib dipilih.' : null,
                      onChanged:
                          lookups.lokasi.isEmpty
                              ? null
                              : (value) => setState(() => _lokasiId = value),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'C',
                          label: Text('Cash'),
                          icon: Icon(Icons.payments_rounded),
                        ),
                        ButtonSegment(
                          value: 'T',
                          label: Text('Transfer'),
                          icon: Icon(Icons.account_balance_rounded),
                        ),
                      ],
                      selected: {_typePembayaran},
                      onSelectionChanged:
                          (value) => setState(() => _typePembayaran = value.first),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Rincian Sampah',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Tambah rincian',
                          onPressed:
                              lookups.sampah.isEmpty
                                  ? null
                                  : () =>
                                      setState(() => _details.add(_DetailInput())),
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
                    _TotalBox(totalBerat: _totalBerat(), totalNilai: _totalNilai()),
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
                      onPressed:
                          createState.isLoading || !lookups.isReady
                              ? null
                              : () => _submit(lookups),
                      icon:
                          createState.isLoading
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                              : const Icon(Icons.local_shipping_rounded),
                      label: const Text('Posting Penjualan'),
                    ),
                    if (createState.hasError) ...[
                      const SizedBox(height: 12),
                      Text(
                        createState.error.toString(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          error:
              (error, _) => _LookupLoadError(
                message: error.toString(),
                onRetry: () => ref.invalidate(penjualanLookupsProvider),
              ),
          loading: () => const Center(child: CircularProgressIndicator()),
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
      orElse:
          () => const Sampah(
            sampahId: 0,
            kodeSampah: '',
            namaSampah: '',
            kodeSatuan: 'KG',
            hargaBeli: 0,
            stockAkhir: 0,
            unitBisnisId: 0,
          ),
    );
    final subtotal = detail.qty * detail.hargaJual;

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
                            '${item.namaSampah} - stok ${AppFormatters.kg(item.stockAkhir)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                  ],
                  validator:
                      (value) => value == null ? 'Jenis wajib dipilih.' : null,
                  onChanged:
                      sampah.isEmpty
                          ? null
                          : (value) {
                            detail.sampahId = value;
                            if (value != null) {
                              final selected = sampah.firstWhere(
                                (item) => item.sampahId == value,
                              );
                              detail.hargaJualText =
                                  selected.hargaJual.toString();
                            }
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
              final parsed = _parseNum(value);
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
          TextFormField(
            key: ValueKey('harga-${detail.sampahId}'),
            initialValue:
                detail.hargaJualText.isEmpty && selected.sampahId != 0
                    ? selected.hargaJual.toString()
                    : detail.hargaJualText,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Harga jual per kg',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final parsed = _parseNum(value);
              if (parsed == null || parsed < 0) {
                return 'Harga jual tidak valid.';
              }
              return null;
            },
            onChanged: (value) {
              detail.hargaJualText = value;
              onChanged();
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  selected.sampahId == 0
                      ? 'Stok mengikuti lokasi terpilih'
                      : 'Stok total ${AppFormatters.kg(selected.stockAkhir)}',
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
  const _TotalBox({required this.totalBerat, required this.totalNilai});

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

class _LookupEmptyState extends StatelessWidget {
  const _LookupEmptyState({required this.lookups});

  final PenjualanLookups lookups;

  @override
  Widget build(BuildContext context) {
    final missing = <String>[
      if (lookups.vendor.isEmpty) 'vendor aktif',
      if (lookups.lokasi.isEmpty) 'lokasi/TPS aktif',
      if (lookups.sampah.isEmpty) 'jenis sampah aktif',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Penjualan belum bisa disimpan karena belum ada ${missing.join(', ')}.',
        style: const TextStyle(fontWeight: FontWeight.w700),
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

class _DetailInput {
  int? sampahId;
  String qtyText = '';
  String hargaJualText = '';

  num get qty => _parseNum(qtyText) ?? 0;
  num get hargaJual => _parseNum(hargaJualText) ?? 0;
}

num? _parseNum(String? value) {
  if (value == null) {
    return null;
  }
  return num.tryParse(value.replaceAll(',', '.'));
}
