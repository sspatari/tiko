import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tiko/core/database/database.dart';
import 'package:tiko/features/subscriptions/data/subscription_repository.dart';
import 'package:tiko/features/usage/data/usage_repository.dart';

void main() {
  late TikoDatabase database;
  late DriftSubscriptionRepository subscriptions;
  late UsageRepository usage;
  setUp(() async {
    database = TikoDatabase.forTesting(NativeDatabase.memory());
    subscriptions = DriftSubscriptionRepository(database);
    usage = UsageRepository(database);
    final now = DateTime.utc(2026, 1, 1);
    await subscriptions.save(
      SubscriptionsCompanion.insert(
        id: 'pass',
        name: 'Pass',
        totalCostMinorUnits: 113400,
        currencyCode: 'MDL',
        startDate: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
  });
  tearDown(() => database.close());

  test('Renewal links periods and preserves historical events', () async {
    final originalId = await usage.add('pass');
    final original =
        (await database.select(database.subscriptions).get()).single;
    final renewedId = await subscriptions.renew(
      original,
      DateTime(2027),
      DateTime(2028),
    );
    final periods = await database.select(database.subscriptions).get();
    expect(periods, hasLength(2));
    expect(periods.first.renewalGroupId, isNotNull);
    expect(periods.map((p) => p.renewalGroupId).toSet(), hasLength(1));
    expect(renewedId, isNot('pass'));
    final event = (await database.select(database.usageEvents).get()).single;
    expect(event.id, originalId);
    expect(event.subscriptionId, 'pass');
  });

  test(
    'Editing and undo target exact events; deleting subscription cascades',
    () async {
      final first = await usage.add('pass');
      final second = await usage.add('pass');
      final backdate = DateTime.utc(2026, 2, 3, 9);
      await usage.edit(
        first,
        occurredAt: backdate,
        quantity: 3,
        note: 'Forgotten visits',
      );
      await usage.delete(second);
      final event = (await database.select(database.usageEvents).get()).single;
      expect(event.id, first);
      expect(event.quantity, 3);
      expect(event.occurredAt.toUtc(), backdate);
      expect(event.note, 'Forgotten visits');
      await subscriptions.archive('pass', true);
      expect(
        (await database.select(database.subscriptions).get()).single.isArchived,
        isTrue,
      );
      await subscriptions.delete('pass');
      expect(await database.select(database.usageEvents).get(), isEmpty);
    },
  );

  test('Invalid renewal and quantity leave existing records intact', () async {
    final original =
        (await database.select(database.subscriptions).get()).single;
    expect(
      () => subscriptions.renew(original, DateTime(2028), DateTime(2027)),
      throwsArgumentError,
    );
    await expectLater(usage.add('pass', quantity: 0), throwsArgumentError);
    expect(await database.select(database.usageEvents).get(), isEmpty);
    expect(await database.select(database.subscriptions).get(), hasLength(1));
  });
  test(
    'An oversized calculated value rolls back the event instead of overflowing',
    () async {
      await subscriptions.save(
        (await database.select(database.subscriptions).get()).single
            .toCompanion(false)
            .copyWith(referenceUnitPriceMinorUnits: Value(9007199254740991)),
      );
      await expectLater(usage.add('pass', quantity: 2), throwsArgumentError);
      expect(await database.select(database.usageEvents).get(), isEmpty);
    },
  );
}
