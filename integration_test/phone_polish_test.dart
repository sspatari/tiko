import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tiko/core/database/database.dart';
import 'package:tiko/core/localization/app_localizations.dart';
import 'package:tiko/features/settings/data/preferences.dart';
import 'package:tiko/main.dart';

// Run only through tool/run_ui_review.dart on a disposable simulator/emulator.
// In-memory fixtures do not protect a production app from test-runner uninstall.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Phone polish: usage, Home layout, Romanian, dark mode, large text and keyboard',
    (tester) async {
      final database = TikoDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() async {
        await database.close();
      });
      final now = DateTime.now().toUtc();
      for (final name in ['Coffee', 'Gym', 'Travel pass']) {
        await database
            .into(database.subscriptions)
            .insert(
              SubscriptionsCompanion.insert(
                id: name,
                name: name,
                totalCostMinorUnits: 10000,
                currencyCode: 'EUR',
                referenceUnitPriceMinorUnits: const Value(1000),
                startDate: DateTime.utc(2020),
                endDate: Value(DateTime.utc(now.year, now.month, now.day + 2)),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(database)],
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        container.dispose();
      });
      await container
          .read(preferencesProvider.notifier)
          .save(
            const AppPreferences(
              theme: 'light',
              language: 'en',
              haptics: false,
            ),
          );
      router.go('/');
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const TikoApp()),
      );
      Future<void> settle() async {
        await tester.pumpAndSettle();
        await Future<void>.delayed(const Duration(milliseconds: 150));
        await tester.pumpAndSettle();
      }

      try {
        await settle();
        if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
        await binding.takeScreenshot('home-light');
        final record = find.widgetWithText(FilledButton, '+1 USE').first;
        await tester.ensureVisible(record);
        await settle();
        await tester.tap(record);
        await settle();
        expect(await database.select(database.usageEvents).get(), hasLength(1));
        await tester.tap(find.text('Undo'));
        await settle();
        expect(await database.select(database.usageEvents).get(), isEmpty);

        await tester.tap(find.byTooltip('Customize Home'));
        await settle();
        final travelActions = find.byTooltip('Arrange Travel pass');
        await tester.ensureVisible(travelActions);
        await settle();
        await tester.tap(travelActions);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pin to top'));
        await tester.pumpAndSettle();
        final gymActions = find.byTooltip('Arrange Gym');
        await tester.ensureVisible(gymActions);
        await settle();
        await tester.tap(gymActions);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Move up'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Compact cards'));
        await settle();
        await tester.tap(find.text('Compact cards'));
        await tester.pumpAndSettle();
        await binding.takeScreenshot('customize-home');
        await tester.tap(find.text('Save'));
        await settle();
        final layout = (await PreferencesRepository(
          database,
        ).load()).homeLayout;
        expect(layout.compact, isTrue);
        expect(layout.pinnedIds, ['Travel pass']);
        expect(layout.order, ['Travel pass', 'Gym', 'Coffee']);
        await tester.drag(find.byType(ListView).first, const Offset(0, 1000));
        await tester.pumpAndSettle();
        await binding.takeScreenshot('home-compact');

        final preferences = container.read(preferencesProvider.notifier);
        await preferences.save(
          container
              .read(preferencesProvider)
              .copyWith(theme: 'dark', language: 'ro'),
        );
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await settle();
        expect(tester.takeException(), isNull);
        await binding.takeScreenshot('home-dark-ro-large');
        final button = find.descendant(
          of: find.byType(RecordUsageButton).first,
          matching: find.byType(FilledButton),
        );
        expect(tester.getSize(button).height, greaterThanOrEqualTo(48));

        await tester.ensureVisible(find.text('Travel pass'));
        await settle();
        await tester.tap(find.text('Travel pass'));
        await settle();
        var l10n = AppLocalizations.of(
          tester.element(find.byType(SubscriptionDetail)),
        );
        await tester.tap(find.byTooltip(l10n.manageSubscription));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.editSubscription));
        await tester.pumpAndSettle();
        final nameField = find.widgetWithText(TextFormField, l10n.name);
        await tester.ensureVisible(nameField);
        await settle();
        await tester.tap(nameField);
        await settle();
        // TestTextInput uses debug-only client -1, which profile builds ignore.
        // Apply the simulated edit through EditableText to synchronize native input.
        final editable = tester.state<EditableTextState>(
          find.descendant(of: nameField, matching: find.byType(EditableText)),
        );
        expect(editable.widget.focusNode.hasFocus, isTrue);
        // Hardware keyboards can legitimately leave the software keyboard hidden.
        binding.reportData ??= {};
        binding.reportData!['nativeKeyboardInset'] = MediaQuery.viewInsetsOf(
          tester.element(nameField),
        ).bottom;
        editable.userUpdateTextEditingValue(
          const TextEditingValue(
            text: 'Travel pass updated',
            selection: TextSelection.collapsed(offset: 19),
          ),
          SelectionChangedCause.keyboard,
        );
        expect(editable.widget.controller.text, 'Travel pass updated');
        await tester.pumpAndSettle();
        await binding.takeScreenshot('form-dark-ro-large');
        expect(tester.takeException(), isNull);
        final saveButton = find.widgetWithText(FilledButton, l10n.save);
        expect(saveButton.hitTestable(), findsOneWidget);
        await tester.tap(saveButton);
        await settle();
        expect(find.byType(CreateCounter), findsNothing);
        expect(
          (await database.select(database.subscriptions).get()).map(
            (s) => s.name,
          ),
          contains('Travel pass updated'),
        );
        expect(await database.select(database.usageEvents).get(), isEmpty);
      } catch (error, stack) {
        try {
          binding.reportData ??= {};
          binding.reportData!['failure'] = {
            'error': error.toString(),
            'stack': stack.toString(),
          };
          await binding.takeScreenshot('failure', {
            'error': error.toString(),
            'stack': stack.toString(),
          });
        } catch (_) {
          // Preserve the original failure if screenshot capture also fails.
        }
        rethrow;
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
}
