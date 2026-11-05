import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database.dart';
import '../domain/usage_dates.dart';
import '../../subscriptions/data/financial_validation.dart';

class UsageRepository {
  UsageRepository(this.database);
  final TikoDatabase database;

  Stream<Map<String, int>> watchTotals() => database
      .customSelect(
        'SELECT subscription_id, SUM(quantity) AS total FROM usage_events GROUP BY subscription_id',
        readsFrom: {database.usageEvents},
      )
      .watch()
      .map(
        (rows) => {
          for (final row in rows)
            row.read<String>('subscription_id'): row.read<int>('total'),
        },
      );

  /// A bounded reactive prefix avoids stale offset pages after edits/deletions.
  Stream<List<UsageEvent>> watchHistory({
    String? subscriptionId,
    DateTime? from,
    DateTime? through,
    int limit = 50,
  }) {
    if (limit < 1) throw ArgumentError.value(limit, 'limit');
    if (from != null &&
        through != null &&
        localDay(from).isAfter(localDay(through))) {
      throw ArgumentError('Invalid date range');
    }
    final query = database.select(database.usageEvents);
    if (subscriptionId != null) {
      query.where((e) => e.subscriptionId.equals(subscriptionId));
    }
    if (from != null) {
      query.where(
        (e) => e.occurredAt.isBiggerOrEqualValue(localDay(from).toUtc()),
      );
    }
    if (through != null) {
      query.where(
        (e) => e.occurredAt.isSmallerThanValue(
          nextLocalDay(localDay(through)).toUtc(),
        ),
      );
    }
    query.orderBy([
      (e) => OrderingTerm.desc(e.occurredAt),
      (e) => OrderingTerm.desc(e.id),
    ]);
    query.limit(limit);
    return query.watch();
  }

  Future<String> add(
    String subscriptionId, {
    DateTime? occurredAt,
    int quantity = 1,
    String? note,
  }) async {
    if (quantity <= 0 || quantity > 2147483647) {
      throw ArgumentError.value(quantity, 'quantity');
    }
    final id = const Uuid().v4();
    final now = DateTime.now().toUtc();
    await database.transaction(() async {
      await database
          .into(database.usageEvents)
          .insert(
            UsageEventsCompanion.insert(
              id: id,
              subscriptionId: subscriptionId,
              occurredAt: (occurredAt ?? now).toUtc(),
              createdAt: now,
              updatedAt: now,
              quantity: Value(quantity),
              note: Value(note),
            ),
          );
      await validateStoredFinancials(database, [subscriptionId]);
    });
    return id;
  }

  Future<void> edit(
    String id, {
    required DateTime occurredAt,
    required int quantity,
    String? note,
  }) async {
    if (quantity <= 0 || quantity > 2147483647) {
      throw ArgumentError.value(quantity, 'quantity');
    }
    await database.transaction(() async {
      final original = await (database.select(
        database.usageEvents,
      )..where((e) => e.id.equals(id))).getSingle();
      final changed =
          await (database.update(
            database.usageEvents,
          )..where((e) => e.id.equals(id))).write(
            UsageEventsCompanion(
              occurredAt: Value(occurredAt.toUtc()),
              quantity: Value(quantity),
              note: Value(note),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );
      if (changed != 1) throw StateError('Usage event no longer exists');
      await validateStoredFinancials(database, [original.subscriptionId]);
    });
  }

  Future<void> delete(String id) async {
    await (database.delete(
      database.usageEvents,
    )..where((e) => e.id.equals(id))).go();
  }
}
