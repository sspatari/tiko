import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'core/database/database.dart';
import 'features/subscriptions/domain/financial_calculator.dart';

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
final eventsProvider = StreamProvider(
  (ref) => ref
      .watch(databaseProvider)
      .select(ref.watch(databaseProvider).usageEvents)
      .watch(),
);
final router = GoRouter(
  routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())],
);
void main() => runApp(const ProviderScope(child: TikoApp()));

class TikoApp extends StatelessWidget {
  const TikoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Tiko',
    routerConfig: router,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('en'), Locale('ro')],
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xff006B5E),
    ),
    darkTheme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: const Color(0xff006B5E),
    ),
  );
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeState();
}

class _HomeState extends ConsumerState<HomeScreen> {
  final pending = <String>{};
  Future<void> record(Subscription subscription) async {
    if (!pending.add(subscription.id)) return;
    try {
      final now = DateTime.now();
      final date = DateTime(now.year, now.month, now.day);
      final start = subscription.startDate;
      final end = subscription.endDate;
      if (date.isBefore(DateTime(start.year, start.month, start.day)) ||
          (end != null &&
              date.isAfter(DateTime(end.year, end.month, end.day)))) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Outside validity period'),
            content: const Text('Record this use anyway?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Record use'),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }
      final id = const Uuid().v4();
      final database = ref.read(databaseProvider);
      await database
          .into(database.usageEvents)
          .insert(
            UsageEventsCompanion.insert(
              id: id,
              subscriptionId: subscription.id,
              occurredAt: now.toUtc(),
              createdAt: now.toUtc(),
              updatedAt: now.toUtc(),
            ),
          );
      HapticFeedback.lightImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text('Recorded at ${DateFormat.Hm().format(now)}'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              try {
                await (database.delete(
                  database.usageEvents,
                )..where((e) => e.id.equals(id))).go();
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not undo. Please retry.'),
                    ),
                  );
                }
              }
            },
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this use. Please retry.'),
          ),
        );
      }
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      pending.remove(subscription.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptions = ref.watch(subscriptionsProvider);
    final events = ref.watch(eventsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tiko'),
            Text('Every use counts.', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const CreateCounter(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Create counter'),
      ),
      body: subscriptions.when(
        error: (_, _) => const Center(child: Text('Could not load counters.')),
        loading: () => const Center(child: CircularProgressIndicator()),
        data: (items) => events.when(
          error: (_, _) => const Center(child: Text('Could not load usage.')),
          loading: () => const Center(child: CircularProgressIndicator()),
          data: (usage) {
            if (items.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_outlined, size: 64),
                      SizedBox(height: 24),
                      Text(
                        'Make every use count',
                        style: TextStyle(fontSize: 26),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Create a counter for your pass, membership, or prepaid service.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            final sorted = [...items]..sort((a, b) => a.name.compareTo(b.name));
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final subscription = sorted[index];
                final history =
                    usage
                        .where((e) => e.subscriptionId == subscription.id)
                        .toList()
                      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
                final result = const FinancialCalculator().calculate(
                  costMinorUnits: subscription.totalCostMinorUnits,
                  quantities: history.map((e) => e.quantity),
                  referenceMinorUnits:
                      subscription.referenceUnitPriceMinorUnits,
                );
                final format = NumberFormat.currency(
                  name: subscription.currencyCode,
                );
                String money(int value) => format.format(value / 100);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          subscription.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${result.uses} uses',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        Text(
                          result.averageMinorUnits == null
                              ? 'No uses recorded yet'
                              : '${money(result.averageMinorUnits!)} / use',
                        ),
                        Text('${money(result.cost)} prepaid'),
                        if (result.breakEvenUses != null) ...[
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: result.progress?.clamp(0, 1) ?? 0,
                          ),
                          const SizedBox(height: 8),
                          Text('${result.remainingUses} uses until break-even'),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () => record(subscription),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(60),
                          ),
                          child: const Text(
                            '+1 USE',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                        ExpansionTile(
                          title: const Text('Usage history'),
                          children: history
                              .take(50)
                              .map(
                                (event) => ListTile(
                                  title: Text(
                                    DateFormat.yMMMd().add_Hm().format(
                                      event.occurredAt.toLocal(),
                                    ),
                                  ),
                                  subtitle: Text('${event.quantity} uses'),
                                  trailing: IconButton(
                                    tooltip: 'Delete event',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () async {
                                      await (ref
                                              .read(databaseProvider)
                                              .delete(
                                                ref
                                                    .read(databaseProvider)
                                                    .usageEvents,
                                              )
                                            ..where(
                                              (e) => e.id.equals(event.id),
                                            ))
                                          .go();
                                    },
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
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

class CreateCounter extends ConsumerStatefulWidget {
  const CreateCounter({super.key});
  @override
  ConsumerState<CreateCounter> createState() => _CreateState();
}

class _CreateState extends ConsumerState<CreateCounter> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final cost = TextEditingController();
  final reference = TextEditingController();
  String currency = 'MDL';
  DateTime start = DateTime.now();
  DateTime? end;
  bool saving = false;
  String? error;
  int? minor(String text) {
    final value = text.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value)) return null;
    final parts = value.split('.');
    return int.parse(parts[0]) * 100 +
        (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
  }

  @override
  void dispose() {
    name.dispose();
    cost.dispose();
    reference.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate() || saving) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final now = DateTime.now().toUtc();
      final database = ref.read(databaseProvider);
      await database
          .into(database.subscriptions)
          .insert(
            SubscriptionsCompanion.insert(
              id: const Uuid().v4(),
              name: name.text.trim(),
              totalCostMinorUnits: minor(cost.text)!,
              currencyCode: currency,
              referenceUnitPriceMinorUnits: Value(
                reference.text.trim().isEmpty ? null : minor(reference.text),
              ),
              startDate: DateTime.utc(start.year, start.month, start.day),
              endDate: Value(
                end == null
                    ? null
                    : DateTime.utc(end!.year, end!.month, end!.day),
              ),
              createdAt: now,
              updatedAt: now,
            ),
          );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error = 'Could not save counter. Please retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Create counter'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a name' : null,
              ),
              TextFormField(
                controller: cost,
                decoration: const InputDecoration(labelText: 'Total price'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) =>
                    minor(v ?? '') == null ? 'Enter a valid price' : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: currency,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: ['MDL', 'EUR', 'USD', 'RON', 'GBP']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => currency = v!),
              ),
              TextFormField(
                controller: reference,
                decoration: const InputDecoration(
                  labelText: 'Single-use price (optional)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty || (minor(v) ?? 0) > 0
                    ? null
                    : 'Enter a positive price',
              ),
              ListTile(
                title: const Text('Start date'),
                subtitle: Text(DateFormat.yMMMd().format(start)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: start,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null && mounted) {
                    setState(() {
                      start = date;
                      if (end != null && end!.isBefore(start)) end = null;
                    });
                  }
                },
              ),
              ListTile(
                title: const Text('End date (optional)'),
                subtitle: Text(
                  end == null
                      ? 'No expiration'
                      : DateFormat.yMMMd().format(end!),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: end ?? start,
                    firstDate: start,
                    lastDate: DateTime(2100),
                  );
                  if (date != null && mounted) setState(() => end = date);
                },
              ),
              if (error != null) Text(error!),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: saving ? null : save,
        child: Text(saving ? 'Saving…' : 'Create'),
      ),
    ],
  );
}
