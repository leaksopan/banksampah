import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/role.dart';
import '../../../data/models/pending_user.dart';
import '../../auth/providers/auth_state_provider.dart';

final pendingUsersProvider = FutureProvider<List<PendingUser>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('mUser')
      .select('User_ID, Email, Nama_Asli, Status_Approval, Tgl_Daftar')
      .eq('Status_Approval', 'PENDING')
      .order('Tgl_Daftar', ascending: true);

  return (response as List<dynamic>)
      .whereType<Map<String, dynamic>>()
      .map(PendingUser.fromJson)
      .toList(growable: false);
});

final approveUserControllerProvider =
    AutoDisposeAsyncNotifierProvider<ApproveUserController, void>(
      ApproveUserController.new,
    );

class ApproveUserController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> approveUser({
    required int userId,
    required String role,
    required String namaPegawai,
    String? nip,
    String? noTelepon,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (role != AppRole.admin && role != AppRole.nasabah) {
        throw const AuthException('Role tidak valid.');
      }

      final client = ref.read(supabaseClientProvider);
      await client.rpc(
        'approve_user',
        params: <String, dynamic>{
          'p_user_id': userId,
          'p_role': role,
          'p_nama_pegawai': namaPegawai,
          'p_nip': nip?.trim().isEmpty ?? true ? null : nip?.trim(),
          'p_no_telepon':
              noTelepon?.trim().isEmpty ?? true ? null : noTelepon?.trim(),
        },
      );

      ref.invalidate(pendingUsersProvider);
      ref.invalidate(appUserProvider);
    });
  }
}
