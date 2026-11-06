import '../../../core/database/database.dart';
import '../../settings/data/home_layout.dart';
import '../../subscriptions/domain/subscription_lifecycle.dart';

List<Subscription> arrangeHomeSubscriptions(
  List<Subscription> subscriptions,
  HomeLayout layout,
  DateTime today,
) {
  final pinned = layout.pinnedIds.toSet();
  final positions = {for (final (index, id) in layout.order.indexed) id: index};
  int priority(Subscription subscription) => switch (subscriptionLifecycle(
    startDate: subscription.startDate,
    endDate: subscription.endDate,
    archived: subscription.isArchived,
    today: today,
  )) {
    SubscriptionLifecycle.active || SubscriptionLifecycle.expiringSoon => 0,
    SubscriptionLifecycle.upcoming => 1,
    SubscriptionLifecycle.expired => 2,
    SubscriptionLifecycle.archived => 3,
  };
  return [...subscriptions]..sort((a, b) {
    if (a.isArchived != b.isArchived) return a.isArchived ? 1 : -1;
    if (!a.isArchived) {
      if (pinned.contains(a.id) != pinned.contains(b.id)) {
        return pinned.contains(a.id) ? -1 : 1;
      }
      final position = (positions[a.id] ?? layout.order.length).compareTo(
        positions[b.id] ?? layout.order.length,
      );
      if (position != 0) return position;
    }
    final status = priority(a).compareTo(priority(b));
    if (status != 0) return status;
    final name = a.name.compareTo(b.name);
    return name == 0 ? a.id.compareTo(b.id) : name;
  });
}

/// Uses the final destination index supplied by Flutter's onReorderItem.
HomeLayout reorderHome(
  HomeLayout layout,
  List<String> visibleIds,
  int oldIndex,
  int newIndex,
) {
  if (oldIndex < 0 ||
      oldIndex >= visibleIds.length ||
      newIndex < 0 ||
      newIndex >= visibleIds.length) {
    return layout;
  }
  final ids = [...visibleIds];
  final pinnedCount = ids.where(layout.pinnedIds.contains).length;
  final first = oldIndex < pinnedCount ? 0 : pinnedCount;
  final last = oldIndex < pinnedCount ? pinnedCount - 1 : ids.length - 1;
  newIndex = newIndex.clamp(first, last);
  ids.insert(newIndex, ids.removeAt(oldIndex));
  return layout.copyWith(
    order: [...ids, ...layout.order.where((id) => !visibleIds.contains(id))],
  );
}
