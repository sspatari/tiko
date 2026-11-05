import 'package:flutter_test/flutter_test.dart';
import 'package:tiko/features/subscriptions/domain/financial_calculator.dart';

void main() {
  const calculator = FinancialCalculator();
  test('Trolleybus: 87 rides', () {
    final result = calculator.calculate(
      costMinorUnits: 113400,
      quantities: [87],
      referenceMinorUnits: 700,
    );
    expect(result.breakEvenUses, 162);
    expect(result.averageMinorUnits, 1303);
    expect(result.remainingUses, 75);
    expect(result.equivalentMinorUnits, 60900);
    expect(result.savingsMinorUnits, -52500);
  });
  test('Trolleybus: break-even and savings', () {
    final even = calculator.calculate(
      costMinorUnits: 113400,
      quantities: [162],
      referenceMinorUnits: 700,
    );
    expect(even.remainingUses, 0);
    expect(even.savingsMinorUnits, 0);
    final result = calculator.calculate(
      costMinorUnits: 113400,
      quantities: [200],
      referenceMinorUnits: 700,
    );
    expect(result.averageMinorUnits, 567);
    expect(result.equivalentMinorUnits, 140000);
    expect(result.savingsMinorUnits, 26600);
    expect(result.progress, greaterThan(1));
  });
  test('Gym without reference', () {
    final result = calculator.calculate(
      costMinorUnits: 64500,
      quantities: [100],
    );
    expect(result.averageMinorUnits, 645);
    expect(result.breakEvenUses, isNull);
    expect(result.savingsMinorUnits, isNull);
  });
  test('Zero usage and free access', () {
    expect(
      calculator
          .calculate(costMinorUnits: 100, quantities: [])
          .averageMinorUnits,
      isNull,
    );
    final free = calculator.calculate(
      costMinorUnits: 0,
      quantities: [1],
      referenceMinorUnits: 100,
    );
    expect(free.breakEvenUses, 0);
    expect(free.progress, isNull);
  });
  test('Invalid amounts and quantities are rejected', () {
    expect(
      () => calculator.calculate(costMinorUnits: -1, quantities: []),
      throwsArgumentError,
    );
    expect(
      () => calculator.calculate(costMinorUnits: 1, quantities: [0]),
      throwsArgumentError,
    );
    expect(
      () => calculator.calculate(
        costMinorUnits: 1,
        quantities: [],
        referenceMinorUnits: 0,
      ),
      throwsArgumentError,
    );
  });
}
