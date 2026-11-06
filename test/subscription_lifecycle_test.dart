import 'package:flutter_test/flutter_test.dart';
import 'package:tiko/features/subscriptions/domain/subscription_lifecycle.dart';

void main() {
  SubscriptionLifecycle status({
    DateTime? end,
    DateTime? start,
    bool archived = false,
    DateTime? today,
  }) => subscriptionLifecycle(
    startDate: start ?? DateTime.utc(2026, 1, 1),
    endDate: end,
    archived: archived,
    today: today ?? DateTime(2026, 3, 28, 23, 59),
  );

  test(
    'Expiry badges include the final three calendar days and expiry day',
    () {
      expect(
        status(end: DateTime.utc(2026, 4, 1)),
        SubscriptionLifecycle.active,
      );
      expect(
        status(end: DateTime.utc(2026, 3, 31)),
        SubscriptionLifecycle.expiringSoon,
      );
      expect(
        status(end: DateTime.utc(2026, 3, 28)),
        SubscriptionLifecycle.expiringSoon,
      );
      expect(
        status(end: DateTime.utc(2026, 3, 27)),
        SubscriptionLifecycle.expired,
      );
      expect(status(), SubscriptionLifecycle.active);
    },
  );

  test(
    'Archived and upcoming periods have precedence over expiry warnings',
    () {
      expect(
        status(end: DateTime.utc(2026, 3, 27), archived: true),
        SubscriptionLifecycle.archived,
      );
      expect(
        status(
          start: DateTime.utc(2026, 3, 29),
          end: DateTime.utc(2026, 3, 31),
        ),
        SubscriptionLifecycle.upcoming,
      );
    },
  );

  test(
    'Calendar boundaries remain correct across months, leap days and DST',
    () {
      expect(
        status(end: DateTime.utc(2028, 3, 2), today: DateTime(2028, 2, 28)),
        SubscriptionLifecycle.expiringSoon,
      );
      expect(
        status(end: DateTime.utc(2026, 3, 31), today: DateTime(2026, 3, 28)),
        SubscriptionLifecycle.expiringSoon,
      );
      expect(
        status(end: DateTime.utc(2026, 10, 27), today: DateTime(2026, 10, 24)),
        SubscriptionLifecycle.expiringSoon,
      );
    },
  );
}
