import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

class Subscriptions extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get category => text().withDefault(const Constant('Other'))();
  TextColumn get icon => text().withDefault(const Constant('ticket'))();
  TextColumn get color => text().withDefault(const Constant('006B5E'))();
  IntColumn get totalCostMinorUnits => integer().customConstraint(
    'NOT NULL CHECK (total_cost_minor_units >= 0)',
  )();
  TextColumn get currencyCode => text()();
  IntColumn get referenceUnitPriceMinorUnits => integer()
      .nullable()
      .customConstraint('CHECK (reference_unit_price_minor_units > 0)')();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get renewalGroupId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(
  name: 'usage_subscription_time',
  columns: {#subscriptionId, #occurredAt},
)
class UsageEvents extends Table {
  TextColumn get id => text()();
  TextColumn get subscriptionId => text().customConstraint(
    'NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE',
  )();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get quantity =>
      integer().customConstraint('NOT NULL DEFAULT 1 CHECK (quantity > 0)')();
  TextColumn get note => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Subscriptions, UsageEvents])
class TikoDatabase extends _$TikoDatabase {
  TikoDatabase() : super(driftDatabase(name: 'tiko'));
  TikoDatabase.forTesting(super.executor);
  @override
  int get schemaVersion => 1;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
