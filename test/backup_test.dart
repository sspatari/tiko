import 'dart:convert';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiko/core/database/database.dart';
import 'package:tiko/features/backup/data/backup_repository.dart';
import 'package:tiko/features/settings/data/preferences.dart';
import 'package:tiko/features/usage/data/usage_repository.dart';

const passId = '11111111-1111-4111-8111-111111111111';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  late TikoDatabase source;
  late TikoDatabase target;
  setUp(() async {
    source = TikoDatabase.forTesting(NativeDatabase.memory());
    target = TikoDatabase.forTesting(NativeDatabase.memory());
    final now = DateTime.utc(2026, 1, 1);
    await source
        .into(source.subscriptions)
        .insert(
          SubscriptionsCompanion.insert(
            id: passId,
            name: 'Pass, Chișinău',
            totalCostMinorUnits: 113400,
            currencyCode: 'MDL',
            startDate: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await UsageRepository(source).add(
      passId,
      occurredAt: DateTime.utc(2026, 3, 29, 8, 42),
      quantity: 2,
      note: 'He said "hello"\nAgain',
    );
    await PreferencesRepository(
      source,
    ).save(const AppPreferences(theme: 'dark', language: 'ro', haptics: false));
  });
  tearDown(() async {
    await source.close();
    await target.close();
  });

  test(
    'JSON backup round trips dates, IDs, relationships and settings without duplication',
    () async {
      final exported = await BackupRepository(source).exportJson();
      final backup = BackupRepository.decode(exported);
      expect(backup.subscriptions.single.startDate.isUtc, isTrue);
      expect(backup.subscriptions.single.startDate, DateTime.utc(2026, 1, 1));
      final repository = BackupRepository(target);
      expect(await repository.restore(backup), (added: 2, skipped: 0));
      expect(await repository.restore(backup), (added: 0, skipped: 2));
      expect(
        (await target.select(target.usageEvents).get()).single.quantity,
        2,
      );
      expect((await PreferencesRepository(target).load()).language, 'ro');
      final result =
          jsonDecode(await repository.exportJson()) as Map<String, dynamic>;
      final original = jsonDecode(exported) as Map<String, dynamic>;
      result.remove('exportedAt');
      original.remove('exportedAt');
      expect(result, original);
    },
  );

  test(
    'Conflict after a tentative insert rolls back all imported records and settings',
    () async {
      final decoded =
          jsonDecode(await BackupRepository(source).exportJson())
              as Map<String, dynamic>;
      final subscription =
          (decoded['subscriptions'] as List).single as Map<String, dynamic>;
      final extra = {
        ...subscription,
        'id': '22222222-2222-4222-8222-222222222222',
      };
      await BackupRepository(
        target,
      ).restore(BackupRepository.decode(jsonEncode(decoded)));
      await target
          .update(target.subscriptions)
          .write(const SubscriptionsCompanion(name: Value('Changed locally')));
      decoded['subscriptions'] = [extra, subscription];
      await expectLater(
        BackupRepository(
          target,
        ).restore(BackupRepository.decode(jsonEncode(decoded))),
        throwsFormatException,
      );
      expect(await target.select(target.subscriptions).get(), hasLength(1));
      expect(
        (await target.select(target.subscriptions).get()).single.name,
        'Changed locally',
      );
    },
  );

  test(
    'Invalid versions, duplicate IDs, timestamps and relationships are rejected',
    () async {
      final original = await BackupRepository(source).exportJson();
      for (final change in <void Function(Map<String, dynamic>)>[
        (data) => data['schemaVersion'] = 9,
        (data) => (data['subscriptions'] as List).add(
          (data['subscriptions'] as List).first,
        ),
        (data) => (data['events'] as List).first['subscriptionId'] =
            '33333333-3333-4333-8333-333333333333',
        (data) => (data['events'] as List).first['quantity'] = 0,
        (data) => (data['events'] as List).first['occurredAt'] =
            '2026-03-29T08:42:00.123Z',
        (data) => (data['events'] as List).first['occurredAt'] =
            '2026-02-30T12:00:00Z',
        (data) =>
            (data['subscriptions'] as List).first['startDate'] = '2026-02-30',
        (data) => (data['preferences'] as Map)['language'] = 'invalid',
      ]) {
        final data = jsonDecode(original) as Map<String, dynamic>;
        change(data);
        expect(
          () => BackupRepository.decode(jsonEncode(data)),
          throwsFormatException,
        );
      }
      expect(await target.select(target.subscriptions).get(), isEmpty);
    },
  );

  test(
    'CSV quotes commas, quotes and newlines and respects local date filters',
    () async {
      final repository = BackupRepository(source);
      final csv = await repository.exportCsv();
      expect(csv, contains('"Pass, Chișinău"'));
      expect(csv, contains('"He said ""hello""\nAgain"'));
      expect(csv, contains('2026-03-29T08:42:00.000Z'));
      final empty = await repository.exportCsv(
        from: DateTime(2020),
        through: DateTime(2020, 1, 1),
      );
      expect(empty, isNot(contains('Pass')));
    },
  );
}
