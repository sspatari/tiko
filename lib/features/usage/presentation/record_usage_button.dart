part of '../../../main.dart';

final _recordingSubscriptions = <String>{};

class RecordUsageButton extends ConsumerStatefulWidget {
  const RecordUsageButton({super.key, required this.subscription});
  final Subscription subscription;
  @override
  ConsumerState<RecordUsageButton> createState() => _RecordUsageButtonState();
}

class _RecordUsageButtonState extends ConsumerState<RecordUsageButton> {
  Future<void> record(Subscription subscription) async {
    if (subscription.isArchived ||
        !_recordingSubscriptions.add(subscription.id)) {
      return;
    }
    try {
      final now = DateTime.now();
      if (outsideValidity(subscription, now)) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.l10n.outsideValidityPeriod),
            content: Text(context.l10n.recordThisUseAnyway),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.l10n.recordUse),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }
      final database = ref.read(databaseProvider);
      final id = await UsageRepository(
        database,
      ).add(subscription.id, occurredAt: now);
      if (ref.read(preferencesProvider).haptics) HapticFeedback.lightImpact();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.removeCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          persist: false,
          showCloseIcon: true,
          duration: Duration(seconds: 5),
          content: Text(context.l10n.recordedAt(DateFormat.Hm().format(now))),
          action: SnackBarAction(
            label: context.l10n.undo,
            onPressed: () async {
              try {
                await UsageRepository(database).delete(id);
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.couldNotUndoPleaseRetry),
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
          SnackBar(content: Text(context.l10n.couldNotSaveThisUsePleaseRetry)),
        );
      }
    } finally {
      await Future<void>.delayed(Duration(milliseconds: 500));
      _recordingSubscriptions.remove(subscription.id);
    }
  }

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: widget.subscription.isArchived
        ? null
        : () => record(widget.subscription),
    style: FilledButton.styleFrom(minimumSize: Size.fromHeight(60)),
    child: Text(context.l10n.label1USE, style: TextStyle(fontSize: 20)),
  );
}
