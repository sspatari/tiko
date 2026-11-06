part of '../../../main.dart';

Future<void> showUsageEditor(
  BuildContext context, {
  Subscription? subscription,
  UsageEvent? event,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => UsageEditor(subscription: subscription, event: event),
);

class UsageEditor extends ConsumerStatefulWidget {
  const UsageEditor({super.key, this.subscription, this.event});
  final Subscription? subscription;
  final UsageEvent? event;
  @override
  ConsumerState<UsageEditor> createState() => _UsageEditorState();
}

class _UsageEditorState extends ConsumerState<UsageEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController quantity;
  late final TextEditingController note;
  late DateTime occurredAt;
  String? subscriptionId;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    quantity = TextEditingController(text: '${widget.event?.quantity ?? 1}');
    note = TextEditingController(text: widget.event?.note ?? '');
    occurredAt = widget.event?.occurredAt.toLocal() ?? DateTime.now();
    subscriptionId = widget.event?.subscriptionId ?? widget.subscription?.id;
  }

  @override
  void dispose() {
    quantity.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> save(List<Subscription> items) async {
    if (saving || !(form.currentState?.validate() ?? false)) return;
    final matches = items.where((s) => s.id == subscriptionId);
    if (matches.isEmpty) return;
    final subscription = matches.first;
    if (widget.event == null && subscription.isArchived) return;
    FocusScope.of(context).unfocus();
    setState(() {
      saving = true;
      error = null;
    });
    try {
      if (outsideValidity(subscription, occurredAt)) {
        final confirmed = await confirmAction(
          context,
          context.l10n.outsideValidityPeriod,
          context
              .l10n
              .thisDateIsOutsideTheSubscriptionValidityPeriodSaveThisUseAnyway,
          context.l10n.saveAnyway,
        );
        if (!confirmed || !mounted) return;
      }
      final repository = UsageRepository(ref.read(databaseProvider));
      final text = note.text.trim();
      if (widget.event == null) {
        await repository.add(
          subscription.id,
          occurredAt: occurredAt,
          quantity: int.parse(quantity.text),
          note: text.isEmpty ? null : text,
        );
      } else {
        await repository.edit(
          widget.event!.id,
          occurredAt: occurredAt,
          quantity: int.parse(quantity.text),
          note: text.isEmpty ? null : text,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => error = context.l10n.couldNotSaveEventPleaseRetry);
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: occurredAt,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (date != null && mounted) {
      setState(
        () => occurredAt = DateTime(
          date.year,
          date.month,
          date.day,
          occurredAt.hour,
          occurredAt.minute,
          occurredAt.second,
          occurredAt.millisecond,
          occurredAt.microsecond,
        ),
      );
    }
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(occurredAt),
    );
    if (time != null && mounted) {
      setState(
        () => occurredAt = DateTime(
          occurredAt.year,
          occurredAt.month,
          occurredAt.day,
          time.hour,
          time.minute,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: AlertDialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: Text(
        widget.event == null
            ? context.l10n.addForgottenUse
            : context.l10n.editUsageEvent,
      ),
      content: SizedBox(
        width: 420,
        child: ref
            .watch(subscriptionsProvider)
            .when(
              loading: () => Center(child: CircularProgressIndicator()),
              error: (_, _) => Text(context.l10n.couldNotLoadSubscriptions),
              data: (all) {
                final items =
                    all
                        .where((s) => !s.isArchived || s.id == subscriptionId)
                        .toList()
                      ..sort((a, b) => a.name.compareTo(b.name));
                return SingleChildScrollView(
                  child: Form(
                    key: form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 12,
                      children: [
                        if (items.isEmpty)
                          Text(
                            context
                                .l10n
                                .createOrRestoreASubscriptionBeforeAddingUsage,
                          ),
                        DropdownButtonFormField<String>(
                          key: ValueKey(subscriptionId),
                          initialValue: items.any((s) => s.id == subscriptionId)
                              ? subscriptionId
                              : null,
                          decoration: InputDecoration(
                            labelText: context.l10n.subscription,
                          ),
                          isExpanded: true,
                          items: items
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(
                                    s.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: saving || widget.event != null
                              ? null
                              : (value) =>
                                    setState(() => subscriptionId = value),
                          validator: (value) => value == null
                              ? context.l10n.chooseASubscription
                              : null,
                        ),
                        if (widget.event == null &&
                            items.any(
                              (s) => s.id == subscriptionId && s.isArchived,
                            ))
                          Text(
                            context
                                .l10n
                                .restoreThisSubscriptionBeforeAddingUsage,
                          ),
                        FormSectionHeading(
                          icon: Icons.schedule,
                          label: context.l10n.dateAndTimeSection,
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          trailing: Icon(
                            Icons.calendar_today_outlined,
                            size: 20,
                          ),
                          title: Text(context.l10n.date),
                          subtitle: Text(DateFormat.yMMMd().format(occurredAt)),
                          onTap: saving ? null : pickDate,
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          trailing: Icon(Icons.access_time, size: 20),
                          title: Text(context.l10n.time),
                          subtitle: Text(DateFormat.Hm().format(occurredAt)),
                          onTap: saving ? null : pickTime,
                        ),
                        FormSectionHeading(
                          icon: Icons.notes_outlined,
                          label: context.l10n.usageDetailsSection,
                        ),
                        TextFormField(
                          controller: quantity,
                          textInputAction: TextInputAction.next,
                          enabled: !saving,
                          decoration: InputDecoration(
                            labelText: context.l10n.quantity,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (text) {
                            final value = int.tryParse(text ?? '');
                            return value == null ||
                                    value <= 0 ||
                                    value > 2147483647
                                ? context.l10n.enterAPositiveWholeNumber
                                : null;
                          },
                        ),
                        TextFormField(
                          controller: note,
                          textCapitalization: TextCapitalization.sentences,
                          enabled: !saving,
                          decoration: InputDecoration(
                            labelText: context.l10n.noteOptional,
                          ),
                          minLines: 1,
                          maxLines: 4,
                        ),
                        if (error != null)
                          Text(
                            error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: saving
              ? null
              : () => save(ref.read(subscriptionsProvider).asData?.value ?? []),
          child: Text(saving ? context.l10n.saving : context.l10n.saveEvent),
        ),
      ],
    ),
  );
}
