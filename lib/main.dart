import 'dart:convert';
import 'features/settings/data/home_layout.dart';
import 'features/home/domain/home_order.dart';
import 'dart:async';
import 'features/subscriptions/domain/subscription_lifecycle.dart';
import 'dart:io';
import 'features/reminders/expiry_reminders.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'features/backup/data/backup_repository.dart';
import 'core/database/database.dart';
import 'core/utils/money.dart';
import 'core/localization/app_localizations.dart';
import 'features/analytics/domain/usage_analytics.dart';
import 'features/settings/data/preferences.dart';
import 'features/subscriptions/data/subscription_repository.dart';
import 'features/usage/data/usage_repository.dart';
import 'features/usage/domain/usage_dates.dart';
import 'features/subscriptions/domain/financial_calculator.dart';

part 'app/design.dart';
part 'features/home/presentation/home_customization.dart';
part 'features/analytics/presentation/analytics_screen.dart';
part 'features/settings/presentation/settings_screen.dart';
part 'features/backup/presentation/backup_actions.dart';
part 'features/subscriptions/presentation/subscription_detail.dart';
part 'features/subscriptions/presentation/break_even_message.dart';
part 'features/subscriptions/presentation/subscription_editor.dart';
part 'features/usage/presentation/record_usage_button.dart';
part 'features/usage/presentation/usage_history.dart';
part 'features/usage/presentation/usage_editor.dart';

final currentLocalDateProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  final timer = Timer(nextLocalDay(now).difference(now), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return now;
});

final databaseProvider = Provider((ref) {
  final database = TikoDatabase();
  ref.onDispose(() {
    database.close();
  });
  return database;
});
final subscriptionsProvider = StreamProvider(
  (ref) => ref
      .watch(databaseProvider)
      .select(ref.watch(databaseProvider).subscriptions)
      .watch(),
);
final totalsProvider = StreamProvider(
  (ref) => UsageRepository(ref.watch(databaseProvider)).watchTotals(),
);
final eventsProvider = StreamProvider(
  (ref) => ref
      .watch(databaseProvider)
      .select(ref.watch(databaseProvider).usageEvents)
      .watch(),
);
typedef HistoryQuery = ({
  String? subscriptionId,
  DateTime? from,
  DateTime? through,
  int limit,
});
final historyProvider = StreamProvider.autoDispose
    .family<List<UsageEvent>, HistoryQuery>(
      (ref, query) => UsageRepository(ref.watch(databaseProvider)).watchHistory(
        subscriptionId: query.subscriptionId,
        from: query.from,
        through: query.through,
        limit: query.limit,
      ),
    );

final router = GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/', builder: (_, _) => HomeScreen())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/analytics', builder: (_, _) => AnalyticsScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (_, state) => UsageHistory(
                initialSubscriptionId:
                    state.uri.queryParameters['subscription'],
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/settings', builder: (_, _) => SettingsScreen()),
          ],
        ),
      ],
    ),
    GoRoute(path: '/home-layout', builder: (_, _) => HomeCustomizationScreen()),
    GoRoute(
      path: '/subscriptions/:id',
      builder: (_, state) =>
          SubscriptionDetail(id: state.pathParameters['id']!),
    ),
  ],
);
final expiryReminderServiceProvider = Provider<ExpiryReminderService?>(
  (ref) => null,
);
final reminderRefreshProvider = NotifierProvider<ReminderRefresh, int>(
  ReminderRefresh.new,
);

class ReminderRefresh extends Notifier<int> {
  @override
  int build() => 0;
  void refresh() => state++;
}

final reminderSyncProvider = FutureProvider<void>((ref) async {
  ref.watch(reminderRefreshProvider);
  final service = ref.watch(expiryReminderServiceProvider);
  if (service == null) return;
  final preferences = ref.watch(
    preferencesProvider.select(
      (value) =>
          (language: value.language, expiryReminders: value.expiryReminders),
    ),
  );
  final subscriptions = ref.watch(subscriptionsProvider);
  if (!subscriptions.hasValue) return;
  final language = preferences.language == 'system'
      ? WidgetsBinding.instance.platformDispatcher.locale.languageCode
      : preferences.language;
  final l10n = await AppLocalizations.delegate.load(
    Locale(language == 'ro' ? 'ro' : 'en'),
  );
  await service.sync(
    subscriptions.requireValue,
    preferences.expiryReminders,
    l10n,
  );
});
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final service = Platform.isAndroid || Platform.isIOS
      ? ExpiryReminderService((id) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => router.go('/subscriptions/${Uri.encodeComponent(id)}'),
          );
          WidgetsBinding.instance.scheduleFrame();
        })
      : null;
  runApp(
    ProviderScope(
      overrides: [expiryReminderServiceProvider.overrideWithValue(service)],
      child: Bootstrap(),
    ),
  );
}

