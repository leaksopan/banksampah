import 'package:banksampah/app.dart';
import 'package:banksampah/features/auth/providers/auth_state_provider.dart';
import 'package:banksampah/features/reporting/providers/reporting_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('menampilkan login saat konfigurasi Supabase belum ada', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override agar tidak memanggil Supabase.instance
          supabaseClientProvider.overrideWithValue(
            SupabaseClient(
              'https://jtxquskrulvjafrusbcq.supabase.co',
              'dummy_key',
              authOptions: const AuthClientOptions(autoRefreshToken: false),
            ),
          ),
          appUserProvider.overrideWith((ref) => null),
          authStateChangesProvider.overrideWith((ref) => const Stream<AuthState>.empty()),
          currentUnitBisnisProvider.overrideWith((ref) => null),
        ],
        child: const BankSampahApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bank Sampah Pemda'), findsOneWidget);
    expect(find.text('Masuk dengan Google'), findsOneWidget);
  });
}


