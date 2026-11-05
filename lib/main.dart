import 'dart:convert';
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
part 'features/analytics/presentation/analytics_screen.dart';
part 'features/settings/presentation/settings_screen.dart';
part 'features/backup/presentation/backup_actions.dart';
part 'features/subscriptions/presentation/subscription_detail.dart';
part 'features/subscriptions/presentation/subscription_editor.dart';
part 'features/usage/presentation/record_usage_button.dart';
part 'features/usage/presentation/usage_history.dart';
part 'features/usage/presentation/usage_editor.dart';

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
    GoRoute(
      path: '/subscriptions/:id',
      builder: (_, state) =>
          SubscriptionDetail(id: state.pathParameters['id']!),
    ),
  ],
);
void main() => runApp(ProviderScope(child: Bootstrap()));

class TikoApp extends ConsumerWidget {
  const TikoApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(preferencesProvider);
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
  @override
  Widget build(BuildContext context) {
    final subscriptions = ref.watch(subscriptionsProvider);
    final events = ref.watch(totalsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tiko'),
            Text(context.l10n.everyUseCounts, style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            showDialog<void>(context: context, builder: (_) => CreateCounter()),
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
            final sorted = [...items]
              ..sort((a, b) {
                final order = subscriptionOrder(
                  a,
                ).compareTo(subscriptionOrder(b));
                return order == 0 ? a.name.compareTo(b.name) : order;
              });
            Widget buildCard(Subscription subscription) {
              final total = usage[subscription.id] ?? 0;
              final result = FinancialCalculator().calculate(
                costMinorUnits: subscription.totalCostMinorUnits,
                quantities: total == 0 ? [] : [total],
                referenceMinorUnits: subscription.referenceUnitPriceMinorUnits,
              );
              String money(int value) =>
                  Money.format(value, subscription.currencyCode);
              return Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          subscriptionIcon(subscription.icon),
                          color: subscriptionColor(subscription.color),
                        ),
                        title: Text(
                          subscription.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        subtitle: Text(
                          subscriptionStatus(context, subscription),
                        ),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () =>
                            context.push('/subscriptions/${subscription.id}'),
                      ),
                      SizedBox(height: 16),
                      Text(
                        context.l10n.uses(result.uses),
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      Text(
                        result.averageMinorUnits == null
                            ? context.l10n.noUsesRecordedYet
                            : context.l10n.costPerUse(
                                money(result.averageMinorUnits!),
                              ),
                      ),
                      Text(context.l10n.prepaid(money(result.cost))),
                      if (result.breakEvenUses != null) ...[
                        SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: result.progress?.clamp(0, 1) ?? 0,
                        ),
                        SizedBox(height: 8),
                        Text(context.l10n.remainingUses(result.remainingUses!)),
                      ],
                      SizedBox(height: 20),
                      RecordUsageButton(subscription: subscription),
                      TextButton(
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
