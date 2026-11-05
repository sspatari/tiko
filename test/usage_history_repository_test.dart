import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiko/core/database/database.dart';
import 'package:tiko/features/usage/data/usage_repository.dart';
import 'package:tiko/features/usage/domain/usage_dates.dart';

void main() {
  late TikoDatabase database;
  late UsageRepository repository;
  setUp(() async {
    database = TikoDatabase.forTesting(NativeDatabase.memory());
    repository = UsageRepository(database);
    final now = DateTime.now().toUtc();
    for (final id in ['one', 'two']) {
      await database
          .into(database.subscriptions)
          .insert(
            SubscriptionsCompanion.insert(
              id: id,
              name: id,
              totalCostMinorUnits: 100,
              currencyCode: 'EUR',
              startDate: DateTime.utc(2026, 3, 1),
              endDate: Value(DateTime.utc(2026, 3, 31)),
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
  });
  tearDown(() => database.close());

  test('Inclusive local date filters exclude the following midnight', () async {
    final day = DateTime(2026, 3, 29);
    await repository.add('one', occurredAt: DateTime(2026, 3, 28, 23, 59));
    final first = await repository.add('one', occurredAt: day);
    final last = await repository.add(
      'one',
      occurredAt: DateTime(2026, 3, 29, 23, 59, 59),
    );
    await repository.add('one', occurredAt: nextLocalDay(day));
    await repository.add('two', occurredAt: day);
    final records = await repository
        .watchHistory(subscriptionId: 'one', from: day, through: day)
        .first;
    expect(records.map((e) => e.id), [last, first]);
    expect(records.every((e) => localDay(e.occurredAt) == day), isTrue);
  });

  test(
    'Bounded history stays ordered and refills after edits and deletions',
    () async {
      final ids = <String>[];
      for (var i = 0; i < 55; i++) {
        ids.add(
          await repository.add('one', occurredAt: DateTime(2026, 3, 1, 0, i)),
        );
      }
      expect(await repository.watchHistory(limit: 51).first, hasLength(51));
      expect(await repository.watchHistory(limit: 101).first, hasLength(55));
      await repository.edit(
        ids.first,
        occurredAt: DateTime(2026, 4),
        quantity: 3,
        note: 'Moved',
      );
      final updated = await repository.watchHistory(limit: 2).first;
      expect(updated.first.id, ids.first);
      expect(updated.first.quantity, 3);
      await repository.delete(ids.first);
      final remaining = await repository.watchHistory(limit: 2).first;
      expect(remaining.map((e) => e.id), [ids.last, ids[53]]);
      await expectLater(
        repository.edit('missing', occurredAt: DateTime.now(), quantity: 1),
        throwsStateError,
      );
    },
  );

  test('Invalid queries and quantities are rejected', () async {
    expect(() => repository.watchHistory(limit: 0), throwsArgumentError);
    expect(
      () => repository.watchHistory(
        from: DateTime(2026, 4),
        through: DateTime(2026, 3),
      ),
      throwsArgumentError,
    );
    await expectLater(
      repository.add('one', quantity: 2147483648),
      throwsArgumentError,
    );
  });

  test(
    'Validity includes both calendar dates, with UTC events localized',
    () async {
      final subscription =
          (await database.select(database.subscriptions).get()).first;
      expect(
        outsideValidity(subscription, DateTime(2026, 3, 1).toUtc()),
        isFalse,
      );
      expect(
        outsideValidity(subscription, DateTime(2026, 3, 31, 23, 59).toUtc()),
        isFalse,
      );
      expect(
        outsideValidity(subscription, DateTime(2026, 2, 28, 23, 59).toUtc()),
        isTrue,
      );
      expect(
        outsideValidity(subscription, DateTime(2026, 4, 1).toUtc()),
        isTrue,
      );
      final day = DateTime(2026, 10, 25);
      expect(nextLocalDay(day), DateTime(2026, 10, 26));
    },
  );
}
