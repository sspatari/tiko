import 'package:drift/drift.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tiko/core/localization/app_localizations_en.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:tiko/core/database/database.dart';
import 'package:tiko/features/reminders/expiry_reminders.dart';
import 'package:tiko/features/settings/data/preferences.dart';

void main() {
  late TikoDatabase database;
  setUp(() {
    tzdata.initializeTimeZones();
    database = TikoDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => database.close());

  Future<Subscription> subscription(
    String id, {
    DateTime? end,
    bool archived = false,
    String? group,
    DateTime? created,
  }) async {
    await database
        .into(database.subscriptions)
        .insert(
          SubscriptionsCompanion.insert(
            id: id,
            name: id,
            totalCostMinorUnits: 100,
            currencyCode: 'EUR',
            startDate: DateTime.utc(2026, 1, 1),
            endDate: Value(end),
            isArchived: Value(archived),
            renewalGroupId: Value(group),
            createdAt: created ?? DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        );
    return (database.select(
      database.subscriptions,
    )..where((s) => s.id.equals(id))).getSingle();
  }

  test('Calendar reminders stay at 9 AM across spring DST', () async {
    final pass = await subscription('pass', end: DateTime.utc(2026, 3, 30));
    final location = tz.getLocation('Europe/Bucharest');
    final plan = planExpiryReminders(
      [pass],
      location,
      DateTime.utc(2026, 3, 1),
    );
    expect(plan.map((r) => r.days), [3, 0]);
    expect(plan.map((r) => r.at.hour), [9, 9]);
    expect(plan.first.at.day, 27);
    expect(plan.last.at.day, 30);
    expect(plan.last.at.difference(plan.first.at).inHours, 71);
  });

  test(
    'Past reminders, archived and open-ended subscriptions are omitted',
    () async {
      final items = [
        await subscription('today', end: DateTime.utc(2026, 5, 1)),
        await subscription(
          'archived',
          end: DateTime.utc(2026, 6, 1),
          archived: true,
        ),
        await subscription('open'),
      ];
      final location = tz.UTC;
      final before = planExpiryReminders(
        items,
        location,
        DateTime.utc(2026, 5, 1, 8),
      );
      expect(before.single.subscriptionId, 'today');
      expect(before.single.days, 0);
      expect(
        planExpiryReminders(items, location, DateTime.utc(2026, 5, 1, 9)),
        isEmpty,
      );
    },
  );

  test(
    'Renewal removes reminders for older periods without changing records',
    () async {
      final old = await subscription(
        'old',
        group: 'group',
        end: DateTime.utc(2026, 6, 1),
      );
      final renewed = await subscription(
        'new',
        group: 'group',
        end: DateTime.utc(2026, 7, 1),
        created: DateTime.utc(2026, 2, 1),
      );
      final plan = planExpiryReminders(
        [old, renewed],
        tz.UTC,
        DateTime.utc(2026, 3, 1),
      );
      expect(plan.map((r) => r.subscriptionId), ['new', 'new']);
      expect(await database.select(database.subscriptions).get(), hasLength(2));
      expect(planExpiryReminders([], tz.UTC, DateTime.utc(2026)), isEmpty);
    },
  );

  test('Keeps the nearest 64 requests in chronological order', () async {
    final items = <Subscription>[];
    for (var i = 39; i >= 0; i--) {
      items.add(
        await subscription('pass$i', end: DateTime.utc(2026, 6, i + 1)),
      );
    }
    final plan = planExpiryReminders(items, tz.UTC, DateTime.utc(2026));
    expect(plan, hasLength(64));
    for (var i = 1; i < plan.length; i++) {
      expect(plan[i].at.isBefore(plan[i - 1].at), isFalse);
    }
  });

  test(
    'Sync replaces stale requests after edits, archive, delete and disabling',
    () async {
      final notifications = FakeNotifications();
      final service = TestReminderService(notifications);
      final l10n = AppLocalizationsEn();
      final pass = await subscription('pass', end: DateTime.utc(2099, 6, 1));
      await service.sync([pass], true, l10n);
      expect(notifications.requests, hasLength(2));
      expect(notifications.requests.values.toSet(), {'pass'});
      await service.sync(
        [pass.copyWith(endDate: Value(DateTime.utc(2099, 7, 1)))],
        true,
        l10n,
      );
      expect(notifications.dates.last.month, 7);
      await service.sync([pass.copyWith(isArchived: true)], true, l10n);
      expect(notifications.requests, isEmpty);
      await service.sync([pass], true, l10n);
      await service.sync([], true, l10n);
      expect(notifications.requests, isEmpty);
      await service.sync([pass], true, l10n);
      await service.sync([pass], false, l10n);
      expect(notifications.requests, isEmpty);
    },
  );

  test(
    'Denied permission cancels pending reminders; retry can recover',
    () async {
      final notifications = FakeNotifications();
      final service = TestReminderService(notifications);
      final pass = await subscription('pass', end: DateTime.utc(2099, 6, 1));
      final l10n = AppLocalizationsEn();
      await service.sync([pass], true, l10n);
      service.allowed = false;
      await expectLater(service.sync([pass], true, l10n), throwsStateError);
      expect(notifications.requests, isEmpty);
      service.allowed = true;
      await service.sync([pass], true, l10n);
      expect(notifications.requests, hasLength(2));
    },
  );

  test(
    'Notification taps open the matching subscription on cold and warm launch',
    () async {
      final notifications = FakeNotifications();
      notifications.launch = const NotificationAppLaunchDetails(
        true,
        notificationResponse: NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: 'cold-pass',
        ),
      );
      final opened = <String>[];
      final service = ExpiryReminderService(
        opened.add,
        notifications: notifications,
      );
      await service.initialize();
      expect(opened, ['cold-pass']);
      notifications.onResponse!(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: 'warm-pass',
        ),
      );
      expect(opened, ['cold-pass', 'warm-pass']);
      expect(await database.select(database.usageEvents).get(), isEmpty);
    },
  );

  test(
    'Old backups default off; reminder preference persists and validates',
    () async {
      final old = {'theme': 'system', 'language': 'en', 'haptics': true};
      expect(AppPreferences.fromJson(old).expiryReminders, isFalse);
      expect(
        () => AppPreferences.fromJson({...old, 'expiryReminders': 'true'}),
        throwsFormatException,
      );
      final repository = PreferencesRepository(database);
      expect((await repository.load()).expiryReminders, isFalse);
      await repository.save(const AppPreferences(expiryReminders: true));
      expect((await repository.load()).expiryReminders, isTrue);
      expect(
        AppPreferences.fromJson(
          (await repository.load()).toJson(),
        ).expiryReminders,
        isTrue,
      );
    },
  );
}

class FakeNotifications implements FlutterLocalNotificationsPlugin {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  NotificationAppLaunchDetails? launch;
  void Function(NotificationResponse)? onResponse;
  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    void Function(NotificationResponse)? onDidReceiveNotificationResponse,
    void Function(NotificationResponse)?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    onResponse = onDidReceiveNotificationResponse;
    return true;
  }

  @override
  Future<NotificationAppLaunchDetails?>
  getNotificationAppLaunchDetails() async => launch;
  final requests = <int, String?>{};
  final dates = <tz.TZDateTime>[];
  @override
  Future<void> cancelAll() async {
    requests.clear();
    dates.clear();
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? title,
    String? body,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    requests[id] = payload;
    dates.add(scheduledDate);
  }
}

class TestReminderService extends ExpiryReminderService {
  TestReminderService(FakeNotifications notifications)
    : super((_) {}, notifications: notifications);
  bool allowed = true;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> notificationsAllowed() async => allowed;
  @override
  Future<tz.Location> localLocation() async => tz.UTC;
}
