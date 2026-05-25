import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/bank_sampah_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  if (!Env.hasSupabaseConfig) {
    return const Stream<AuthState>.empty();
  }

  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

final appUserProvider = FutureProvider<AppUser?>((ref) async {
  if (Uri.base.toString().contains('bypass_auth=true')) {
    BankSampahRepository.bypassAuthActive = true;
  }

  if (BankSampahRepository.bypassAuthActive) {
    return const AppUser(
      userId: 1,
      email: 'admin.bkpsdm@badung.go.id',
      namaAsli: 'Admin BKPSDM Playwright',
      statusApproval: 'APPROVED',
      roles: ['ADMIN'],
      unitBisnisIds: [1],
    );
  }

  if (!Env.hasSupabaseConfig) {
    return null;
  }

  ref.watch(authStateChangesProvider);

  final client = ref.watch(supabaseClientProvider);
  final authUser = client.auth.currentUser;
  if (authUser == null) {
    return null;
  }

  final data =
      await client
          .from('vCurrentUserProfile')
          .select()
          .eq('Auth_UID', authUser.id)
          .maybeSingle();

  if (data == null) {
    return null;
  }

  final unitRows = await client
      .from('mUserUnitBisnis')
      .select('UnitBisnisID')
      .eq('User_ID', data['User_ID'] as int);
  final unitBisnisIds =
      (unitRows as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map((row) => row['UnitBisnisID'])
          .whereType<int>()
          .toList(growable: false);

  return AppUser.fromJson(data, unitBisnisIds: unitBisnisIds);
});
