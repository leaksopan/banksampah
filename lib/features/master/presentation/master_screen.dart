import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/bank_sampah_models.dart';
import '../providers/master_provider.dart';

class MasterScreen extends ConsumerStatefulWidget {
  const MasterScreen({super.key});

  @override
  ConsumerState<MasterScreen> createState() => _MasterScreenState();
}

class _MasterScreenState extends ConsumerState<MasterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openCurrentForm() async {
    if (_tabController.index == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pegawai baru dibuat dari menu Approval User.'),
        ),
      );
      return;
    }

    if (_tabController.index == 1) {
      await _openSampahDialog();
      return;
    }

    if (_tabController.index == 2) {
      await _openLokasiDialog();
      return;
    }

    await _openVendorDialog();
  }

  Future<void> _openPegawaiDialog(Pegawai pegawai) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _PegawaiDialog(pegawai: pegawai),
    );
    if (saved == true && mounted) {
      _showSavedSnackBar('Pegawai tersimpan.');
    }
  }

  Future<void> _openLokasiDialog({Lokasi? lokasi}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _LokasiDialog(lokasi: lokasi),
    );
    if (saved == true && mounted) {
      _showSavedSnackBar('Lokasi tersimpan.');
    }
  }

  Future<void> _openSampahDialog({Sampah? sampah}) async {
    final kategori = await ref.read(masterKategoriProvider.future);
    final satuan = await ref.read(masterSatuanProvider.future);
    if (!mounted) {
      return;
    }

    if (kategori.isEmpty || satuan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori dan satuan wajib tersedia sebelum input sampah.'),
        ),
      );
      return;
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _SampahDialog(
        sampah: sampah,
        kategori: kategori,
        satuan: satuan,
      ),
    );
    if (saved == true && mounted) {
      _showSavedSnackBar('Sampah tersimpan.');
    }
  }

  Future<void> _openVendorDialog({Vendor? vendor}) async {
    final kategori = await ref.read(masterKategoriVendorProvider.future);
    if (!mounted) {
      return;
    }

    if (kategori.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori vendor wajib tersedia sebelum input vendor.'),
        ),
      );
      return;
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _VendorDialog(
        vendor: vendor,
        kategori: kategori,
      ),
    );
    if (saved == true && mounted) {
      _showSavedSnackBar('Vendor tersimpan.');
    }
  }

  void _showSavedSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openBulkImportDialog() async {
    final importedCount = await showDialog<int>(
      context: context,
      builder: (context) => const _BulkImportDialog(),
    );
    if (importedCount != null && mounted) {
      _showSavedSnackBar('Berhasil mengimport $importedCount pegawai.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fabIcon =
        _tabController.index == 0 ? Icons.info_outline_rounded : Icons.add_rounded;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Master Data',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (_tabController.index == 0)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _openBulkImportDialog,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Bulk Import'),
                    ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Pegawai'),
                Tab(text: 'Sampah'),
                Tab(text: 'Lokasi'),
                Tab(text: 'Vendor'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _PegawaiTab(onEdit: _openPegawaiDialog),
                  _SampahTab(onEdit: (item) => _openSampahDialog(sampah: item)),
                  _LokasiTab(onEdit: (item) => _openLokasiDialog(lokasi: item)),
                  _VendorTab(onEdit: (item) => _openVendorDialog(vendor: item)),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: _tabController.index == 0 ? 'Info pegawai' : 'Tambah master',
        onPressed: _openCurrentForm,
        child: Icon(fabIcon),
      ),
    );
  }
}

class _PegawaiTab extends ConsumerWidget {
  const _PegawaiTab({required this.onEdit});

  final ValueChanged<Pegawai> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(masterPegawaiProvider);
    return _AsyncList<Pegawai>(
      value: data,
      onRefresh: () => ref.invalidate(masterPegawaiProvider),
      emptyIcon: Icons.people_outline_rounded,
      emptyText: 'Belum ada pegawai aktif.',
      itemBuilder: (item) => _MasterTile(
        title: item.namaPegawai,
        subtitle: item.nip.isEmpty ? item.email : '${item.nip} - ${item.email}',
        trailing: _StatusChip(active: item.statusAktif),
        onTap: () => onEdit(item),
      ),
    );
  }
}

