import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tiko/core/database/database.dart';
import 'package:tiko/features/analytics/domain/usage_analytics.dart';

void main() {
  final start = DateTime.utc(2026, 1, 1);
  final subscription = Subscription(
    id: 'pass',
    name: 'Pass',
    description: null,
    category: 'Other',
    icon: 'ticket',
    color: '006B5E',
    totalCostMinorUnits: 10000,
    currencyCode: 'EUR',
    referenceUnitPriceMinorUnits: 1000,
    startDate: start,
    endDate: DateTime.utc(2026, 1, 31),
    isArchived: false,
    renewalGroupId: null,
    createdAt: start,
    updatedAt: start,
  );
  UsageEvent event(int day, {int quantity = 1}) => UsageEvent(
    id: '$day',
    subscriptionId: 'pass',
    occurredAt: DateTime(2026, 1, day, 8).toUtc(),
    createdAt: start,
    updatedAt: start,
    quantity: quantity,
    note: null,
  );
  const calculator = AnalyticsCalculator();
  test('Sparse, future, expired and archived periods are not forecast', () {
    expect(
      calculator.calculate(subscription, [
        event(1),
      ], now: DateTime(2026, 1, 8)).breakEvenDate,
      isNull,
    );
    expect(
      calculator.calculate(subscription, [
        event(1),
        event(2),
        event(3),
      ], now: DateTime(2026, 1, 4)).projectedAverageMinorUnits,
      isNull,
    );
    expect(
      calculator.calculate(subscription, [
        event(1),
        event(2),
        event(3),
      ], now: DateTime(2026, 2, 1)).breakEvenDate,
      isNull,
    );
    expect(
      calculator.calculate(subscription.copyWith(isArchived: true), [
        event(1),
        event(2),
        event(3),
      ], now: DateTime(2026, 1, 8)).breakEvenDate,
      isNull,
    );
    expect(
      calculator.calculate(
        subscription.copyWith(startDate: DateTime.utc(2027)),
        [event(1)],
        now: DateTime(2026, 1, 8),
      ).usesPerWeek,
      isNull,
    );
  });
  test(
    'Forecast follows valid-period rate and keeps actual totals separate',
    () {
      final result = calculator.calculate(subscription, [
        event(1),
        event(2),
        event(3),
      ], now: DateTime(2026, 1, 7));
      expect(result.total, 3);
      expect(result.usesPerWeek, 3);
      expect(result.daysSinceLastUse, 4);
      expect(result.breakEvenDate, DateTime(2026, 1, 24));
      expect(result.projectedAverageMinorUnits, 753);
    },
  );
  test(
    'Missing reference and open-ended dates suppress relevant projections',
    () {
      final result = calculator.calculate(
        subscription.copyWith(
          referenceUnitPriceMinorUnits: const Value(null),
          endDate: const Value(null),
        ),
        [event(1), event(2), event(3)],
        now: DateTime(2026, 1, 8),
      );
      expect(result.breakEvenDate, isNull);
      expect(result.projectedAverageMinorUnits, isNull);
      expect(result.usesPerWeek, isNotNull);
    },
  );
}
