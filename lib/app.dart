import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/reporting/providers/reporting_provider.dart';
import 'routing/app_router.dart';
import 'shared/layouts/mobile_app_frame.dart';

class BankSampahApp extends ConsumerWidget {
  const BankSampahApp({super.key});

  Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final unitBisnisAsync = ref.watch(currentUnitBisnisProvider);
    final unitBisnis = unitBisnisAsync.valueOrNull;
    final primaryColor = _parseHexColor(unitBisnis?.warnaPrimary) ?? const Color(0xFF2E7D32);

    return MaterialApp.router(
      title: 'Bank Sampah Pemda',
      theme: AppTheme.light(seedColor: primaryColor),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MobileAppFrame(child: child),
    );
  }
}
