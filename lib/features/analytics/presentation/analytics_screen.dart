part of '../../../main.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String? selectedId;
  int period = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.analytics)),
    body: ref
        .watch(subscriptionsProvider)
        .when(
          loading: () => BrandLoading(),
          error: (_, _) =>
              Center(child: Text(context.l10n.couldNotLoadSubscriptions)),
          data: (subscriptions) {
            if (subscriptions.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    context
                        .l10n
                        .createASubscriptionAndRecordAUseToSeeYourPatterns,
                  ),
                ),
              );
            }
            final sorted = [...subscriptions]
              ..sort((a, b) => a.name.compareTo(b.name));
            final selected = sorted
                .where((s) => s.id == selectedId)
                .firstOrNull;
            return ref
                .watch(eventsProvider)
                .when(
                  loading: () => BrandLoading(),
                  error: (_, _) =>
                      Center(child: Text(context.l10n.couldNotLoadUsage)),
                  data: (events) {
                    final now = DateTime.now();
                    final today = localDay(now);
                    final stats = selected == null
                        ? null
                        : AnalyticsCalculator().calculate(
                            selected,
                            events,
                            now: now,
                          );
                    final daily = stats?.daily ?? <DateTime, int>{};
                    if (selected == null) {
                      for (final event in events) {
                        daily.update(
                          localDay(event.occurredAt),
                          (value) => value + event.quantity,
                          ifAbsent: () => event.quantity,
                        );
                      }
                    }
                    final bins = <({String label, int count})>[];
                    for (var i = 6; i >= 0; i--) {
                      final start = period == 0
                          ? DateTime(today.year, today.month, today.day - i)
                          : period == 1
                          ? DateTime(
                              today.year,
                              today.month,
                              today.day - (today.weekday - 1) - i * 7,
                            )
                          : DateTime(today.year, today.month - i);
                      final end = period == 0
                          ? nextLocalDay(start)
                          : period == 1
                          ? DateTime(start.year, start.month, start.day + 7)
                          : DateTime(start.year, start.month + 1);
                      final count = daily.entries
                          .where(
                            (e) =>
                                !e.key.isBefore(start) && e.key.isBefore(end),
                          )
                          .fold(0, (sum, e) => sum + e.value);
                      bins.add((
                        label: period == 2
                            ? DateFormat.MMM().format(start)
                            : DateFormat.MMMd().format(start),
                        count: count,
                      ));
                    }
                    final maxCount = bins.fold(
                      1,
                      (max, bin) => bin.count > max ? bin.count : max,
                    );
                    final total =
                        stats?.total ??
                        events.fold<int>(0, (sum, e) => sum + e.quantity);
                    final summary = selected == null
                        ? null
                        : FinancialCalculator().calculate(
                            costMinorUnits: selected.totalCostMinorUnits,
                            quantities: events
                                .where((e) => e.subscriptionId == selected.id)
                                .map((e) => e.quantity),
                            referenceMinorUnits:
                                selected.referenceUnitPriceMinorUnits,
                          );
                    return ListView(
                      padding: EdgeInsets.all(20),
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: selected?.id ?? '',
                          decoration: InputDecoration(
                            labelText: context.l10n.subscription,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: '',
                              child: Text(context.l10n.allSubscriptions),
                            ),
                            for (final s in sorted)
                              DropdownMenuItem(
                                value: s.id,
                                child: Text(
                                  s.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) => setState(
                            () => selectedId = value == '' ? null : value,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          context.l10n.uses(total),
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        Text(context.l10n.totalRecordedUsage),
                        SizedBox(height: 24),
                        SegmentedButton<int>(
                          segments: [
                            ButtonSegment(
                              value: 0,
                              label: Text(context.l10n.daily),
                            ),
                            ButtonSegment(
                              value: 1,
                              label: Text(context.l10n.weekly),
                            ),
                            ButtonSegment(
                              value: 2,
                              label: Text(context.l10n.monthly),
                            ),
                          ],
                          selected: {period},
                          onSelectionChanged: (value) =>
                              setState(() => period = value.first),
                        ),
                        SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              children: [
                                for (final bin in bins)
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 6),
                                    child: Semantics(
                                      label: context.l10n.chartTooltip(
                                        bin.label,
                                        bin.count,
                                      ),
                                      excludeSemantics: true,
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 64,
                                            child: Text(bin.label),
                                          ),
                                          Expanded(
                                            child: LinearProgressIndicator(
                                              value: bin.count / maxCount,
                                              minHeight: 14,
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          SizedBox(
                                            width: 40,
                                            child: Text(
                                              '${bin.count}',
                                              textAlign: TextAlign.end,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          context.l10n.last12Weeks,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  for (var d = 0; d < 7; d++)
                                    SizedBox(
                                      height: 24,
                                      width: 40,
                                      child: Text(
                                        DateFormat.E().format(
                                          DateTime(2026, 1, 5 + d),
                                        ),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelSmall,
                                      ),
                                    ),
                                ],
                              ),
                              for (var week = 0; week < 12; week++)
                                Column(
                                  children: [
                                    for (
                                      var weekday = 0;
                                      weekday < 7;
                                      weekday++
                                    )
                                      Builder(
                                        builder: (context) {
                                          final date = DateTime(
                                            today.year,
                                            today.month,
                                            today.day -
                                                today.weekday +
                                                1 -
                                                (11 - week) * 7 +
                                                weekday,
                                          );
                                          final count = daily[date] ?? 0;
                                          return Padding(
                                            padding: EdgeInsets.all(2),
                                            child: Tooltip(
                                              triggerMode:
                                                  TooltipTriggerMode.tap,
                                              message: context.l10n
                                                  .chartTooltip(
                                                    DateFormat.yMMMd().format(
                                                      date,
                                                    ),
                                                    count,
                                                  ),
                                              child: Semantics(
                                                label: context.l10n
                                                    .chartTooltip(
                                                      DateFormat.yMMMd().format(
                                                        date,
                                                      ),
                                                      count,
                                                    ),
                                                child: Container(
                                                  width: 20,
                                                  height: 20,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          5,
                                                        ),
                                                    color: date.isAfter(today)
                                                        ? Colors.transparent
                                                        : count == 0
                                                        ? Theme.of(context)
                                                              .colorScheme
                                                              .surfaceContainerHighest
                                                        : Theme.of(context)
                                                              .colorScheme
                                                              .primary
                                                              .withValues(
                                                                alpha:
                                                                    (.3 +
                                                                            count *
                                                                                .1)
                                                                        .clamp(
                                                                          .3,
                                                                          1,
                                                                        ),
                                                              ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          context
                              .l10n
                              .lighterSquaresIndicateFewerUsesTapASquareForItsDate,
                        ),
                        if (stats != null &&
                            selected != null &&
                            summary != null) ...[
                          Divider(height: 32),
                          Text(
                            context.l10n.actualResults,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          _Metric(
                            context.l10n.averageUsesPerWeek,
                            (stats.usesPerWeek == null
                                    ? null
                                    : NumberFormat(
                                        '0.0',
                                      ).format(stats.usesPerWeek)) ??
                                context.l10n.notAvailable,
                          ),
                          _Metric(
                            context.l10n.averageUsesPerMonth,
                            (stats.usesPerMonth == null
                                    ? null
                                    : NumberFormat(
                                        '0.0',
                                      ).format(stats.usesPerMonth)) ??
                                context.l10n.notAvailable,
                          ),
                          _Metric(
                            context.l10n.daysSinceLastUse,
                            stats.daysSinceLastUse?.toString() ??
                                context.l10n.noUsesYet,
                          ),
                          _Metric(
                            context.l10n.averageCostPerUse,
                            summary.averageMinorUnits == null
                                ? context.l10n.noUsesYet
                                : Money.format(
                                    summary.averageMinorUnits!,
                                    selected.currencyCode,
                                  ),
                          ),
                          if (summary.progress != null)
                            _Metric(
                              context.l10n.breakEvenProgress,
                              NumberFormat('0.0%').format(summary.progress!),
                            ),
                          SizedBox(height: 20),
                          Text(
                            context.l10n.averageCostOverTime,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Builder(
                            builder: (context) {
                              final dates =
                                  daily.keys
                                      .where((date) => !date.isAfter(today))
                                      .toList()
                                    ..sort();
                              var cumulative = 0;
                              final averages = <({DateTime date, int value})>[];
                              for (final date in dates) {
                                cumulative += daily[date]!;
                                if (cumulative > 0) {
                                  averages.add((
                                    date: date,
                                    value:
                                        (summary.cost + cumulative ~/ 2) ~/
                                        cumulative,
                                  ));
                                }
                              }
                              final recent = averages
                                  .skip(
                                    averages.length > 7
                                        ? averages.length - 7
                                        : 0,
                                  )
                                  .toList();
                              final max = recent.fold<int>(
                                1,
                                (max, point) =>
                                    point.value > max ? point.value : max,
                              );
                              return Column(
                                children: [
                                  for (final point in recent)
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Wrap(
                                            alignment:
                                                WrapAlignment.spaceBetween,
                                            spacing: 16,
                                            children: [
                                              Text(
                                                DateFormat.yMMMd().format(
                                                  point.date,
                                                ),
                                              ),
                                              Text(
                                                Money.format(
                                                  point.value,
                                                  selected.currencyCode,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 6),
                                          LinearProgressIndicator(
                                            value: point.value / max,
                                            minHeight: 6,
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          SizedBox(height: 20),
                          Text(
                            context.l10n.projections,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 8),
                          Text(
                            context
                                .l10n
                                .estimatesFollowYourAveragePaceDuringValidityTheyAreNotGuaranteed,
                          ),
                          if (summary.reference != null)
                            _Metric(
                              context.l10n.estimatedBreakEvenDate,
                              summary.remainingUses == 0
                                  ? context.l10n.alreadyReached
                                  : stats.breakEvenDate == null
                                  ? context.l10n.notEnoughActivity
                                  : DateFormat.yMMMd().format(
                                      stats.breakEvenDate!,
                                    ),
                            ),
                          if (stats.breakEvenDate != null &&
                              selected.endDate != null &&
                              stats.breakEvenDate!.isAfter(
                                DateTime(
                                  selected.endDate!.year,
                                  selected.endDate!.month,
                                  selected.endDate!.day,
                                ),
                              ))
                            Text(
                              context.l10n.atThisPaceBreakEvenIsAfterExpiration,
                            ),
                          _Metric(
                            context.l10n.projectedCostPerUseAtExpiration,
                            stats.projectedAverageMinorUnits == null
                                ? context.l10n.notAvailable
                                : Money.format(
                                    stats.projectedAverageMinorUnits!,
                                    selected.currencyCode,
                                  ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            context
                                .l10n
                                .projectionsNeed7DaysOfHistoryWithActivityOnAtLeast3DatesExpiredAndArchivedP,
                          ),
                        ] else ...[
                          SizedBox(height: 24),
                          Text(
                            context
                                .l10n
                                .chooseASubscriptionForFinancialResultsAndProjections,
                          ),
                        ],
                      ],
                    );
                  },
                );
          },
        ),
  );
}