class _SampahTab extends ConsumerWidget {
  const _SampahTab({required this.onEdit});

  final ValueChanged<Sampah> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(masterSampahProvider);
    return _AsyncList<Sampah>(
      value: data,
      onRefresh: () => ref.invalidate(masterSampahProvider),
      emptyIcon: Icons.recycling_rounded,
      emptyText: 'Belum ada jenis sampah.',
      itemBuilder: (item) => _MasterTile(
        title: item.namaSampah,
        subtitle:
            '${item.kodeSampah} - ${AppFormatters.rupiah(item.hargaBeli)} / ${item.kodeSatuan}',
        trailing: _StatusChip(active: item.aktif),
        onTap: () => onEdit(item),
      ),
    );
  }
}

class _LokasiTab extends ConsumerWidget {
  const _LokasiTab({required this.onEdit});

  final ValueChanged<Lokasi> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(masterLokasiProvider);
    return _AsyncList<Lokasi>(
      value: data,
      onRefresh: () => ref.invalidate(masterLokasiProvider),
      emptyIcon: Icons.warehouse_rounded,
      emptyText: 'Belum ada lokasi/TPS.',
      itemBuilder: (item) => _MasterTile(
        title: item.namaLokasi,
        subtitle: item.tipeLokasi.isEmpty
            ? item.kodeLokasi
            : '${item.kodeLokasi} - ${item.tipeLokasi}',
        trailing: _StatusChip(active: item.statusAktif),
        onTap: () => onEdit(item),
      ),
    );
  }
}

class _VendorTab extends ConsumerWidget {
  const _VendorTab({required this.onEdit});

  final ValueChanged<Vendor> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(masterVendorProvider);
    return _AsyncList<Vendor>(
      value: data,
      onRefresh: () => ref.invalidate(masterVendorProvider),
      emptyIcon: Icons.storefront_rounded,
      emptyText: 'Belum ada vendor.',
      itemBuilder: (item) => _MasterTile(
        title: item.namaVendor,
        subtitle: [
          item.kodeVendor,
          if (item.namaKategori.isNotEmpty) item.namaKategori,
          if (item.noTelepon.isNotEmpty) item.noTelepon,
        ].join(' - '),
        trailing: _StatusChip(active: item.statusAktif),
        onTap: () => onEdit(item),
      ),
    );
  }
}

class _AsyncList<T> extends StatelessWidget {
  const _AsyncList({
    required this.value,
    required this.onRefresh,
    required this.emptyIcon,
    required this.emptyText,
    required this.itemBuilder,
  });

