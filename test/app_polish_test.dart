import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiko/core/database/database.dart';
import 'package:tiko/core/localization/app_localizations.dart';
import 'package:tiko/features/settings/data/preferences.dart';
import 'package:tiko/features/usage/data/usage_repository.dart';
import 'package:tiko/main.dart';

Future<void> settleApp(WidgetTester tester) async {
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
    await database
        .into(database.subscriptions)
        .insert(
          SubscriptionsCompanion.insert(
            id: 'pass',
            name: 'Pass',
            totalCostMinorUnits: 100,
            currencyCode: 'EUR',
            startDate: DateTime.utc(2020),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await UsageRepository(database).add('pass');
    router.go('/');
  });
  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const TikoApp(),
      ),
    );
    await settleApp(tester);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.runAsync(database.close);
  }

  testWidgets(
    'Navigation opens analytics and settings; language and theme persist',
    (tester) async {
      await launch(tester);
      await tester.tap(find.text('Analytics'));
      await settleApp(tester);
      expect(find.text('Total recorded usage'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      await tester.tap(find.text('Settings').last);
      await settleApp(tester);
      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<String>, 'Appearance'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark').last);
      await settleApp(tester);
      expect(
        (await tester.runAsync(
          () => PreferencesRepository(database).load(),
        ))!.theme,
        'dark',
      );
      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<String>, 'Language'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Română').last);
      await settleApp(tester);
      expect(find.text('Aspect'), findsOneWidget);
      expect(find.text('Setări'), findsWidgets);
      expect(
        (await tester.runAsync(
          () => PreferencesRepository(database).load(),
        ))!.language,
        'ro',
      );
      await close(tester);
    },
  );
  testWidgets(
    'Dashboard supports large text and opening a detail records no usage',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await launch(tester);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Pass'));
      await settleApp(tester);
      expect(find.text('Average cost per use'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final events = await tester.runAsync(
        () => database.select(database.usageEvents).get(),
      );
      expect(events, hasLength(1));
      await close(tester);
    },
  );
  testWidgets('A cold link to a deleted subscription can return Home', (
    tester,
  ) async {
    router.go('/subscriptions/missing');
    await launch(tester);
    expect(find.text('Subscription not found.'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await settleApp(tester);
    expect(find.text('Pass'), findsOneWidget);
    await close(tester);
  });
  test('English and Romanian use localized plurals', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final ro = lookupAppLocalizations(const Locale('ro'));
    expect(en.uses(1), '1 use');
    expect(en.uses(2), '2 uses');
    expect(ro.uses(1), '1 utilizare');
    expect(ro.uses(2), '2 utilizări');
    expect(ro.uses(20), '20 de utilizări');
  });
}