class TikoApp extends ConsumerWidget {
  const TikoApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(preferencesProvider);
    ref.watch(reminderSyncProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Tiko',
      routerConfig: router,
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: [Locale('en'), Locale('ro')],
      localeResolutionCallback: (device, _) {
        final locale = Locale(device?.languageCode == 'ro' ? 'ro' : 'en');
        Intl.defaultLocale = locale.languageCode;
        return locale;
      },
      locale: preferences.language == 'system'
          ? null
          : Locale(preferences.language),
      themeMode: switch (preferences.theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      theme: tikoTheme(Brightness.light),
      darkTheme: tikoTheme(Brightness.dark),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeState();
}

class _HomeState extends ConsumerState<HomeScreen> {
  final scroll = ScrollController();
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(currentLocalDateProvider);
    final layout = ref.watch(preferencesProvider).homeLayout;
    ref.listen(preferencesProvider.select((value) => value.homeLayout), (
      previous,
      next,
    ) {
      if (previous == next) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && scroll.hasClients) scroll.jumpTo(0);
      });
    });
    void createCounter() =>
        showDialog<void>(context: context, builder: (_) => CreateCounter());
    final smallCreateButton =
        layout.compact || MediaQuery.textScalerOf(context).scale(14) > 18;
    final subscriptions = ref.watch(subscriptionsProvider);
    final events = ref.watch(totalsProvider);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: context.l10n.customizeHome,
            icon: Icon(Icons.dashboard_customize_outlined),
            onPressed: () => context.push('/home-layout'),
          ),
        ],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tiko'),
            Text(context.l10n.everyUseCounts, style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
      floatingActionButton: smallCreateButton
          ? FloatingActionButton(
              onPressed: createCounter,
              tooltip: context.l10n.createCounter,
              child: Icon(Icons.add),
            )
          : FloatingActionButton.extended(
              onPressed: createCounter,
              icon: Icon(Icons.add),
              label: Text(context.l10n.createCounter),
            ),
      body: subscriptions.when(
        error: (_, _) => Center(child: Text(context.l10n.couldNotLoadCounters)),
        loading: () => BrandLoading(),
        data: (items) => events.when(
          error: (_, _) => Center(child: Text(context.l10n.couldNotLoadUsage)),
          loading: () => BrandLoading(),
          data: (usage) {
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BrandMark(size: 72),
                      SizedBox(height: 24),
                      Text(
                        context.l10n.makeEveryUseCount,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -.7,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        context
                            .l10n
                            .createACounterForYourPassMembershipOrPrepaidService,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            final sorted = arrangeHomeSubscriptions(items, layout, today);
            Widget buildCard(Subscription subscription) {
              final iconColor = subscriptionDisplayColor(
                context,
                subscription.color,
              );
              final total = usage[subscription.id] ?? 0;
              final result = FinancialCalculator().calculate(
                costMinorUnits: subscription.totalCostMinorUnits,
                quantities: total == 0 ? [] : [total],
                referenceMinorUnits: subscription.referenceUnitPriceMinorUnits,
              );
              String money(int value) =>
                  Money.format(value, subscription.currencyCode);
              return Card(
                key: ValueKey(subscription.id),
                child: Padding(
                  padding: EdgeInsets.all(layout.compact ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            subscriptionIcon(subscription.icon),
                            color: iconColor,
                          ),
                        ),
                        title: Text(
                          subscription.name,
                          style: layout.compact
                              ? Theme.of(context).textTheme.titleMedium
                              : Theme.of(context).textTheme.titleLarge,
                        ),
                        subtitle: Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SubscriptionStatusBadge(
                                subscription: subscription,
                              ),
                              SizedBox(height: 6),
                              Text(subscriptionStatus(context, subscription)),
                            ],
                          ),
                        ),
                        trailing:
                            layout.pinnedIds.contains(subscription.id) &&
                                !subscription.isArchived
                            ? Tooltip(
                                message: context.l10n.pinnedStatus,
                                child: Icon(Icons.push_pin, size: 20),
                              )
                            : Icon(Icons.chevron_right),
                        onTap: () =>
                            context.push('/subscriptions/${subscription.id}'),
                      ),
                      SizedBox(height: 16),
                      AnimatedUsageTotal(
                        uses: result.uses,
                        style: layout.compact
                            ? Theme.of(context).textTheme.titleLarge
                            : null,
                      ),
                      if (!layout.compact || result.averageMinorUnits != null)
                        Text(
                          result.averageMinorUnits == null
                              ? context.l10n.noUsesRecordedYet
                              : context.l10n.costPerUse(
                                  money(result.averageMinorUnits!),
                                ),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      if (!layout.compact) ...[
                        SizedBox(height: 6),
                        Text(
                          context.l10n.prepaid(money(result.cost)),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                      if (!layout.compact &&
                          result.costRecoveryState !=
                              CostRecoveryState.unavailable) ...[
                        SizedBox(height: 16),
                        if (result.progress != null) ...[
                          UsageProgress(value: result.progress!),
                          SizedBox(height: 8),
                        ],
                        BreakEvenMessage(
                          summary: result,
                          periodClosed: subscriptionOrder(subscription) >= 2,
                        ),
                      ],
                      if (layout.compact &&
                          result.costRecoveryState ==
                              CostRecoveryState.recovered)
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: BreakEvenMessage(summary: result),
                        ),
                      SizedBox(height: 20),
                      RecordUsageButton(subscription: subscription),
                      if (!layout.compact)
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () =>
                              context.push('/subscriptions/${subscription.id}'),
                          child: Text(context.l10n.detailsHistory),
                        ),
                    ],
                  ),
                ),
              );
            }

            final visible = sorted.where((s) => !s.isArchived).toList();
            final archived = sorted.where((s) => s.isArchived).toList();
            return ListView.builder(
              controller: scroll,
              padding: EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: visible.length + (archived.isEmpty ? 0 : 1),
              itemBuilder: (context, index) => index < visible.length
                  ? buildCard(visible[index])
                  : ExpansionTile(
                      title: Text(context.l10n.archivedSubscriptions),
                      children: [
                        for (final subscription in archived)
                          buildCard(subscription),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}
