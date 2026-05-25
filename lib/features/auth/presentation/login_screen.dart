import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../providers/auth_state_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  String _resolveRedirectTo() {
    if (!kIsWeb) {
      return 'banksampah://login-callback';
    }

    final base = Uri.base;
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: '/',
    ).toString();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _resolveRedirectTo(),
        authScreenLaunchMode:
            kIsWeb
                ? LaunchMode.platformDefault
                : LaunchMode.externalApplication,
      );
    } on AuthException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Login Google gagal. Coba lagi.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.recycling_rounded,
                  size: 56,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Bank Sampah Pemda',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masuk memakai akun Google untuk melanjutkan.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed:
                      _isLoading || !Env.hasSupabaseConfig
                          ? null
                          : _signInWithGoogle,
                  icon:
                      _isLoading
                          ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.login_rounded),
                  label: const Text('Masuk dengan Google'),
                ),
                if (!Env.hasSupabaseConfig) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Konfigurasi Supabase belum tersedia. Jalankan dengan '
                    '--dart-define=SUPABASE_URL=... dan '
                    '--dart-define=SUPABASE_PUBLISHABLE_KEY=...',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
