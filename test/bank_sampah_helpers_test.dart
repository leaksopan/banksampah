import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Color? parseHexColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

void main() {
  group('Hex Color Parser Tests', () {
    test('Should parse valid 6-char hex color with # prefix', () {
      final color = parseHexColor('#2E7D32');
      expect(color, const Color(0xFF2E7D32));
    });

    test('Should parse valid 6-char hex color without # prefix', () {
      final color = parseHexColor('2E7D32');
      expect(color, const Color(0xFF2E7D32));
    });

    test('Should parse valid 8-char hex color with opacity', () {
      final color = parseHexColor('#802E7D32');
      expect(color, const Color(0x802E7D32));
    });

    test('Should return null for null input', () {
      final color = parseHexColor(null);
      expect(color, isNull);
    });

    test('Should return null for empty input', () {
      final color = parseHexColor('');
      expect(color, isNull);
    });
  });
}
