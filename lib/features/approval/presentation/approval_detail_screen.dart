import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/role.dart';
import '../providers/approval_provider.dart';

class ApprovalDetailScreen extends ConsumerStatefulWidget {
  const ApprovalDetailScreen({super.key, required this.userId});

  final int userId;

  @override
  ConsumerState<ApprovalDetailScreen> createState() =>
      _ApprovalDetailScreenState();
}

class _ApprovalDetailScreenState extends ConsumerState<ApprovalDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaPegawaiController = TextEditingController();
  final _nipController = TextEditingController();
  final _noTeleponController = TextEditingController();
  String _selectedRole = AppRole.nasabah;

  @override
  void dispose() {
    _namaPegawaiController.dispose();
    _nipController.dispose();
    _noTeleponController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref
        .read(approveUserControllerProvider.notifier)
        .approveUser(
          userId: widget.userId,
          role: _selectedRole,
          namaPegawai: _namaPegawaiController.text.trim(),
          nip: _nipController.text,
          noTelepon: _noTeleponController.text,
        );

    if (!mounted) {
      return;
    }

    final state = ref.read(approveUserControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approve gagal: ${state.error}')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User berhasil disetujui.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final approveState = ref.watch(approveUserControllerProvider);
    final isSubmitting = approveState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Approval')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              'User_ID: ${widget.userId}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _namaPegawaiController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Pegawai',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama pegawai wajib diisi.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nipController,
                    decoration: const InputDecoration(
                      labelText: 'NIP (opsional)',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noTeleponController,
                    decoration: const InputDecoration(
                      labelText: 'No Telepon (opsional)',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: AppRole.nasabah,
                        label: Text('Nasabah'),
                      ),
                      ButtonSegment<String>(
                        value: AppRole.admin,
                        label: Text('Admin'),
                      ),
                    ],
                    selected: {_selectedRole},
                    onSelectionChanged: (selection) {
                      setState(() => _selectedRole = selection.first);
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSubmitting ? null : _submit,
                      child:
                          isSubmitting
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Approve User'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
