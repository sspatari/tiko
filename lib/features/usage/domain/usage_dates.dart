import '../../../core/database/database.dart';

/// Subscription boundaries are date-only values, not UTC instants to localize.
bool outsideValidity(Subscription subscription, DateTime instant) {
  final local = instant.toLocal();
  final date = DateTime(local.year, local.month, local.day);
  final start = subscription.startDate;
  final end = subscription.endDate;
  return date.isBefore(DateTime(start.year, start.month, start.day)) ||
      (end != null && date.isAfter(DateTime(end.year, end.month, end.day)));
}

DateTime localDay(DateTime instant) {
  final local = instant.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// An exclusive next-midnight bound remains correct across 23/25-hour days.
DateTime nextLocalDay(DateTime date) =>
    DateTime(date.year, date.month, date.day + 1);
