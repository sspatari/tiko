import 'package:flutter_test/flutter_test.dart';
import 'package:tiko/core/utils/money.dart';

void main() {
  test('Currency parsing respects zero, two and three decimal places', () {
    expect(Money.parse('1134', 'MDL'), 113400);
    expect(Money.parse('13,03', 'MDL'), 1303);
    expect(Money.parse('645.00', 'EUR'), 64500);
    expect(Money.parse('123', 'JPY'), 123);
    expect(Money.parse('123.5', 'JPY'), isNull);
    expect(Money.parse('1.234', 'KWD'), 1234);
    expect(Money.parse('1.234', 'EUR'), isNull);
    expect(Money.parse('-1', 'EUR'), isNull);
    expect(Money.parse('999999999999999999999999999', 'EUR'), isNull);
    expect(Money.parse('9007199254740991', 'EUR'), isNull);
    for (final currency in ['MDL', 'JPY', 'KWD']) {
      expect(Money.parse(Money.input(1234, currency), currency), 1234);
    }
  });
}
