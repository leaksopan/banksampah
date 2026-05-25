import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light({Color seedColor = const Color(0xFF2E7D32)}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFEAF7F8),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
