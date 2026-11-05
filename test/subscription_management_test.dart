import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiko/core/database/database.dart';
import 'package:tiko/main.dart';

Future<void> settleDatabase(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

void main() {
  late TikoDatabase database;
  setUp(() async {
    database = TikoDatabase.forTesting(NativeDatabase.memory());
    final now = DateTime.now().toUtc();
    await database
        .into(database.subscriptions)
        .insert(
          SubscriptionsCompanion.insert(
            id: 'pass',
            name: 'Pass',
            totalCostMinorUnits: 113400,
            currencyCode: 'MDL',
            startDate: DateTime.utc(2020),
            createdAt: now,
            updatedAt: now,
          ),
        );
    router.go('/');
  });

  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const TikoApp(),
      ),
    );
    await settleDatabase(tester);
    await tester.tap(find.text('Pass'));
    await settleDatabase(tester);
  }

  Future<void> menu(WidgetTester tester, String text) async {
    await tester.tap(find.byTooltip('Manage subscription'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text));
    await settleDatabase(tester);
  }

  testWidgets(
    'Detail hides missing reference metrics and edits existing subscription',
    (tester) async {
      await launch(tester);
      expect(find.text('Average cost per use'), findsOneWidget);
      expect(find.text('Net savings'), findsNothing);
      await menu(tester, 'Edit subscription');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Edited pass',
      );
      await tester.tap(find.text('Save'));
      await settleDatabase(tester);
      final records = await tester.runAsync(
        () => database.select(database.subscriptions).get(),
      );
      expect(records, hasLength(1));
      expect(records!.single.id, 'pass');
      expect(records.single.name, 'Edited pass');
      expect(find.text('Edited pass'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.runAsync(database.close);
    },
  );

  testWidgets(
    'Archive disables recording, restore enables it, deletion needs confirmation',
    (tester) async {
      await launch(tester);
      await menu(tester, 'Archive subscription');
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '+1 USE'))
            .onPressed,
        isNull,
      );
      await menu(tester, 'Restore subscription');
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '+1 USE'))
            .onPressed,
        isNotNull,
      );
      await menu(tester, 'Delete subscription');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Pass'), findsOneWidget);
      await menu(tester, 'Delete subscription');
      await tester.tap(find.text('Delete'));
      await settleDatabase(tester);
      expect(find.text('Make every use count'), findsOneWidget);
      final records = await tester.runAsync(
        () => database.select(database.subscriptions).get(),
      );
      expect(records, isEmpty);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.runAsync(database.close);
    },
  );

  testWidgets('Renewal creates a linked empty period and opens its detail', (
    tester,
  ) async {
    await launch(tester);
    await menu(tester, 'Renew subscription');
    await tester.tap(find.text('Renew'));
    await settleDatabase(tester);
    final records = await tester.runAsync(
      () => database.select(database.subscriptions).get(),
    );
    expect(records, hasLength(2));
    expect(records!.map((s) => s.renewalGroupId).toSet(), hasLength(1));
    expect(records.first.renewalGroupId, isNotNull);
    expect(find.text('Related subscription periods'), findsOneWidget);
    expect(find.text('0 uses'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.runAsync(database.close);
  });
  testWidgets('Rapid taps record once and Undo deletes the created event', (
    tester,
  ) async {
    await launch(tester);
    final button = find.widgetWithText(FilledButton, '+1 USE');
    await tester.tap(button);
    await tester.tap(button);
    await settleDatabase(tester);
    final recorded = await tester.runAsync(
      () => database.select(database.usageEvents).get(),
    );
    expect(recorded, hasLength(1));
    await tester.tap(find.text('Undo'));
    await settleDatabase(tester);
    final remaining = await tester.runAsync(
      () => database.select(database.usageEvents).get(),
    );
    expect(remaining, isEmpty);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.runAsync(database.close);
  });
}