  final AsyncValue<List<T>> value;
  final VoidCallback onRefresh;
  final IconData emptyIcon;
  final String emptyText;
  final Widget Function(T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: value.when(
        data: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
          children: [
            if (items.isEmpty)
              _EmptyBox(icon: emptyIcon, text: emptyText)
            else
              for (final item in items) ...[
                itemBuilder(item),
                const SizedBox(height: 10),
              ],
          ],
        ),
        error: (error, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 112),
          children: [
            _ErrorBox(message: error.toString(), onRetry: onRefresh),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _MasterTile extends StatelessWidget {
  const _MasterTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle.isEmpty ? '-' : subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? colorScheme.primaryContainer : colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Aktif' : 'Nonaktif',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _PegawaiDialog extends ConsumerStatefulWidget {
  const _PegawaiDialog({required this.pegawai});

  final Pegawai pegawai;

  @override
  ConsumerState<_PegawaiDialog> createState() => _PegawaiDialogState();
}

class _PegawaiDialogState extends ConsumerState<_PegawaiDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaController;
  late final TextEditingController _nipController;
  late final TextEditingController _teleponController;
  late final TextEditingController _emailController;
  late bool _statusAktif;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.pegawai.namaPegawai);
    _nipController = TextEditingController(text: widget.pegawai.nip);
    _teleponController = TextEditingController(text: widget.pegawai.noTelepon);
    _emailController = TextEditingController(text: widget.pegawai.email);
    _statusAktif = widget.pegawai.statusAktif;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nipController.dispose();
    _teleponController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final saved = await ref.read(saveMasterControllerProvider.notifier).savePegawai(
          pegawaiId: widget.pegawai.pegawaiId,
          namaPegawai: _namaController.text,
          nip: _nipController.text,
          noTelepon: _teleponController.text,
          email: _emailController.text,
          statusAktif: _statusAktif,
        );
    if (saved && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saveState = ref.watch(saveMasterControllerProvider);
    return AlertDialog(
      title: const Text('Edit Pegawai'),
      content: _DialogBody(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RequiredTextField(
                controller: _namaController,
                label: 'Nama Pegawai',
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nipController,
                decoration: const InputDecoration(
                  labelText: 'NIP',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _teleponController,
                decoration: const InputDecoration(
                  labelText: 'No Telepon',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Aktif'),
                value: _statusAktif,
                onChanged: (value) => setState(() => _statusAktif = value),
              ),
              if (saveState.hasError)
                _DialogError(message: saveState.error.toString()),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saveState.isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: saveState.isLoading ? null : _save,
          icon: saveState.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _LokasiDialog extends ConsumerStatefulWidget {
  const _LokasiDialog({this.lokasi});

  final Lokasi? lokasi;

  @override
  ConsumerState<_LokasiDialog> createState() => _LokasiDialogState();
}

class _LokasiDialogState extends ConsumerState<_LokasiDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kodeController;
  late final TextEditingController _namaController;
  late final TextEditingController _tipeController;
  late final TextEditingController _alamatController;
  late bool _gudangUtama;
  late bool _statusAktif;

  @override
  void initState() {
    super.initState();
    final lokasi = widget.lokasi;
    _kodeController = TextEditingController(text: lokasi?.kodeLokasi ?? '');
    _namaController = TextEditingController(text: lokasi?.namaLokasi ?? '');
    _tipeController = TextEditingController(text: lokasi?.tipeLokasi ?? 'TPS');
    _alamatController = TextEditingController(text: lokasi?.alamat ?? '');
    _gudangUtama = lokasi?.gudangUtama ?? false;
    _statusAktif = lokasi?.statusAktif ?? true;
  }

  @override
  void dispose() {
    _kodeController.dispose();
    _namaController.dispose();
    _tipeController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final saved = await ref.read(saveMasterControllerProvider.notifier).saveLokasi(
          lokasiId: widget.lokasi?.lokasiId,
          kodeLokasi: _kodeController.text,
          namaLokasi: _namaController.text,
          tipeLokasi: _tipeController.text,
          alamat: _alamatController.text,
          gudangUtama: _gudangUtama,
          statusAktif: _statusAktif,
        );
    if (saved && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saveState = ref.watch(saveMasterControllerProvider);
    return AlertDialog(
      title: Text(widget.lokasi == null ? 'Tambah Lokasi' : 'Edit Lokasi'),
      content: _DialogBody(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RequiredTextField(
                controller: _kodeController,
                label: 'Kode Lokasi',
              ),
              const SizedBox(height: 10),
              _RequiredTextField(
                controller: _namaController,
                label: 'Nama Lokasi',
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _tipeController,
                decoration: const InputDecoration(
                  labelText: 'Tipe Lokasi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _alamatController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  border: OutlineInputBorder(),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Gudang utama'),
                value: _gudangUtama,
                onChanged: (value) => setState(() => _gudangUtama = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Aktif'),
                value: _statusAktif,
                onChanged: (value) => setState(() => _statusAktif = value),
              ),
              if (saveState.hasError)
                _DialogError(message: saveState.error.toString()),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saveState.isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: saveState.isLoading ? null : _save,
          icon: saveState.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _SampahDialog extends ConsumerStatefulWidget {
  const _SampahDialog({
    required this.kategori,
    required this.satuan,
    this.sampah,
  });

  final Sampah? sampah;
  final List<Kategori> kategori;
  final List<Satuan> satuan;

  @override
  ConsumerState<_SampahDialog> createState() => _SampahDialogState();
}

class _SampahDialogState extends ConsumerState<_SampahDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kodeController;
  late final TextEditingController _namaController;
  late final TextEditingController _hargaBeliController;
  late final TextEditingController _hargaJualController;
  late final TextEditingController _minStockController;
  late int _kategoriId;
  late String _kodeSatuan;
  late bool _aktif;

  @override
  void initState() {
    super.initState();
    final sampah = widget.sampah;
    _kodeController = TextEditingController(text: sampah?.kodeSampah ?? '');
    _namaController = TextEditingController(text: sampah?.namaSampah ?? '');
    _hargaBeliController = TextEditingController(
      text: sampah == null ? '' : sampah.hargaBeli.toString(),
    );
    _hargaJualController = TextEditingController(
      text: sampah == null ? '' : sampah.hargaJual.toString(),
    );
    _minStockController = TextEditingController(
      text: sampah == null ? '0' : sampah.minStock.toString(),
    );
    _kategoriId = sampah?.kategoriId ?? widget.kategori.first.kategoriId;
    _kodeSatuan = sampah?.kodeSatuan ?? widget.satuan.first.kodeSatuan;
    _aktif = sampah?.aktif ?? true;
  }

  @override
  void dispose() {
    _kodeController.dispose();
    _namaController.dispose();
    _hargaBeliController.dispose();
    _hargaJualController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final saved = await ref.read(saveMasterControllerProvider.notifier).saveSampah(
          sampahId: widget.sampah?.sampahId,
          kodeSampah: _kodeController.text,
          namaSampah: _namaController.text,
          kategoriId: _kategoriId,
          kodeSatuan: _kodeSatuan,
          hargaBeli: _parseNum(_hargaBeliController.text),
          hargaJual: _parseNum(_hargaJualController.text),
          minStock: _parseNum(_minStockController.text),
          aktif: _aktif,
        );
    if (saved && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saveState = ref.watch(saveMasterControllerProvider);
    return AlertDialog(
      title: Text(widget.sampah == null ? 'Tambah Sampah' : 'Edit Sampah'),
      content: _DialogBody(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RequiredTextField(
                controller: _kodeController,
                label: 'Kode Sampah',
              ),
              const SizedBox(height: 10),
              _RequiredTextField(
                controller: _namaController,
                label: 'Nama Sampah',
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: _kategoriId,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final item in widget.kategori)
                    DropdownMenuItem(
                      value: item.kategoriId,
                      child: Text(item.namaKategori),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _kategoriId = value);
                  }
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _kodeSatuan,
                decoration: const InputDecoration(
                  labelText: 'Satuan',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final item in widget.satuan)
                    DropdownMenuItem(
                      value: item.kodeSatuan,
                      child: Text('${item.kodeSatuan} - ${item.namaSatuan}'),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _kodeSatuan = value);
                  }
                },
              ),
              const SizedBox(height: 10),
              _NumberTextField(
                controller: _hargaBeliController,
                label: 'Harga Beli',
              ),
              const SizedBox(height: 10),
              _NumberTextField(
                controller: _hargaJualController,
                label: 'Harga Jual',
              ),
              const SizedBox(height: 10),
              _NumberTextField(
                controller: _minStockController,
                label: 'Min Stock',
                allowZero: true,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Aktif'),
                value: _aktif,
                onChanged: (value) => setState(() => _aktif = value),
              ),
              if (saveState.hasError)
                _DialogError(message: saveState.error.toString()),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saveState.isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: saveState.isLoading ? null : _save,
          icon: saveState.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _VendorDialog extends ConsumerStatefulWidget {
  const _VendorDialog({
    required this.kategori,
    this.vendor,
  });

  final Vendor? vendor;
  final List<KategoriVendor> kategori;

  @override
  ConsumerState<_VendorDialog> createState() => _VendorDialogState();
}

class _VendorDialogState extends ConsumerState<_VendorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kodeController;
  late final TextEditingController _namaController;
  late final TextEditingController _alamatController;
  late final TextEditingController _teleponController;
  late final TextEditingController _emailController;
  late final TextEditingController _npwpController;
  late final TextEditingController _atasNamaController;
  late final TextEditingController _bankController;
  late final TextEditingController _noRekController;
  late String _kodeKategori;
  late bool _statusAktif;

  @override
  void initState() {
    super.initState();
    final vendor = widget.vendor;
    _kodeController = TextEditingController(text: vendor?.kodeVendor ?? '');
    _namaController = TextEditingController(text: vendor?.namaVendor ?? '');
    _alamatController = TextEditingController(text: vendor?.alamat ?? '');
    _teleponController = TextEditingController(text: vendor?.noTelepon ?? '');
    _emailController = TextEditingController(text: vendor?.alamatEmail ?? '');
    _npwpController = TextEditingController(text: vendor?.noNpwp ?? '');
    _atasNamaController = TextEditingController(text: vendor?.atasNama ?? '');
    _bankController = TextEditingController(text: vendor?.bank ?? '');
    _noRekController = TextEditingController(text: vendor?.noRek ?? '');
    final vendorKategori = vendor?.kodeKategori;
    _kodeKategori =
        widget.kategori.any((item) => item.kodeKategori == vendorKategori)
            ? vendorKategori!
            : widget.kategori.first.kodeKategori;
    _statusAktif = vendor?.statusAktif ?? true;
  }

  @override
  void dispose() {
    _kodeController.dispose();
    _namaController.dispose();
    _alamatController.dispose();
    _teleponController.dispose();
    _emailController.dispose();
    _npwpController.dispose();
    _atasNamaController.dispose();
    _bankController.dispose();
    _noRekController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final saved = await ref.read(saveMasterControllerProvider.notifier).saveVendor(
          vendorId: widget.vendor?.vendorId,
          kodeVendor: _kodeController.text,
          namaVendor: _namaController.text,
          kodeKategori: _kodeKategori,
          alamat: _alamatController.text,
          noTelepon: _teleponController.text,
          alamatEmail: _emailController.text,
          noNpwp: _npwpController.text,
          atasNama: _atasNamaController.text,
          bank: _bankController.text,
          noRek: _noRekController.text,
          statusAktif: _statusAktif,
        );
    if (saved && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saveState = ref.watch(saveMasterControllerProvider);
    return AlertDialog(
      title: Text(widget.vendor == null ? 'Tambah Vendor' : 'Edit Vendor'),
      content: _DialogBody(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RequiredTextField(
                controller: _kodeController,
                label: 'Kode Vendor',
              ),
              const SizedBox(height: 10),
              _RequiredTextField(
                controller: _namaController,
                label: 'Nama Vendor',
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _kodeKategori,
                decoration: const InputDecoration(
                  labelText: 'Kategori Vendor',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final item in widget.kategori)
                    DropdownMenuItem(
                      value: item.kodeKategori,
                      child: Text('${item.kodeKategori} - ${item.kategoriName}'),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _kodeKategori = value);
                  }
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _alamatController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _teleponController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'No Telepon',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _npwpController,
                decoration: const InputDecoration(
                  labelText: 'No NPWP',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _atasNamaController,
                decoration: const InputDecoration(
                  labelText: 'Atas Nama',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _bankController,
                decoration: const InputDecoration(
                  labelText: 'Bank',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _noRekController,
                decoration: const InputDecoration(
                  labelText: 'No Rekening',
                  border: OutlineInputBorder(),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Aktif'),
                value: _statusAktif,
                onChanged: (value) => setState(() => _statusAktif = value),
              ),
              if (saveState.hasError)
                _DialogError(message: saveState.error.toString()),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saveState.isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: saveState.isLoading ? null : _save,
          icon: saveState.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _DialogBody extends StatelessWidget {
  const _DialogBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: SingleChildScrollView(child: child),
    );
  }
}

class _RequiredTextField extends StatelessWidget {
  const _RequiredTextField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label wajib diisi.';
        }
        return null;
      },
    );
  }
}

class _NumberTextField extends StatelessWidget {
  const _NumberTextField({
    required this.controller,
    required this.label,
    this.allowZero = false,
  });

  final TextEditingController controller;
  final String label;
  final bool allowZero;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final parsed = _tryParseNum(value);
        if (parsed == null || parsed < 0 || (!allowZero && parsed == 0)) {
          return allowZero ? '$label minimal 0.' : '$label harus lebih dari 0.';
        }
        return null;
      },
    );
  }
}

class _DialogError extends StatelessWidget {
  const _DialogError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36),
          const SizedBox(height: 10),
          Text(text),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}

num _parseNum(String value) {
  return _tryParseNum(value) ?? 0;
}

num? _tryParseNum(String? value) {
  if (value == null) {
    return null;
  }
  return num.tryParse(value.replaceAll(',', '.'));
}

class _BulkImportDialog extends ConsumerStatefulWidget {
  const _BulkImportDialog();

  @override
  ConsumerState<_BulkImportDialog> createState() => _BulkImportDialogState();
}

class _BulkImportDialogState extends ConsumerState<_BulkImportDialog> {
  final _jsonController = TextEditingController(
    text: '[\n'
        '  {\n'
        '    "nama_pegawai": "Pegawai DLH Baru",\n'
        '    "nip": "199505052026052002",\n'
        '    "email": "pegawai.dlh@badung.go.id",\n'
        '    "no_telepon": "081223344556"\n'
        '  }\n'
        ']',
  );

  int? _selectedUnitBisnisId;
  String? _parseError;

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _parseError = null;
    });

    if (_selectedUnitBisnisId == null) {
      setState(() {
        _parseError = 'Wajib memilih OPD tujuan.';
      });
      return;
    }

    List<dynamic> parsedList;
    try {
      final decoded = json.decode(_jsonController.text);
      if (decoded is! List) {
        throw const FormatException('JSON harus berupa list/array.');
      }
      parsedList = decoded;
    } catch (e) {
      setState(() {
        _parseError = 'Format JSON tidak valid: ${e.toString()}';
      });
      return;
    }

    final listMap = <Map<String, dynamic>>[];
    for (final item in parsedList) {
      if (item is Map) {
        listMap.add(Map<String, dynamic>.from(item));
      } else {
        setState(() {
          _parseError = 'Tiap baris pegawai wajib berupa object/map.';
        });
        return;
      }
    }

    if (listMap.isEmpty) {
      setState(() {
        _parseError = 'Data pegawai kosong.';
      });
      return;
    }

    final response = await ref.read(saveMasterControllerProvider.notifier).bulkImportPegawai(
          unitBisnisId: _selectedUnitBisnisId!,
          pegawaiList: listMap,
        );

    if (response != null && mounted) {
      final bool ok = response['ok'] as bool? ?? false;
      final int importedCount = response['imported_count'] as int? ?? 0;
      if (ok) {
        Navigator.of(context).pop(importedCount);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final saveState = ref.watch(saveMasterControllerProvider);
    final unitBisnisListAsync = ref.watch(masterUnitBisnisProvider);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.upload_file_rounded, color: Colors.green),
          SizedBox(width: 8),
          Text('Bulk Import Pegawai'),
        ],
      ),
      content: _DialogBody(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Import data pegawai secara massal menggunakan format JSON array.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            unitBisnisListAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Text('Tidak ada OPD aktif.');
                }
                if (_selectedUnitBisnisId == null && list.isNotEmpty) {
                  // Default ke BKPSDM (1) atau DLH (2) jika ada
                  final hasBkpsdm = list.any((el) => el.unitBisnisId == 1);
                  _selectedUnitBisnisId = hasBkpsdm ? 1 : list.first.unitBisnisId;
                }
                return DropdownButtonFormField<int>(
                  value: _selectedUnitBisnisId,
                  decoration: const InputDecoration(
                    labelText: 'Pilih OPD Tujuan',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final u in list)
                      DropdownMenuItem(
                        value: u.unitBisnisId,
                        child: Text(u.unitBisnisName),
                      ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedUnitBisnisId = val);
                    }
                  },
                );
              },
              error: (err, _) => _DialogError(message: err.toString()),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 16),
            const Text(
              'Data Pegawai (JSON List):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _jsonController,
              maxLines: 8,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Masukkan JSON array pegawai...',
              ),
            ),
            if (_parseError != null) ...[
              const SizedBox(height: 10),
              _DialogError(message: _parseError!),
            ],
            if (saveState.hasError) ...[
              const SizedBox(height: 10),
              _DialogError(message: saveState.error.toString()),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: saveState.isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: saveState.isLoading ? null : _submit,
          icon: saveState.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded),
          label: const Text('Import Sekarang'),
        ),
      ],
    );
  }
}
