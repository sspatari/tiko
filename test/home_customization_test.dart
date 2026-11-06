import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiko/core/database/database.dart';
import 'package:tiko/features/settings/data/preferences.dart';
import 'package:tiko/main.dart';

void main() {
  testWidgets(
    'Home pinning, accessible reordering, compact mode and reset persist only on Save',
    (tester) async {
      final database = TikoDatabase.forTesting(NativeDatabase.memory());
      for (final name in ['Alpha', 'Beta', 'Gamma']) {
        await database
            .into(database.subscriptions)
            .insert(
              SubscriptionsCompanion.insert(
                id: name.toLowerCase(),
                name: name,
                totalCostMinorUnits: 100,
                currencyCode: 'EUR',
                startDate: DateTime.utc(2020),
                createdAt: DateTime.utc(2026),
                updatedAt: DateTime.utc(2026),
              ),
            );
      }
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
      final fullHeight = tester
          .getSize(find.byKey(const ValueKey('alpha')))
          .height;
      await tester.tap(find.byTooltip('Customize Home'));
      await settle();
      await tester.tap(find.byTooltip('Arrange Beta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pin to top'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Arrange Gamma'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move up'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Compact cards'));
      await tester.tap(find.text('Compact cards'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await settle();
      final layout = (await tester.runAsync(
        () => PreferencesRepository(database).load(),
      ))!.homeLayout;
      expect(layout.compact, isTrue);
      expect(layout.pinnedIds, ['beta']);
      expect(layout.order, ['beta', 'gamma', 'alpha']);
      expect(
        tester.getSize(find.byKey(const ValueKey('beta'))).height,
        lessThan(fullHeight),
      );
      await tester.tap(find.widgetWithText(FilledButton, '+1 USE').first);
      await settle();
      await tester.tap(find.text('Undo'));
      await settle();
      expect(
        await tester.runAsync(
          () => database.select(database.usageEvents).get(),
        ),
        isEmpty,
      );
      await tester.tap(find.byTooltip('Customize Home'));
      await settle();
      await tester.ensureVisible(find.text('Reset Home layout'));
      await tester.tap(find.text('Reset Home layout'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await settle();
      expect(
        (await tester.runAsync(
          () => PreferencesRepository(database).load(),
        ))!.homeLayout.compact,
        isTrue,
      );
      await tester.tap(find.byTooltip('Customize Home'));
      await settle();
      await tester.ensureVisible(find.text('Reset Home layout'));
      await tester.tap(find.text('Reset Home layout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await settle();
      final reset = (await tester.runAsync(
        () => PreferencesRepository(database).load(),
      ))!.homeLayout;
      expect(reset.compact, isFalse);
      expect(reset.pinnedIds, isEmpty);
      expect(reset.order, isEmpty);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.runAsync(database.close);
    },
  );
}
