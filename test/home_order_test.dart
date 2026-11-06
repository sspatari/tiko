import 'package:flutter_test/flutter_test.dart';
import 'package:tiko/core/database/database.dart';
import 'package:tiko/features/home/domain/home_order.dart';
import 'package:tiko/features/settings/data/home_layout.dart';
import 'package:tiko/features/settings/data/preferences.dart';

Subscription pass(
  String id, {
  DateTime? start,
  DateTime? end,
  bool archived = false,
}) => Subscription(
  id: id,
  name: id,
  description: null,
  category: 'Other',
  icon: 'ticket',
  color: '006B5E',
  totalCostMinorUnits: 100,
  currencyCode: 'EUR',
  referenceUnitPriceMinorUnits: null,
  startDate: start ?? DateTime.utc(2026, 1, 1),
  endDate: end,
  isArchived: archived,
  renewalGroupId: null,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);
void main() {
  final today = DateTime(2026, 6, 1);
  test('Default Home preserves validity priority and alphabetical order', () {
    final items = [
      pass('expired', end: DateTime.utc(2026, 5, 1)),
      pass('upcoming', start: DateTime.utc(2026, 7, 1)),
      pass('B'),
      pass('A'),
      pass('archived', archived: true),
    ];
    expect(
      arrangeHomeSubscriptions(
        items,
        const HomeLayout(),
        today,
      ).map((s) => s.id),
      ['A', 'B', 'upcoming', 'expired', 'archived'],
    );
  });
  test(
    'Pins precede manual order; archived and missing IDs do not become visible',
    () {
      final items = [
        pass('a'),
        pass('b'),
        pass('expired', end: DateTime.utc(2026, 5, 1)),
        pass('archive', archived: true),
        pass('new'),
      ];
      const layout = HomeLayout(
        pinnedIds: ['expired', 'archive', 'missing'],
        order: ['b', 'a'],
      );
      expect(arrangeHomeSubscriptions(items, layout, today).map((s) => s.id), [
        'expired',
        'b',
        'a',
        'new',
        'archive',
      ]);
    },
  );
  test(
    'Reorder uses final indices in both directions and respects pin groups',
    () {
      const layout = HomeLayout(
        pinnedIds: ['a', 'b'],
        order: ['a', 'b', 'c', 'd', 'archived'],
      );
      const ids = ['a', 'b', 'c', 'd'];
      expect(reorderHome(layout, ids, 0, 1).order, [
        'b',
        'a',
        'c',
        'd',
        'archived',
      ]);
      expect(reorderHome(layout, ids, 3, 2).order, [
        'a',
        'b',
        'd',
        'c',
        'archived',
      ]);
      expect(reorderHome(layout, ids, 0, 3).order, [
        'b',
        'a',
        'c',
        'd',
        'archived',
      ]);
      expect(reorderHome(layout, ids, 3, 0).order, [
        'a',
        'b',
        'd',
        'c',
        'archived',
      ]);
      expect(reorderHome(layout, [], 0, 0), same(layout));
      expect(layout.order, ['a', 'b', 'c', 'd', 'archived']);
    },
  );
  test(
    'Old backups default to full cards; Home layout round-trips and validates',
    () {
      final old = {'theme': 'system', 'language': 'en', 'haptics': true};
      expect(AppPreferences.fromJson(old).homeLayout.compact, isFalse);
      const preferences = AppPreferences(
        homeLayout: HomeLayout(
          compact: true,
          pinnedIds: ['a'],
          order: ['b', 'a'],
        ),
      );
      final restored = AppPreferences.fromJson(preferences.toJson()).homeLayout;
      expect(restored.compact, isTrue);
      expect(restored.pinnedIds, ['a']);
      expect(restored.order, ['b', 'a']);
      for (final invalid in [
        null,
        [],
        {'compact': 'true'},
        {
          'order': ['a', 'a'],
        },
        {
          'pinnedIds': [4],
        },
      ]) {
        expect(
          () => AppPreferences.fromJson({...old, 'homeLayout': invalid}),
          throwsFormatException,
        );
      }
    },
  );
}
