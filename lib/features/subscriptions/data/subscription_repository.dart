import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'financial_validation.dart';
import '../../../core/database/database.dart';

abstract interface class SubscriptionRepository {
  Stream<List<Subscription>> watchAll();
  Future<void> save(SubscriptionsCompanion subscription);
  Future<void> archive(String id, bool archived);
  Future<void> delete(String id);
  Future<String> renew(Subscription source, DateTime start, DateTime? end);
  Future<String> renewWithSettings(
    Subscription source,
    SubscriptionsCompanion settings,
  );
}

class DriftSubscriptionRepository implements SubscriptionRepository {
  DriftSubscriptionRepository(this.database);
  final TikoDatabase database;

  @override
  Stream<List<Subscription>> watchAll() =>
      database.select(database.subscriptions).watch();

  @override
  Future<void> save(SubscriptionsCompanion subscription) =>
      database.transaction(() async {
        await database
            .into(database.subscriptions)
            .insertOnConflictUpdate(subscription);
        await validateStoredFinancials(database, [subscription.id.value]);
      });

  @override
  Future<void> archive(String id, bool archived) async {
    await (database.update(
      database.subscriptions,
    )..where((s) => s.id.equals(id))).write(
      SubscriptionsCompanion(
        isArchived: Value(archived),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    await (database.delete(
      database.subscriptions,
    )..where((s) => s.id.equals(id))).go();
  }

  @override
  Future<String> renew(Subscription source, DateTime start, DateTime? end) {
    if (end != null && end.isBefore(start)) {
      throw ArgumentError('Invalid validity period');
    }
    return renewWithSettings(
      source,
      source
          .toCompanion(false)
          .copyWith(
            startDate: Value(DateTime.utc(start.year, start.month, start.day)),
            endDate: Value(
              end == null ? null : DateTime.utc(end.year, end.month, end.day),
            ),
          ),
    );
  }

  @override
  Future<String> renewWithSettings(
    Subscription source,
    SubscriptionsCompanion settings,
  ) {
    final start = settings.startDate.value;
    final end = settings.endDate.present ? settings.endDate.value : null;
    if (end != null && end.isBefore(start)) {
      throw ArgumentError('Invalid validity period');
    }
    return database.transaction(() async {
      final current = await (database.select(
        database.subscriptions,
      )..where((s) => s.id.equals(source.id))).getSingle();
      final id = const Uuid().v4();
      final group = current.renewalGroupId ?? const Uuid().v4();
      final now = DateTime.now().toUtc();
      await (database.update(
        database.subscriptions,
      )..where((s) => s.id.equals(source.id))).write(
        SubscriptionsCompanion(
          renewalGroupId: Value(group),
          updatedAt: Value(now),
        ),
      );
      await save(
        settings.copyWith(
          id: Value(id),
          renewalGroupId: Value(group),
          isArchived: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      return id;
    });
  }
}
