enum SubscriptionLifecycle { active, expiringSoon, upcoming, expired, archived }

/// Validity is expressed as calendar dates, never timezone-shifted instants.
SubscriptionLifecycle subscriptionLifecycle({
  required DateTime startDate,
  DateTime? endDate,
  required bool archived,
  required DateTime today,
}) {
  if (archived) return SubscriptionLifecycle.archived;
  DateTime calendarDay(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);
  final day = calendarDay(today);
  if (calendarDay(startDate).isAfter(day)) {
    return SubscriptionLifecycle.upcoming;
  }
  if (endDate != null) {
    final daysLeft = calendarDay(endDate).difference(day).inDays;
    if (daysLeft < 0) return SubscriptionLifecycle.expired;
    if (daysLeft <= 3) return SubscriptionLifecycle.expiringSoon;
  }
  return SubscriptionLifecycle.active;
}
