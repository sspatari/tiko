import '../../../core/database/database.dart';
import '../../usage/domain/usage_dates.dart';
import '../../subscriptions/domain/financial_calculator.dart';

int calendarDays(DateTime from, DateTime through) => DateTime.utc(
  through.year,
  through.month,
  through.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

class UsageAnalytics {
  UsageAnalytics({
    required this.daily,
    required this.total,
    required this.daysSinceLastUse,
    required this.usesPerWeek,
    required this.usesPerMonth,
    required this.breakEvenDate,
    required this.projectedAverageMinorUnits,
  });
  final Map<DateTime, int> daily;
  final int total;
  final int? daysSinceLastUse;
  final double? usesPerWeek;
  final double? usesPerMonth;
  final DateTime? breakEvenDate;
  final int? projectedAverageMinorUnits;
}

class AnalyticsCalculator {
  const AnalyticsCalculator();
  UsageAnalytics calculate(
    Subscription subscription,
    Iterable<UsageEvent> events, {
    required DateTime now,
  }) {
    final selected = events
        .where((e) => e.subscriptionId == subscription.id)
        .toList();
    final daily = <DateTime, int>{};
    for (final event in selected) {
      final date = localDay(event.occurredAt);
      daily.update(
        date,
        (value) => value + event.quantity,
        ifAbsent: () => event.quantity,
      );
    }
    final today = localDay(now);
    final start = DateTime(
      subscription.startDate.year,
      subscription.startDate.month,
      subscription.startDate.day,
    );
    final end = subscription.endDate == null
        ? null
        : DateTime(
            subscription.endDate!.year,
            subscription.endDate!.month,
            subscription.endDate!.day,
          );
    final observedEnd = end != null && end.isBefore(today) ? end : today;
    final elapsed = calendarDays(start, observedEnd) + 1;
    var validUses = 0;
    var validDays = 0;
    DateTime? last;
    for (final entry in daily.entries) {
      if (!entry.key.isAfter(today) &&
          (last == null || entry.key.isAfter(last))) {
        last = entry.key;
      }
      if (!entry.key.isBefore(start) && !entry.key.isAfter(observedEnd)) {
        validUses += entry.value;
        validDays++;
      }
    }
    final rate = elapsed > 0 ? validUses / elapsed : null;
    final summary = const FinancialCalculator().calculate(
      costMinorUnits: subscription.totalCostMinorUnits,
      quantities: selected.map((e) => e.quantity),
      referenceMinorUnits: subscription.referenceUnitPriceMinorUnits,
    );
    final canForecast =
        elapsed >= 7 &&
        validDays >= 3 &&
        rate != null &&
        rate > 0 &&
        (end == null || !end.isBefore(today)) &&
        !subscription.isArchived;
    DateTime? breakEven;
    int? projected;
    if (canForecast) {
      if (summary.remainingUses != null && summary.remainingUses! > 0) {
        final days = (summary.remainingUses! / rate).ceil();
        if (days <= calendarDays(today, DateTime(9999, 12, 31))) {
          breakEven = DateTime(today.year, today.month, today.day + days);
        }
      }
      if (end != null) {
        final projectedUses = summary.uses + rate * calendarDays(today, end);
        if (projectedUses > 0) {
          projected = (summary.cost / projectedUses).round();
        }
      }
    }
    return UsageAnalytics(
      daily: daily,
      total: summary.uses,
      daysSinceLastUse: last == null ? null : calendarDays(last, today),
      usesPerWeek: rate == null ? null : rate * 7,
      usesPerMonth: rate == null ? null : rate * 30.4375,
      breakEvenDate: breakEven,
      projectedAverageMinorUnits: projected,
    );
  }
}
