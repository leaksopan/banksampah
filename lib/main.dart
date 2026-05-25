import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/utils/oauth_url_cleaner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Env.hasSupabaseConfig) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabasePublishableKey,
    );
    cleanOAuthCodeFromUrl();
  }

  runApp(const ProviderScope(child: BankSampahApp()));
}
