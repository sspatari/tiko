import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiko/core/database/database.dart';
import 'package:tiko/features/usage/data/usage_repository.dart';
import 'package:tiko/main.dart';

Future<void> settleHistory(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  await tester.pumpAndSettle();
}

void main() {
  late TikoDatabase database;
  setUp(() async {
    database = TikoDatabase.forTesting(NativeDatabase.memory());
    final now = DateTime.now().toUtc();
    for (final id in ['pass', 'other']) {
      await database
          .into(database.subscriptions)
          .insert(
            SubscriptionsCompanion.insert(
              id: id,
              name: id == 'pass' ? 'Pass' : 'Other',
              totalCostMinorUnits: 100,
              currencyCode: 'EUR',
              startDate: DateTime.utc(2020),
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
    router.go('/history?subscription=pass');
  });

  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const TikoApp(),
      ),
    );
    await settleHistory(tester);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.runAsync(database.close);
  }

  testWidgets(
    'Manual entry validates quantity, persists notes, and can be edited',
    (tester) async {
      await launch(tester);
      await tester.tap(find.text('Add forgotten use'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantity'),
        '0',
      );
      await tester.tap(find.text('Save event'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a positive whole number'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantity'),
        '3',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Note (optional)'),
        'Forgotten visits',
      );
      await tester.tap(find.text('Save event'));
      await settleHistory(tester);
      expect(find.textContaining('Today ·'), findsOneWidget);
      expect(find.textContaining('Forgotten visits'), findsOneWidget);
      final initial = await tester.runAsync(
        () => database.select(database.usageEvents).get(),
      );
      expect(initial!.single.quantity, 3);
      await tester.tap(find.textContaining('Forgotten visits'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantity'),
        '2',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Note (optional)'),
        'Updated',
      );
      await tester.tap(find.text('Save event'));
      await settleHistory(tester);
      final edited = await tester.runAsync(
        () => database.select(database.usageEvents).get(),
      );
      expect(edited!.single.id, initial.single.id);
      expect(edited.single.quantity, 2);
      expect(edited.single.note, 'Updated');
      expect(find.textContaining('Updated'), findsOneWidget);
      await close(tester);
    },
  );

  testWidgets('Outside-validity entry requires an explicit override', (
    tester,
  ) async {
    await database
        .update(database.subscriptions)
        .write(SubscriptionsCompanion(startDate: Value(DateTime.utc(2100))));
    await launch(tester);
    await tester.tap(find.text('Add forgotten use'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save event'));
    await tester.pumpAndSettle();
    expect(find.text('Outside validity period'), findsOneWidget);
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();
    final cancelled = await tester.runAsync(
      () => database.select(database.usageEvents).get(),
    );
    expect(cancelled, isEmpty);
    await tester.tap(find.text('Save event'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save anyway'));
    await settleHistory(tester);
    final confirmed = await tester.runAsync(
      () => database.select(database.usageEvents).get(),
    );
    expect(confirmed, hasLength(1));
    await close(tester);
  });

  testWidgets('History filters subscriptions and loads additional pages', (
    tester,
  ) async {
    await database.transaction(() async {
      for (var i = 0; i < 51; i++) {
        await UsageRepository(
          database,
        ).add('pass', occurredAt: DateTime(2026, 1, 1, 0, i), note: 'Event $i');
      }
      await UsageRepository(
        database,
      ).add('other', note: 'Other subscription event');
    });
    await launch(tester);
    expect(find.textContaining('Other subscription event'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Load more'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Load more'));
    await settleHistory(tester);
    await tester.scrollUntilVisible(
      find.textContaining('Event 0', findRichText: true),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('Event 0'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other').last);
    await settleHistory(tester);
    expect(find.textContaining('Other subscription event'), findsOneWidget);
    await close(tester);
  });
  testWidgets(
    'Date editing keeps the event identity and deletion updates history',
    (tester) async {
      final originalTime = DateTime(2026, 1, 14, 8, 42);
      final id = await UsageRepository(
        database,
      ).add('pass', occurredAt: originalTime, note: 'Backdated');
      await launch(tester);
      await tester.tap(find.textContaining('Backdated'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save event'));
      await settleHistory(tester);
      final edited = await tester.runAsync(
        () => database.select(database.usageEvents).get(),
      );
      expect(edited!.single.id, id);
      expect(edited.single.occurredAt.toLocal(), DateTime(2026, 1, 15, 8, 42));
      await tester.tap(find.byTooltip('Event actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete event'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Backdated'), findsOneWidget);
      await tester.tap(find.byTooltip('Event actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete event'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await settleHistory(tester);
      expect(find.text('No usage events for these filters.'), findsOneWidget);
      final deleted = await tester.runAsync(
        () => database.select(database.usageEvents).get(),
      );
      expect(deleted, isEmpty);
      await close(tester);
    },
  );
}
