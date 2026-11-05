part of '../../../main.dart';

class CreateCounter extends ConsumerStatefulWidget {
  const CreateCounter({super.key, this.subscription, this.renew = false});
  final Subscription? subscription;
  final bool renew;
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
  final description = TextEditingController();
  final category = TextEditingController(text: 'Other');
  String icon = 'ticket';
  String color = '006B5E';
  String template = 'custom';

  @override
  void initState() {
    super.initState();
    final existing = widget.subscription;
    if (existing == null) return;
    name.text = existing.name;
    description.text = existing.description ?? '';
    category.text = existing.category;
    icon = existing.icon;
    color = existing.color;
    currency = existing.currencyCode;
    cost.text = Money.input(existing.totalCostMinorUnits, currency);
    reference.text = existing.referenceUnitPriceMinorUnits == null
        ? ''
        : Money.input(existing.referenceUnitPriceMinorUnits!, currency);
    start = DateTime(
      existing.startDate.year,
      existing.startDate.month,
      existing.startDate.day,
    );
    final oldEnd = existing.endDate;
    end = oldEnd == null
        ? null
        : DateTime(oldEnd.year, oldEnd.month, oldEnd.day);
    if (widget.renew) {
      final now = DateUtils.dateOnly(DateTime.now());
      start = end == null ? now : DateTime(end!.year, end!.month, end!.day + 1);
      if (start.isBefore(now)) start = now;
      end = oldEnd == null
          ? null
          : DateTime(
              start.year,
              start.month,
              start.day + oldEnd.difference(existing.startDate).inDays,
            );
    }
  }

  int? minor(String text) => Money.parse(text, currency);

