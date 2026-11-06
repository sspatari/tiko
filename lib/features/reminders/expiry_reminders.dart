import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../../core/database/database.dart';
import '../../core/localization/app_localizations.dart';

typedef ExpiryReminder = ({
  String subscriptionId,
  String name,
  tz.TZDateTime at,
  int days,
});

List<ExpiryReminder> planExpiryReminders(
  List<Subscription> subscriptions,
  tz.Location location,
  DateTime now,
) {
  final latestByGroup = <String, Subscription>{};
  for (final subscription in subscriptions) {
    final group = subscription.renewalGroupId;
    if (group == null) continue;
    final previous = latestByGroup[group];
    if (previous == null ||
        subscription.createdAt.isAfter(previous.createdAt) ||
        (subscription.createdAt == previous.createdAt &&
            !subscription.startDate.isBefore(previous.startDate))) {
      latestByGroup[group] = subscription;
    }
  }
  final result = <ExpiryReminder>[];
  for (final subscription in subscriptions) {
    final end = subscription.endDate;
    if (subscription.isArchived || end == null) continue;
    final group = subscription.renewalGroupId;
    if (group != null && latestByGroup[group]?.id != subscription.id) continue;
    for (final days in [3, 0]) {
      // Construct calendar dates rather than subtracting 72 hours across DST.
      final date = DateTime.utc(end.year, end.month, end.day - days);
      final at = tz.TZDateTime(location, date.year, date.month, date.day, 9);
      if (at.isAfter(now)) {
        result.add((
          subscriptionId: subscription.id,
          name: subscription.name,
          at: at,
          days: days,
        ));
      }
    }
  }
  result.sort((a, b) {
    final order = a.at.compareTo(b.at);
    return order != 0 ? order : a.subscriptionId.compareTo(b.subscriptionId);
  });
  // iOS permits only 64 pending requests. Keep the nearest reminders.
  return result.take(64).toList();
}

class ExpiryReminderService {
  ExpiryReminderService(
    this.openSubscription, {
    FlutterLocalNotificationsPlugin? notifications,
  }) : plugin = notifications ?? FlutterLocalNotificationsPlugin();
  final void Function(String) openSubscription;
  final FlutterLocalNotificationsPlugin plugin;
  Future<void>? _initialization;
  Future<void> _queue = Future.value();

  Future<void> initialize() => _initialization ??= _initialize().catchError((
    Object error,
    StackTrace stack,
  ) {
    _initialization = null;
    Error.throwWithStackTrace(error, stack);
  });
  Future<void> _initialize() async {
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) => _open(response.payload),
    );
    final launch = await plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      _open(launch?.notificationResponse?.payload);
    }
  }

  void _open(String? id) {
    if (id != null && id.isNotEmpty) openSubscription(id);
  }

  Future<bool> requestPermission() async {
    await initialize();
    if (Platform.isAndroid) {
      return await plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()!
              .requestNotificationsPermission() ??
          false;
    }
    if (Platform.isIOS) {
      return await plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()!
              .requestPermissions(alert: true, sound: true) ??
          false;
    }
    return false;
  }

  Future<bool> notificationsAllowed() async {
    if (Platform.isAndroid) {
      return await plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()!
              .areNotificationsEnabled() ??
          false;
    }
    return (await plugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()!
                .checkPermissions())
            ?.isEnabled ??
        false;
  }

  Future<tz.Location> localLocation() async {
    tzdata.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    return ['UTC', 'GMT', 'Etc/UTC', 'Etc/GMT'].contains(zone.identifier)
        ? tz.UTC
        : tz.getLocation(zone.identifier);
  }

  Future<void> sync(
    List<Subscription> subscriptions,
    bool enabled,
    AppLocalizations l10n,
  ) {
    final work = _queue.then((_) async {
      await initialize();
      if (!enabled) {
        await plugin.cancelAll();
        return;
      }
      if (!await notificationsAllowed()) {
        await plugin.cancelAll();
        throw StateError('Notification permission denied');
      }
      final reminders = planExpiryReminders(
        subscriptions,
        await localLocation(),
        DateTime.now(),
      );
      await plugin.cancelAll();
      for (final (index, reminder) in reminders.indexed) {
        await plugin.zonedSchedule(
          id: index,
          title: l10n.expiryReminderTitle,
          body: reminder.days == 0
              ? l10n.expiresTodayReminder(reminder.name)
              : l10n.expiresSoonReminder(reminder.name),
          scheduledDate: reminder.at,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'expiry',
              'Subscription expiry',
              channelDescription: 'Prepaid subscription expiry reminders',
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: reminder.subscriptionId,
        );
      }
    });
    _queue = work.catchError((Object _) {});
    return work;
  }
}
