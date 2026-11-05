import 'package:drift/drift.dart';
import '../../../core/database/database.dart';
import '../domain/financial_calculator.dart';

/// Run inside the caller's transaction so an out-of-range edit rolls back.
Future<void> validateStoredFinancials(
  TikoDatabase database,
  Iterable<String> ids,
) async {
  for (final id in ids) {
    final subscription = await (database.select(
      database.subscriptions,
    )..where((s) => s.id.equals(id))).getSingle();
    final row = await database
        .customSelect(
          'SELECT COALESCE(SUM(quantity), 0) AS total FROM usage_events WHERE subscription_id = ?',
          variables: [Variable<String>(id)],
          readsFrom: {database.usageEvents},
        )
        .getSingle();
    final total = row.read<int>('total');
    const FinancialCalculator().calculate(
      costMinorUnits: subscription.totalCostMinorUnits,
      quantities: total == 0 ? [] : [total],
      referenceMinorUnits: subscription.referenceUnitPriceMinorUnits,
    );
  }
}
