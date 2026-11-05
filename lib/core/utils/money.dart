import 'package:intl/intl.dart';

/// Currency precision comes from intl's ISO currency metadata.
class Money {
  static int precision(String currency) =>
      NumberFormat.currency(name: currency).decimalDigits!;

  static int scale(String currency) {
    var result = 1;
    for (var i = 0; i < precision(currency); i++) {
      result *= 10;
    }
    return result;
  }

  static int? parse(String input, String currency) {
    final text = input.trim().replaceAll(',', '.');
    final digits = precision(currency);
    if (!RegExp(r'^\d+(?:\.\d+)?$').hasMatch(text)) return null;
    final parts = text.split('.');
    if (parts.length == 2 && parts[1].length > digits) return null;
    final whole = int.tryParse(parts[0]);
    if (whole == null || whole > 9007199254740991 ~/ scale(currency)) {
      return null;
    }
    final fraction = parts.length == 1
        ? 0
        : int.tryParse(parts[1].padRight(digits, '0'));
    if (fraction == null) return null;
    final result = whole * scale(currency) + fraction;
    // Stay within exact interoperable JSON/SQLite application arithmetic.
    return result <= 9007199254740991 ? result : null;
  }

  static String input(int amount, String currency) {
    final unit = scale(currency);
    final digits = precision(currency);
    if (digits == 0) return '$amount';
    return '${amount ~/ unit}.${(amount % unit).toString().padLeft(digits, '0')}';
  }

  static String format(int amount, String currency) =>
      NumberFormat.currency(name: currency).format(amount / scale(currency));
}