  @override
  void dispose() {
    description.dispose();
    category.dispose();
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
      final existing = widget.subscription;
      final values = (existing?.toCompanion(false) ?? SubscriptionsCompanion())
          .copyWith(
            id: Value(existing?.id ?? Uuid().v4()),
            name: Value(name.text.trim()),
            description: Value(
              description.text.trim().isEmpty ? null : description.text.trim(),
            ),
            category: Value(
              category.text.trim().isEmpty ? 'Other' : category.text.trim(),
            ),
            icon: Value(icon),
            color: Value(color),
            totalCostMinorUnits: Value(minor(cost.text)!),
            currencyCode: Value(currency),
            referenceUnitPriceMinorUnits: Value(
              reference.text.trim().isEmpty ? null : minor(reference.text),
            ),
            startDate: Value(DateTime.utc(start.year, start.month, start.day)),
            endDate: Value(
              end == null
                  ? null
                  : DateTime.utc(end!.year, end!.month, end!.day),
            ),
            createdAt: Value(existing?.createdAt ?? now),
            updatedAt: Value(now),
          );
      final repository = DriftSubscriptionRepository(database);
      String? renewedId;
      if (widget.renew) {
        renewedId = await repository.renewWithSettings(existing!, values);
      } else {
        await repository.save(values);
      }
      if (mounted) Navigator.pop(context, renewedId);
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error = context.l10n.couldNotSaveCounterPleaseRetry;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: AlertDialog(
      title: Text(
        widget.renew
            ? context.l10n.renewSubscription
            : widget.subscription == null
            ? context.l10n.createCounter
            : context.l10n.editSubscription,
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.subscription == null) ...[
                  DropdownButtonFormField<String>(
                    initialValue: template,
                    decoration: InputDecoration(
                      labelText: context.l10n.starterTemplateOptional,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'custom',
                        child: Text(context.l10n.custom),
                      ),
                      DropdownMenuItem(
                        value: 'trolleybus',
                        child: Text(context.l10n.trolleybus),
                      ),
                      DropdownMenuItem(
                        value: 'gym',
                        child: Text(context.l10n.gym),
                      ),
                    ],
                    onChanged: (value) => setState(() {
                      template = value!;
                      if (value == 'trolleybus') {
                        name.text = context.l10n.trolleybus;
                        cost.text = '1134';
                        reference.text = '7';
                        currency = 'MDL';
                        icon = 'ticket';
                        end = null;
                      } else if (value == 'gym') {
                        name.text = context.l10n.gym;
                        cost.text = '645';
                        reference.clear();
                        currency = 'EUR';
                        icon = 'fitness';
                        final maxDay = DateUtils.getDaysInMonth(
                          start.year + 1,
                          start.month,
                        );
                        end = DateTime(
                          start.year + 1,
                          start.month,
                          start.day > maxDay ? maxDay : start.day,
                        );
                      }
                    }),
                  ),
                  SizedBox(height: 16),
                ],
                TextFormField(
                  controller: name,
                  decoration: InputDecoration(labelText: context.l10n.name),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? context.l10n.enterAName
                      : null,
                ),
                TextFormField(
                  controller: description,
                  decoration: InputDecoration(
                    labelText: context.l10n.descriptionOptional,
                  ),
                ),
                TextFormField(
                  controller: category,
                  decoration: InputDecoration(labelText: context.l10n.category),
                ),
                DropdownButtonFormField<String>(
                  key: ValueKey('icon:$icon'),
                  initialValue: icon,
                  decoration: InputDecoration(labelText: context.l10n.icon),
                  items:
                      {
                            icon,
                            'ticket',
                            'fitness',
                            'book',
                            'coffee',
                            'travel',
                            'other',
                          }
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Row(
                                children: [
                                  Icon(subscriptionIcon(value)),
                                  SizedBox(width: 12),
                                  Text(switch (value) {
                                    'ticket' => context.l10n.ticketIcon,
                                    'fitness' => context.l10n.fitnessIcon,
                                    'book' => context.l10n.bookIcon,
                                    'coffee' => context.l10n.coffeeIcon,
                                    'travel' => context.l10n.travelIcon,
                                    _ => context.l10n.otherIcon,
                                  }),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => icon = value!),
                ),
                DropdownButtonFormField<String>(
                  initialValue: color,
                  decoration: InputDecoration(labelText: context.l10n.color),
                  items:
                      {color, '006B5E', '3F51B5', '8E24AA', 'C65D00', 'B3261E'}
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    color: subscriptionColor(value),
                                  ),
                                  SizedBox(width: 12),
                                  Text(switch (value) {
                                    '006B5E' => context.l10n.teal,
                                    '3F51B5' => context.l10n.indigo,
                                    '8E24AA' => context.l10n.violet,
                                    'C65D00' => context.l10n.amber,
                                    'B3261E' => context.l10n.red,
                                    _ => context.l10n.color,
                                  }),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => color = value!),
                ),
                TextFormField(
                  controller: cost,
                  decoration: InputDecoration(
                    labelText: context.l10n.totalPrice,
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => minor(v ?? '') == null
                      ? context.l10n.enterAValidPrice
                      : null,
                ),
                DropdownButtonFormField<String>(
                  key: ValueKey('currency:$currency'),
                  initialValue: currency,
                  decoration: InputDecoration(labelText: context.l10n.currency),
                  items:
                      {
                            currency,
                            'MDL',
                            'EUR',
                            'USD',
                            'RON',
                            'GBP',
                            'JPY',
                            'KWD',
                          }
                          .toList()
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => currency = v!),
                ),
                TextFormField(
                  controller: reference,
                  decoration: InputDecoration(
                    labelText: context.l10n.singleUsePriceOptional,
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (v) =>
                      v == null || v.trim().isEmpty || (minor(v) ?? 0) > 0
                      ? null
                      : context.l10n.enterAPositivePrice,
                ),
                ListTile(
                  title: Text(context.l10n.startDate),
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
                  title: Text(context.l10n.endDateOptional),
                  trailing: end == null
                      ? null
                      : IconButton(
                          tooltip: context.l10n.clearEndDate,
                          icon: Icon(Icons.clear),
                          onPressed: () => setState(() => end = null),
                        ),
                  subtitle: Text(
                    end == null
                        ? context.l10n.noExpiration
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
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: saving ? null : save,
          child: Text(
            saving
                ? context.l10n.saving
                : widget.renew
                ? context.l10n.renew
                : widget.subscription == null
                ? context.l10n.create
                : context.l10n.save,
          ),
        ),
      ],
    ),
  );
}
