part of '../../../main.dart';

class HomeCustomizationScreen extends ConsumerStatefulWidget {
  const HomeCustomizationScreen({super.key});
  @override
  ConsumerState<HomeCustomizationScreen> createState() =>
      _HomeCustomizationState();
}

class _HomeCustomizationState extends ConsumerState<HomeCustomizationScreen> {
  late HomeLayout draft;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    draft = ref.read(preferencesProvider).homeLayout;
  }

  Future<void> save() async {
    final existing = ref
        .read(subscriptionsProvider)
        .requireValue
        .map((s) => s.id)
        .toSet();
    setState(() => saving = true);
    try {
      final layout = draft.copyWith(
        pinnedIds: draft.pinnedIds.where(existing.contains).toList(),
        order: draft.order.where(existing.contains).toList(),
      );
      final controller = ref.read(preferencesProvider.notifier);
      await controller.save(
        ref.read(preferencesProvider).copyWith(homeLayout: layout),
      );
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotSaveSettingsPleaseRetry)),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptions = ref.watch(subscriptionsProvider);
    final today = ref.watch(currentLocalDateProvider);
    return PopScope(
      canPop: !saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.customizeHome),
          actions: [
            TextButton(
              onPressed: saving || !subscriptions.hasValue ? null : save,
              child: Text(saving ? context.l10n.saving : context.l10n.save),
            ),
          ],
        ),
        body: subscriptions.when(
          loading: () => BrandLoading(),
          error: (_, _) =>
              Center(child: Text(context.l10n.couldNotLoadCounters)),
          data: (items) {
            final ordered = arrangeHomeSubscriptions(
              items,
              draft,
              today,
            ).where((s) => !s.isArchived).toList();
            final ids = ordered.map((s) => s.id).toList();
            final pinnedCount = ids.where(draft.pinnedIds.contains).length;
            void move(int from, int to) =>
                setState(() => draft = reorderHome(draft, ids, from, to));
            return ReorderableListView.builder(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
              buildDefaultDragHandles: false,
              onReorderItem: saving ? (_, _) {} : move,
              header: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.l10n.compactHome),
                    subtitle: Text(context.l10n.compactHomeDescription),
                    value: draft.compact,
                    onChanged: saving
                        ? null
                        : (value) => setState(
                            () => draft = draft.copyWith(compact: value),
                          ),
                  ),
                  Divider(height: 32),
                  Text(
                    context.l10n.arrangeSubscriptions,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    context.l10n.arrangeSubscriptionsHelp,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 16),
                  if (ordered.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(context.l10n.noSubscriptionsToArrange),
                    ),
                ],
              ),
              footer: Padding(
                padding: EdgeInsets.only(top: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: saving
                        ? null
                        : () => setState(() => draft = const HomeLayout()),
                    icon: Icon(Icons.restart_alt),
                    label: Text(context.l10n.resetHomeLayout),
                  ),
                ),
              ),
              itemCount: ordered.length,
              itemBuilder: (context, index) {
                final subscription = ordered[index];
                final pinned = draft.pinnedIds.contains(subscription.id);
                final first = pinned ? 0 : pinnedCount;
                final last = pinned ? pinnedCount - 1 : ordered.length - 1;
                return ListTile(
                  key: ValueKey(subscription.id),
                  contentPadding: EdgeInsets.zero,
                  leading: ReorderableDragStartListener(
                    index: index,
                    enabled: !saving,
                    child: Tooltip(
                      message: context.l10n.dragToReorder,
                      child: SizedBox(
                        width: 40,
                        height: 48,
                        child: Icon(Icons.drag_indicator),
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      if (pinned) ...[
                        Icon(
                          Icons.push_pin,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 8),
                      ],
                      Expanded(child: Text(subscription.name)),
                    ],
                  ),
                  subtitle: Text(subscriptionStatus(context, subscription)),
                  trailing: PopupMenuButton<String>(
                    enabled: !saving,
                    tooltip: context.l10n.arrangeSubscriptionActions(
                      subscription.name,
                    ),
                    onSelected: (action) {
                      if (action == 'pin') {
                        setState(
                          () => draft = draft.copyWith(
                            pinnedIds: pinned
                                ? draft.pinnedIds
                                      .where((id) => id != subscription.id)
                                      .toList()
                                : [...draft.pinnedIds, subscription.id],
                          ),
                        );
                      } else if (action == 'up') {
                        move(index, index - 1);
                      } else if (action == 'down') {
                        move(index, index + 1);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'pin',
                        child: ActionMenuLabel(
                          icon: pinned
                              ? Icons.push_pin_outlined
                              : Icons.push_pin,
                          label: pinned
                              ? context.l10n.unpinSubscription
                              : context.l10n.pinSubscription,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'up',
                        enabled: index > first,
                        child: ActionMenuLabel(
                          icon: Icons.arrow_upward,
                          label: context.l10n.moveUp,
                          color: index > first
                              ? null
                              : Theme.of(context).disabledColor,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'down',
                        enabled: index < last,
                        child: ActionMenuLabel(
                          icon: Icons.arrow_downward,
                          label: context.l10n.moveDown,
                          color: index < last
                              ? null
                              : Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
