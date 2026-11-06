import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiko/core/database/database.dart';
import 'package:tiko/core/localization/app_localizations.dart';
import 'package:tiko/features/reminders/expiry_reminders.dart';
import 'package:tiko/features/settings/data/preferences.dart';
import 'package:tiko/main.dart';

class FakeReminderService extends ExpiryReminderService {
  FakeReminderService() : super((_) {});
  bool allowed = false;
  int permissionRequests = 0;
  final enabledStates = <bool>[];
  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return allowed;
  }

  @override
  Future<void> sync(
    List<Subscription> subscriptions,
    bool enabled,
    AppLocalizations l10n,
  ) async {
    enabledStates.add(enabled);
  }
}

void main() {
  testWidgets('Reminders require opt-in and permission; disabling persists', (
    tester,
  ) async {
    final database = TikoDatabase.forTesting(NativeDatabase.memory());
    final service = FakeReminderService();
    router.go('/settings');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          expiryReminderServiceProvider.overrideWithValue(service),
        ],
        child: const TikoApp(),
      ),
    );
    Future<void> settle() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
    }

    await settle();
    expect(service.permissionRequests, 0);
    final toggle = find.widgetWithText(SwitchListTile, 'Expiry reminders');
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await settle();
    expect(service.permissionRequests, 1);
    expect(
      (await tester.runAsync(
        () => PreferencesRepository(database).load(),
      ))!.expiryReminders,
      isFalse,
    );
    expect(find.textContaining('Notifications are blocked'), findsOneWidget);
    service.allowed = true;
    await tester.tap(toggle);
    await settle();
    expect(
      (await tester.runAsync(
        () => PreferencesRepository(database).load(),
      ))!.expiryReminders,
      isTrue,
    );
    expect(service.enabledStates.last, isTrue);
    await tester.tap(toggle);
    await settle();
    expect(
      (await tester.runAsync(
        () => PreferencesRepository(database).load(),
      ))!.expiryReminders,
      isFalse,
    );
    expect(service.enabledStates.last, isFalse);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.runAsync(database.close);
  });
}
