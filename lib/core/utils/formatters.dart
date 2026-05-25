class AppFormatters {
  const AppFormatters._();

  static String rupiah(num value) {
    final rounded = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < rounded.length; i++) {
      final remaining = rounded.length - i;
      buffer.write(rounded[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString()}';
  }

  static String kg(num value) => '${value.toStringAsFixed(2)} kg';

  static String shortDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  static DateTime startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime nextDay(DateTime value) {
    return startOfDay(value).add(const Duration(days: 1));
  }
}
