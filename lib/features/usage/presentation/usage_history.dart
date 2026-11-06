part of '../../../main.dart';

class UsageHistory extends ConsumerStatefulWidget {
  const UsageHistory({super.key, this.initialSubscriptionId});
  final String? initialSubscriptionId;
  @override
  ConsumerState<UsageHistory> createState() => _UsageHistoryState();
}

class _UsageHistoryState extends ConsumerState<UsageHistory> {
  String? subscriptionId;
  DateTimeRange? range;
  int limit = 50;
  bool exporting = false;

  @override
  void initState() {
    super.initState();
    subscriptionId = widget.initialSubscriptionId;
  }

  @override
  void didUpdateWidget(covariant UsageHistory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSubscriptionId != widget.initialSubscriptionId) {
      subscriptionId = widget.initialSubscriptionId;
      limit = 50;
    }
  }

  Future<void> filterDates() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
      initialDateRange: range,
    );
    if (selected != null && mounted) {
      setState(() {
        range = selected;
        limit = 50;
      });
    }
  }

  String dateLabel(DateTime date) {
    final today = localDay(DateTime.now());
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final formatted = DateFormat.yMMMMd().format(date);
    if (date == today) return context.l10n.todayDate(formatted);
    if (date == yesterday) return context.l10n.yesterdayDate(formatted);
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final subscriptions = ref.watch(subscriptionsProvider);
    final query = (
      subscriptionId: subscriptionId,
      from: range?.start,
      through: range?.end,
      limit: limit + 1,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.usageHistory),
        actions: [
          IconButton(
            tooltip: context.l10n.exportUsageCSV,
            icon: Icon(Icons.ios_share),
            onPressed: exporting
                ? null
                : () async {
                    setState(() => exporting = true);
                    try {
                      final csv =
                          await BackupRepository(
                            ref.read(databaseProvider),
                          ).exportCsv(
                            subscriptionId: subscriptionId,
                            from: range?.start,
                            through: range?.end,
                          );
                      if (context.mounted) {
                        await shareExport(
                          context,
                          csv,
                          'tiko-history.csv',
                          'text/csv',
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context
                                  .l10n
                                  .couldNotCompleteExportOrImportPleaseRetry,
                            ),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => exporting = false);
                    }
                  },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final matches = subscriptions.asData?.value.where(
            (s) => s.id == subscriptionId,
          );
          showUsageEditor(
            context,
            subscription: matches == null || matches.isEmpty
                ? null
                : matches.first,
          );
        },
        icon: Icon(Icons.add),
        label: Text(context.l10n.addForgottenUse),
      ),
      body: subscriptions.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            Center(child: Text(context.l10n.couldNotLoadSubscriptions)),
        data: (items) {
          final byId = {for (final item in items) item.id: item};
          final selectedExists =
              subscriptionId == null || byId.containsKey(subscriptionId);
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: DropdownButtonFormField<String>(
                  key: ValueKey(subscriptionId),
                  initialValue: selectedExists ? subscriptionId ?? '' : '',
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.subscription,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text(context.l10n.allSubscriptions),
                    ),
                    for (final item in [
                      ...items,
                    ]..sort((a, b) => a.name.compareTo(b.name)))
                      DropdownMenuItem(
                        value: item.id,
                        child: Text(
                          item.isArchived
                              ? context.l10n.archivedName(item.name)
                              : item.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    subscriptionId = value == '' ? null : value;
                    limit = 50;
                  }),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: filterDates,
                        icon: Icon(Icons.date_range),
                        label: Text(
                          range == null
                              ? context.l10n.allDates
                              : '${DateFormat.yMMMd().format(range!.start)} – ${DateFormat.yMMMd().format(range!.end)}',
                        ),
                      ),
                    ),
                    if (range != null)
                      IconButton(
                        tooltip: context.l10n.clearDateFilter,
                        icon: Icon(Icons.clear),
                        onPressed: () => setState(() {
                          range = null;
                          limit = 50;
                        }),
                      ),
                  ],
                ),
              ),
              if (!selectedExists)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    context
                        .l10n
                        .subscriptionNoLongerExistsSelectAnotherSubscription,
                  ),
                ),
              Expanded(
                child: ref
                    .watch(historyProvider(query))
                    .when(
                      loading: () => Center(child: CircularProgressIndicator()),
                      error: (_, _) => Center(
                        child: TextButton(
                          onPressed: () =>
                              ref.invalidate(historyProvider(query)),
                          child: Text(
                            context.l10n.couldNotLoadHistoryTapToRetry,
                          ),
                        ),
                      ),
                      data: (events) {
                        if (events.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                context.l10n.noUsageEventsForTheseFilters,
                              ),
                            ),
                          );
                        }
                        final count = events.length > limit
                            ? limit
                            : events.length;
                        return ListView.builder(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: count + (events.length > limit ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == count) {
                              return TextButton(
                                onPressed: () => setState(() => limit += 50),
                                child: Text(context.l10n.loadMore),
                              );
                            }
                            final event = events[index];
                            final subscription = byId[event.subscriptionId];
                            final day = localDay(event.occurredAt);
                            final heading =
                                index == 0 ||
                                day != localDay(events[index - 1].occurredAt);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (heading)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: 20,
                                      bottom: 4,
                                    ),
                                    child: Text(
                                      dateLabel(day),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  onTap: subscription == null
                                      ? null
                                      : () => showUsageEditor(
                                          context,
                                          subscription: subscription,
                                          event: event,
                                        ),
                                  title: Text(
                                    '${DateFormat.Hm().format(event.occurredAt.toLocal())} · ${subscription?.name ?? context.l10n.subscriptionUnavailable}',
                                  ),
                                  subtitle: Text(
                                    '${context.l10n.uses(event.quantity)}${event.note == null ? '' : '\n${event.note}'}',
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    tooltip: context.l10n.eventActions,
                                    onSelected: (action) {
                                      if (action == 'edit' &&
                                          subscription != null) {
                                        showUsageEditor(
                                          context,
                                          subscription: subscription,
                                          event: event,
                                        );
                                      }
                                      if (action == 'delete') {
                                        deleteUsage(
                                          context,
                                          ref.read(databaseProvider),
                                          event.id,
                                        );
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      if (subscription != null)
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: ActionMenuLabel(
                                            icon: Icons.edit_outlined,
                                            label: context.l10n.editEvent,
                                          ),
                                        ),
                                      if (subscription != null)
                                        PopupMenuDivider(),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: ActionMenuLabel(
                                          icon: Icons.delete_outline,
                                          label: context.l10n.deleteEvent,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}
