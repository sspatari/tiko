part of '../../../main.dart';

IconData subscriptionIcon(String icon) => switch (icon) {
  'fitness' => Icons.fitness_center,
  'book' => Icons.menu_book,
  'coffee' => Icons.local_cafe_outlined,
  'travel' => Icons.flight,
  'other' => Icons.category_outlined,
  _ => Icons.confirmation_number_outlined,
};

Color subscriptionColor(String color) =>
    Color(int.tryParse('ff$color', radix: 16) ?? 0xff006B5E);

Color subscriptionDisplayColor(BuildContext context, String color) =>
    ColorScheme.fromSeed(
      seedColor: subscriptionColor(color),
      brightness: Theme.of(context).brightness,
    ).primary;

int subscriptionOrder(Subscription subscription) =>
    switch (subscriptionLifecycle(
      startDate: subscription.startDate,
      endDate: subscription.endDate,
      archived: subscription.isArchived,
      today: DateTime.now(),
    )) {
      SubscriptionLifecycle.active || SubscriptionLifecycle.expiringSoon => 0,
      SubscriptionLifecycle.upcoming => 1,
      SubscriptionLifecycle.expired => 2,
      SubscriptionLifecycle.archived => 3,
    };

String subscriptionStatus(BuildContext context, Subscription subscription) {
  if (subscription.isArchived) return context.l10n.archived;
  final end = subscription.endDate;
  return switch (subscriptionOrder(subscription)) {
    1 => context.l10n.startsOn(
      DateFormat.yMMMd().format(subscription.startDate),
    ),
    2 => context.l10n.expiredOn(DateFormat.yMMMd().format(end!)),
    _ =>
      end == null
          ? context.l10n.noExpiration
          : context.l10n.expiresOn(DateFormat.yMMMd().format(end)),
  };
}

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String message,
  String action, {
  bool destructive = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

Future<void> deleteUsage(
  BuildContext context,
  TikoDatabase database,
  String id,
) async {
  if (!await confirmAction(
    context,
    context.l10n.deleteEventLabel,
    context.l10n.thisUsageEventWillBePermanentlyDeleted,
    context.l10n.delete,
    destructive: true,
  )) {
    return;
  }
  try {
    await UsageRepository(database).delete(id);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotDeleteEventPleaseRetry)),
      );
    }
  }
}

class SubscriptionDetail extends ConsumerStatefulWidget {
  const SubscriptionDetail({super.key, required this.id});
  final String id;
  @override
  ConsumerState<SubscriptionDetail> createState() => _SubscriptionDetailState();
}

class _SubscriptionDetailState extends ConsumerState<SubscriptionDetail> {
  bool busy = false;

