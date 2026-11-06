part of '../../../main.dart';

class BreakEvenMessage extends StatelessWidget {
  const BreakEvenMessage({
    super.key,
    required this.summary,
    this.periodClosed = false,
    this.showComparisonHint = false,
  });
  final FinancialSummary summary;
  final bool periodClosed;
  final bool showComparisonHint;

  @override
  Widget build(BuildContext context) {
    final state = summary.costRecoveryState;
    if (state == CostRecoveryState.unavailable) return SizedBox.shrink();
    final message = switch (state) {
      CostRecoveryState.inProgress =>
        periodClosed
            ? context.l10n.usesShortOfRecoveringCost(summary.remainingUses!)
            : context.l10n.usesToRecoverCost(summary.remainingUses!),
      CostRecoveryState.recovered => context.l10n.prepaidCostRecovered,
      CostRecoveryState.noCost => context.l10n.noPrepaidCostToRecover,
      CostRecoveryState.unavailable => '',
    };
    final recovered = state == CostRecoveryState.recovered;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recovered) ...[
              Icon(Icons.check_circle_outline, size: 18, color: scheme.primary),
              SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: recovered ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: recovered ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        if (showComparisonHint && state != CostRecoveryState.noCost) ...[
          SizedBox(height: 4),
          Text(
            context.l10n.costRecoveryComparisonHint,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
