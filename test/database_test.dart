import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiko/core/database/database.dart';

void main() {
  test(
    'Usage is persisted as individual events and exact-event undo preserves other uses',
    () async {
      final database = TikoDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final now = DateTime.utc(2026, 11, 4, 8, 42);
      await database
          .into(database.subscriptions)
          .insert(
            SubscriptionsCompanion.insert(
              id: 'pass',
              name: 'Pass',
              totalCostMinorUnits: 113400,
              currencyCode: 'MDL',
              startDate: DateTime.utc(2026, 9),
              createdAt: now,
              updatedAt: now,
            ),
          );
      for (final id in ['first', 'second']) {
        await database
            .into(database.usageEvents)
            .insert(
              UsageEventsCompanion.insert(
                id: id,
                subscriptionId: 'pass',
                occurredAt: now,
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
      expect(await database.select(database.usageEvents).get(), hasLength(2));
      await (database.delete(
        database.usageEvents,
      )..where((e) => e.id.equals('second'))).go();
      final remaining = await database.select(database.usageEvents).get();
      expect(remaining.single.id, 'first');
      expect(remaining.single.quantity, 1);
      expect(remaining.single.occurredAt.toUtc(), now);
    },
  );
}
