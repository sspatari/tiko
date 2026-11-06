import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiko/core/database/database.dart';
import 'package:tiko/core/localization/app_localizations.dart';
import 'package:tiko/core/localization/app_localizations_en.dart';
import 'package:tiko/core/localization/app_localizations_ro.dart';
import 'package:tiko/features/subscriptions/domain/financial_calculator.dart';
import 'package:tiko/features/usage/data/usage_repository.dart';
import 'package:tiko/main.dart';

void main() {
  const calculator = FinancialCalculator();
  FinancialSummary summary(int uses, {int cost = 100, int? reference = 30}) =>
      calculator.calculate(
        costMinorUnits: cost,
        quantities: uses == 0 ? [] : [uses],
        referenceMinorUnits: reference,
      );

  test(
    'Recovery uses the integer break-even threshold, not rounded average or progress',
    () {
      expect(summary(0).costRecoveryState, CostRecoveryState.inProgress);
      expect(summary(3).remainingUses, 1);
      expect(summary(3).costRecoveryState, CostRecoveryState.inProgress);
      expect(summary(4).costRecoveryState, CostRecoveryState.recovered);
      expect(summary(9).costRecoveryState, CostRecoveryState.recovered);
      expect(
        summary(1000, reference: null).costRecoveryState,
        CostRecoveryState.unavailable,
      );
      expect(summary(0, cost: 0).costRecoveryState, CostRecoveryState.noCost);
      expect(
        summary(0, cost: 0, reference: null).costRecoveryState,
        CostRecoveryState.unavailable,
      );
    },
  );

  test(
    'Recovery copy has English and Romanian singular, few and other plurals',
    () {
      final en = AppLocalizationsEn();
      final ro = AppLocalizationsRo();
      expect(
        en.usesToRecoverCost(1),
        '1 more use to recover your prepaid cost.',
      );
      expect(
        en.usesToRecoverCost(2),
        '2 more uses to recover your prepaid cost.',
      );
      expect(ro.usesToRecoverCost(1), contains('o utilizare'));
      expect(ro.usesToRecoverCost(2), contains('2 utilizări'));
      expect(ro.usesToRecoverCost(20), contains('20 de utilizări'));
      expect(ro.usesShortOfRecoveringCost(1), startsWith('O utilizare'));
      expect(ro.usesShortOfRecoveringCost(2), startsWith('2 utilizări'));
      expect(ro.usesShortOfRecoveringCost(20), startsWith('20 de utilizări'));
    },
  );

  testWidgets(
    'Recovery messages distinguish closed periods, zero cost and unavailable reference',
    (tester) async {
      Future<void> show(
        FinancialSummary value, {
        bool closed = false,
        String language = 'en',
      }) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: tikoTheme(Brightness.dark),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: BreakEvenMessage(
                  summary: value,
                  periodClosed: closed,
                  showComparisonHint: true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await show(summary(3));
      expect(
        find.text('1 more use to recover your prepaid cost.'),
        findsOneWidget,
      );
      await show(summary(3), closed: true);
      expect(
        find.text('1 use short of recovering your prepaid cost.'),
        findsOneWidget,
      );
      expect(find.textContaining('more use'), findsNothing);
      await show(summary(4));
      expect(find.text('You’ve recovered your prepaid cost.'), findsOneWidget);
      expect(find.text('Compared with paying per use.'), findsOneWidget);
      await show(summary(0, cost: 0));
      expect(find.text('No prepaid cost to recover.'), findsOneWidget);
      expect(find.text('You’ve recovered your prepaid cost.'), findsNothing);
      await show(summary(500, reference: null));
      expect(find.textContaining('recover'), findsNothing);

      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await show(summary(3), closed: true, language: 'ro');
      expect(tester.takeException(), isNull);
      await show(summary(4), language: 'ro');
      expect(find.text('Ai recuperat costul abonamentului.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Milestone updates from saved events, survives compact view, and reverts on exact-event Undo',
    (tester) async {
      final database = TikoDatabase.forTesting(NativeDatabase.memory());
      final now = DateTime.now().toUtc();
      await database
          .into(database.subscriptions)
          .insert(
            SubscriptionsCompanion.insert(
              id: 'pass',
              name: 'Pass',
              totalCostMinorUnits: 100,
              currencyCode: 'EUR',
              referenceUnitPriceMinorUnits: const Value(60),
              startDate: DateTime.utc(2020),
              createdAt: now,
              updatedAt: now,
            ),
          );
      final originalEvent = await UsageRepository(database).add('pass');
      router.go('/');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(database)],
          child: const TikoApp(),
        ),
      );
      Future<void> settle() async {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 60)),
        );
        await tester.pumpAndSettle();
      }

      await settle();
      expect(
        find.text('1 more use to recover your prepaid cost.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.widgetWithText(FilledButton, '+1 USE'));
      await tester.tap(find.widgetWithText(FilledButton, '+1 USE'));
      await settle();
      expect(find.text('You’ve recovered your prepaid cost.'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(TikoApp)),
      );
      Future<void> compact(bool value) async {
        await tester.runAsync(
          () => container
              .read(preferencesProvider.notifier)
              .save(
                container
                    .read(preferencesProvider)
                    .copyWith(
                      homeLayout: container
                          .read(preferencesProvider)
                          .homeLayout
                          .copyWith(compact: value),
                    ),
              ),
        );
        await settle();
      }

      await compact(true);
      expect(find.text('You’ve recovered your prepaid cost.'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await settle();
      expect(find.text('You’ve recovered your prepaid cost.'), findsNothing);
      final events = await tester.runAsync(
        () => database.select(database.usageEvents).get(),
      );
      expect(events!.map((event) => event.id), [originalEvent]);
      await compact(false);
      expect(
        find.text('1 more use to recover your prepaid cost.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Pass'));
      await tester.tap(find.text('Pass'));
      await settle();
      expect(
        find.text('1 more use to recover your prepaid cost.'),
        findsOneWidget,
      );
      expect(find.text('Compared with paying per use.'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.runAsync(database.close);
    },
  );
}