  void back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Future<void> manage(Subscription subscription, String action) async {
    if (busy) return;
    final repository = DriftSubscriptionRepository(ref.read(databaseProvider));
    if (action == 'edit' || action == 'renew') {
      final id = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            CreateCounter(subscription: subscription, renew: action == 'renew'),
      );
      if (id != null && mounted) context.pushReplacement('/subscriptions/$id');
      return;
    }
    if (action == 'delete') {
      final confirmed = await confirmAction(
        context,
        context.l10n.deleteSubscriptionLabel,
        context.l10n.deleteSubscriptionPrompt(subscription.name),
        context.l10n.delete,
        destructive: true,
      );
      if (!confirmed || !mounted) return;
    }
    setState(() => busy = true);
    try {
      if (action == 'delete') {
        await repository.delete(subscription.id);
        if (mounted) context.go('/');
      } else {
        await repository.archive(subscription.id, !subscription.isArchived);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotSaveChangesPleaseRetry)),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptions = ref.watch(subscriptionsProvider);
    return subscriptions.when(
      loading: () => Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: back)),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: back)),
        body: Center(child: Text(context.l10n.couldNotLoadSubscription)),
      ),
      data: (items) {
        final matches = items.where((s) => s.id == widget.id);
        if (matches.isEmpty) {
          return Scaffold(
            appBar: AppBar(leading: BackButton(onPressed: back)),
            body: Center(child: Text(context.l10n.subscriptionNotFound)),
          );
        }
        final subscription = matches.first;
        return Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: back),
            title: Text(subscription.name),
            actions: [
              IconButton(
                tooltip: context.l10n.usageHistory,
                icon: Icon(Icons.history),
                onPressed: () =>
                    context.push('/history?subscription=${subscription.id}'),
              ),
              PopupMenuButton<String>(
                enabled: !busy,
                tooltip: context.l10n.manageSubscription,
                onSelected: (value) => manage(subscription, value),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: ActionMenuLabel(
                      icon: Icons.edit_outlined,
                      label: context.l10n.editSubscription,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'renew',
                    child: ActionMenuLabel(
                      icon: Icons.autorenew,
                      label: context.l10n.renewSubscription,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: ActionMenuLabel(
                      icon: subscription.isArchived
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                      label: subscription.isArchived
                          ? context.l10n.restoreSubscription
                          : context.l10n.archiveSubscription,
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: ActionMenuLabel(
                      icon: Icons.delete_outline,
                      label: context.l10n.deleteSubscription,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: ref
              .watch(
                historyProvider((
                  subscriptionId: widget.id,
                  from: null,
                  through: null,
                  limit: 50,
                )),
              )
              .when(
                loading: () => Center(child: CircularProgressIndicator()),
                error: (_, _) =>
                    Center(child: Text(context.l10n.couldNotLoadUsage)),
                data: (events) {
                  final history =
                      events
                          .where((e) => e.subscriptionId == subscription.id)
                          .toList()
                        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
                  final totals = ref.watch(totalsProvider);
                  if (totals.hasError) {
                    return Center(child: Text(context.l10n.couldNotLoadUsage));
                  }
                  if (!totals.hasValue) return BrandLoading();
                  final total = totals.requireValue[subscription.id] ?? 0;
                  final summary = FinancialCalculator().calculate(
                    costMinorUnits: subscription.totalCostMinorUnits,
                    quantities: total == 0 ? [] : [total],
                    referenceMinorUnits:
                        subscription.referenceUnitPriceMinorUnits,
                  );
                  String money(int value) =>
                      Money.format(value, subscription.currencyCode);
                  final periods =
                      items
                          .where(
                            (s) =>
                                s.id != subscription.id &&
                                subscription.renewalGroupId != null &&
                                s.renewalGroupId == subscription.renewalGroupId,
                          )
                          .toList()
                        ..sort((a, b) => b.startDate.compareTo(a.startDate));
                  return ListView(
                    padding: EdgeInsets.all(20),
                    children: [
                      Row(
                        children: [
                          Icon(
                            subscriptionIcon(subscription.icon),
                            size: 40,
                            color: subscriptionDisplayColor(
                              context,
                              subscription.color,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SubscriptionStatusBadge(
                                  subscription: subscription,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  subscriptionStatus(context, subscription),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      if (subscription.description != null)
                        Text(subscription.description!),
                      Text(subscription.category),
                      SizedBox(height: 20),
                      AnimatedUsageTotal(uses: summary.uses),
                      SizedBox(height: 16),
                      RecordUsageButton(subscription: subscription),
                      SizedBox(height: 20),
                      _Metric(
                        context.l10n.averageCostPerUse,
                        summary.averageMinorUnits == null
                            ? context.l10n.noUsesYet
                            : money(summary.averageMinorUnits!),
                      ),
                      _Metric(context.l10n.prepaidCost, money(summary.cost)),
                      _Metric(
                        context.l10n.startDate,
                        DateFormat.yMMMd().format(subscription.startDate),
                      ),
                      _Metric(
                        context.l10n.endDate,
                        subscription.endDate == null
                            ? context.l10n.noExpiration
                            : DateFormat.yMMMd().format(subscription.endDate!),
                      ),
                      if (summary.reference != null) ...[
                        _Metric(
                          context.l10n.singleUsePrice,
                          money(summary.reference!),
                        ),
                        _Metric(
                          context.l10n.equivalentIndividualCost,
                          money(summary.equivalentMinorUnits!),
                        ),
                        _Metric(
                          summary.savingsMinorUnits! < 0
                              ? context.l10n.unrecoveredCost
                              : context.l10n.netSavings,
                          money(summary.savingsMinorUnits!.abs()),
                        ),
                        _Metric(
                          context.l10n.breakEvenThreshold,
                          context.l10n.uses(summary.breakEvenUses!),
                        ),
                        _Metric(
                          context.l10n.remainingUntilBreakEven,
                          context.l10n.uses(summary.remainingUses!),
                        ),
                        if (summary.progress != null) ...[
                          SizedBox(height: 12),
                          UsageProgress(value: summary.progress!),
                          _Metric(
                            context.l10n.breakEvenProgress,
                            NumberFormat('0.0%').format(summary.progress!),
                          ),
                        ],
                        if (summary.savingsPercentage != null)
                          _Metric(
                            context.l10n.savingsPercentage,
                            NumberFormat(
                              '0.0%',
                            ).format(summary.savingsPercentage! / 100),
                          ),
                      ],
                      if (periods.isNotEmpty) ...[
                        Divider(height: 32),
                        Text(
                          context.l10n.relatedSubscriptionPeriods,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        for (final period in periods)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(period.name),
                            subtitle: Text(
                              '${DateFormat.yMMMd().format(period.startDate)} · ${subscriptionStatus(context, period)}',
                            ),
                            trailing: Icon(Icons.chevron_right),
                            onTap: () =>
                                context.push('/subscriptions/${period.id}'),
                          ),
                      ],
                      Divider(height: 32),
                      Text(
                        context.l10n.recentUsage,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (history.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(context.l10n.noUsesRecordedYet),
                        ),
                      TextButton.icon(
                        onPressed: () => context.push(
                          '/history?subscription=${subscription.id}',
                        ),
                        icon: Icon(Icons.history),
                        label: Text(context.l10n.viewFullHistory),
                      ),
                      for (final event in history.take(50))
                        ListTile(
                          onTap: () => showUsageEditor(
                            context,
                            subscription: subscription,
                            event: event,
                          ),
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            DateFormat.yMMMd().add_Hm().format(
                              event.occurredAt.toLocal(),
                            ),
                          ),
                          subtitle: Text(
                            '${context.l10n.uses(event.quantity)}${event.note == null ? '' : ' · ${event.note}'}',
                          ),
                          trailing: IconButton(
                            tooltip: context.l10n.deleteEvent,
                            color: Theme.of(context).colorScheme.error,
                            icon: Icon(Icons.delete_outline),
                            onPressed: () => deleteUsage(
                              context,
                              ref.read(databaseProvider),
                              event.id,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 16,
      runSpacing: 4,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}
