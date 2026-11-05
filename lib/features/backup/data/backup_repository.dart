import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../core/database/database.dart';
import '../../settings/data/preferences.dart';
import '../../subscriptions/domain/financial_calculator.dart';
import '../../subscriptions/data/financial_validation.dart';
import '../../usage/domain/usage_dates.dart';

const backupSerializer = ValueSerializer.defaults(
  serializeDateTimeValuesAsString: true,
);
const maxExactInteger = 9007199254740991;
final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

class BackupData {
  BackupData(this.subscriptions, this.events, this.preferences);
  final List<Subscription> subscriptions;
  final List<UsageEvent> events;
  final AppPreferences preferences;
}

class BackupRepository {
  BackupRepository(this.database);
  final TikoDatabase database;

  Future<String> exportJson() => database.transaction(() async {
    final subscriptions = await database.select(database.subscriptions).get();
    final events = await database.select(database.usageEvents).get();
    final preferences = await PreferencesRepository(database).load();
    return const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'subscriptions': subscriptions.map(_subscriptionJson).toList(),
      'events': events.map(_eventJson).toList(),
      'preferences': preferences.toJson(),
    });
  });

  static Map<String, dynamic> _subscriptionJson(Subscription s) => {
    ...s.toJson(serializer: backupSerializer),
    'startDate': _date(s.startDate),
    'endDate': s.endDate == null ? null : _date(s.endDate!),
    'createdAt': s.createdAt.toUtc().toIso8601String(),
    'updatedAt': s.updatedAt.toUtc().toIso8601String(),
  };
  static Map<String, dynamic> _eventJson(UsageEvent e) => {
    ...e.toJson(serializer: backupSerializer),
    'occurredAt': e.occurredAt.toUtc().toIso8601String(),
    'createdAt': e.createdAt.toUtc().toIso8601String(),
    'updatedAt': e.updatedAt.toUtc().toIso8601String(),
  };
  static String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static BackupData decode(String source) {
    try {
      final root = jsonDecode(source);
      if (root is! Map<String, dynamic> ||
          root['schemaVersion'] != 1 ||
          root['subscriptions'] is! List ||
          root['events'] is! List ||
          root['preferences'] is! Map<String, dynamic>) {
        throw const FormatException();
      }
      final subscriptions = <Subscription>[];
      final ids = <String>{};
      for (final row in root['subscriptions'] as List) {
        if (row is! Map<String, dynamic>) throw const FormatException();
        _id(row['id']);
        if (!ids.add(row['id'] as String)) {
          throw const FormatException('Duplicate subscription ID');
        }
        if (row['name'] is! String ||
            (row['name'] as String).trim().isEmpty ||
            row['category'] is! String ||
            row['icon'] is! String ||
            row['color'] is! String ||
            !RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(row['color'] as String) ||
            row['currencyCode'] is! String ||
            !RegExp(r'^[A-Z]{3}$').hasMatch(row['currencyCode'] as String) ||
            row['isArchived'] is! bool) {
          throw const FormatException();
        }
        _integer(row['totalCostMinorUnits'], 0, maxExactInteger);
        if (row['referenceUnitPriceMinorUnits'] != null) {
          _integer(row['referenceUnitPriceMinorUnits'], 1, maxExactInteger);
        }
        if (row['description'] != null && row['description'] is! String) {
          throw const FormatException();
        }
        if (row['renewalGroupId'] != null) _id(row['renewalGroupId']);
        _calendarDate(row['startDate']);
        if (row['endDate'] != null) _calendarDate(row['endDate']);
        _instant(row['createdAt']);
        _instant(row['updatedAt']);
        final subscription = Subscription.fromJson({
          ...row,
          'startDate': '${row['startDate']}T00:00:00Z',
          'endDate': row['endDate'] == null
              ? null
              : '${row['endDate']}T00:00:00Z',
        }, serializer: backupSerializer);
        if (subscription.endDate != null &&
            subscription.endDate!.isBefore(subscription.startDate)) {
          throw const FormatException('Invalid validity dates');
        }
        subscriptions.add(subscription);
      }
      final events = <UsageEvent>[];
      final eventIds = <String>{};
      for (final row in root['events'] as List) {
        if (row is! Map<String, dynamic>) throw const FormatException();
        _id(row['id']);
        _id(row['subscriptionId']);
        if (!eventIds.add(row['id'] as String)) {
          throw const FormatException('Duplicate event ID');
        }
        if (!ids.contains(row['subscriptionId'])) {
          throw const FormatException('Missing subscription relationship');
        }
        _integer(row['quantity'], 1, 2147483647);
        if (row['note'] != null && row['note'] is! String) {
          throw const FormatException();
        }
        _instant(row['occurredAt']);
        _instant(row['createdAt']);
        _instant(row['updatedAt']);
        events.add(UsageEvent.fromJson(row, serializer: backupSerializer));
      }
      final totals = <String, int>{};
      for (final event in events) {
        final previous = totals[event.subscriptionId] ?? 0;
        if (event.quantity > maxFinancialInteger - previous) {
          throw const FormatException('Usage total out of range');
        }
        totals[event.subscriptionId] = previous + event.quantity;
      }
      for (final subscription in subscriptions) {
        final total = totals[subscription.id] ?? 0;
        const FinancialCalculator().calculate(
          costMinorUnits: subscription.totalCostMinorUnits,
          quantities: total == 0 ? [] : [total],
          referenceMinorUnits: subscription.referenceUnitPriceMinorUnits,
        );
      }
      return BackupData(
        List.unmodifiable(subscriptions),
        List.unmodifiable(events),
        AppPreferences.fromJson(root['preferences'] as Map<String, dynamic>),
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid backup');
    }
  }

  static void _id(Object? value) {
    if (value is! String || !_uuid.hasMatch(value)) {
      throw const FormatException('Invalid UUID');
    }
  }

  static void _integer(Object? value, int min, int max) {
    if (value is! int || value < min || value > max) {
      throw const FormatException('Invalid amount or quantity');
    }
  }

  static void _calendarDate(Object? value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw const FormatException('Invalid date');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null || _date(parsed) != value) {
      throw const FormatException('Invalid date');
    }
  }

  static void _instant(Object? value) {
    if (value is! String ||
        !RegExp(
          r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?Z$',
        ).hasMatch(value)) {
      throw const FormatException('UTC timestamp required');
    }
    final date = DateTime.tryParse(value);
    if (date == null ||
        date.microsecondsSinceEpoch % Duration.microsecondsPerSecond != 0 ||
        date.toIso8601String().substring(0, 19) != value.substring(0, 19)) {
      throw const FormatException('Invalid timestamp');
    }
  }

  Future<({int added, int skipped})> restore(
    BackupData backup,
  ) => database.transaction(() async {
    // Revalidate even programmatically constructed backup objects.
    final checked = decode(
      jsonEncode({
        'schemaVersion': 1,
        'subscriptions': backup.subscriptions.map(_subscriptionJson).toList(),
        'events': backup.events.map(_eventJson).toList(),
        'preferences': backup.preferences.toJson(),
      }),
    );
    final subscriptions = {
      for (final s in await database.select(database.subscriptions).get())
        s.id: s,
    };
    final events = {
      for (final e in await database.select(database.usageEvents).get())
        e.id: e,
    };
    var added = 0;
    var skipped = 0;
    for (final subscription in checked.subscriptions) {
      final existing = subscriptions[subscription.id];
      if (existing != null) {
        if (jsonEncode(_subscriptionJson(existing)) !=
            jsonEncode(_subscriptionJson(subscription))) {
          throw const FormatException(
            'A subscription ID conflicts with local data. Nothing was imported.',
          );
        }
        skipped++;
      } else {
        await database
            .into(database.subscriptions)
            .insert(subscription.toCompanion(false));
        added++;
      }
    }
    for (final event in checked.events) {
      final existing = events[event.id];
      if (existing != null) {
        if (jsonEncode(_eventJson(existing)) != jsonEncode(_eventJson(event))) {
          throw const FormatException(
            'An event ID conflicts with local data. Nothing was imported.',
          );
        }
        skipped++;
      } else {
        await database
            .into(database.usageEvents)
            .insert(event.toCompanion(false));
        added++;
      }
    }
    await validateStoredFinancials(
      database,
      checked.subscriptions.map((s) => s.id),
    );
    await PreferencesRepository(database).save(checked.preferences);
    return (added: added, skipped: skipped);
  });

  Future<String> exportCsv({
    String? subscriptionId,
    DateTime? from,
    DateTime? through,
  }) async {
    return database.transaction(() async {
      final subscriptions = {
        for (final s in await database.select(database.subscriptions).get())
          s.id: s,
      };
      final query = database.select(database.usageEvents);
      if (subscriptionId != null) {
        query.where((e) => e.subscriptionId.equals(subscriptionId));
      }
      if (from != null) {
        query.where(
          (e) => e.occurredAt.isBiggerOrEqualValue(localDay(from).toUtc()),
        );
      }
      if (through != null) {
        query.where(
          (e) => e.occurredAt.isSmallerThanValue(
            nextLocalDay(localDay(through)).toUtc(),
          ),
        );
      }
      query.orderBy([
        (e) => OrderingTerm.desc(e.occurredAt),
        (e) => OrderingTerm.desc(e.id),
      ]);
      final events = await query.get();
      String cell(Object value) {
        var text = value.toString();
        if (RegExp(r'^\s*[=+@-]').hasMatch(text)) text = "'$text";
        return '"${text.replaceAll('"', '""')}"';
      }

      return '\uFEFFevent_id,subscription_id,subscription,occurred_at_utc,quantity,note\r\n${events.map((e) => [e.id, e.subscriptionId, subscriptions[e.subscriptionId]?.name ?? '', e.occurredAt.toUtc().toIso8601String(), e.quantity, e.note ?? ''].map(cell).join(',')).join('\r\n')}\r\n';
    });
  }
}
