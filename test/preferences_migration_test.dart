import 'dart:io';
import 'package:tiko/features/settings/data/home_layout.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiko/core/database/database.dart';
import 'package:tiko/features/settings/data/preferences.dart';
import 'package:tiko/features/usage/data/usage_repository.dart';

void main() {
  test(
    'Version 1 migration preserves events; settings survive a database reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'tiko-migration-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/tiko.sqlite');
      var database = TikoDatabase.forTesting(NativeDatabase(file));
      final now = DateTime.utc(2026, 1, 1);
      await database
          .into(database.subscriptions)
          .insert(
            SubscriptionsCompanion.insert(
              id: 'pass',
              name: 'Pass',
              totalCostMinorUnits: 100,
              currencyCode: 'EUR',
              startDate: now,
              createdAt: now,
              updatedAt: now,
            ),
          );
      final event = await UsageRepository(
        database,
      ).add('pass', occurredAt: now);
      // Recreate the pre-settings v1 database, retaining its original tables/data.
      await database.customStatement('DROP TABLE app_settings');
      await database.customStatement('PRAGMA user_version = 1');
      await database.close();
      database = TikoDatabase.forTesting(NativeDatabase(file));
      expect(
        (await database.select(database.subscriptions).get()).single.name,
        'Pass',
      );
      expect(
        (await database.select(database.usageEvents).get()).single.id,
        event,
      );
      expect((await PreferencesRepository(database).load()).theme, 'system');
      await PreferencesRepository(database).save(
        const AppPreferences(
          theme: 'dark',
          language: 'ro',
          haptics: false,
          expiryReminders: true,
          homeLayout: HomeLayout(
            compact: true,
            pinnedIds: ['pass'],
            order: ['pass'],
          ),
        ),
      );
      await database.close();
      database = TikoDatabase.forTesting(NativeDatabase(file));
      final preferences = await PreferencesRepository(database).load();
      expect(preferences.theme, 'dark');
      expect(preferences.language, 'ro');
      expect(preferences.haptics, isFalse);
      expect(preferences.expiryReminders, isTrue);
      expect(preferences.homeLayout.compact, isTrue);
      expect(preferences.homeLayout.pinnedIds, ['pass']);
      expect(preferences.homeLayout.order, ['pass']);
      await database.close();
    },
  );
}
