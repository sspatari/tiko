enum CostRecoveryState { unavailable, inProgress, recovered, noCost }

/// Financial calculations use integer minor units until display formatting.
class FinancialSummary {
  const FinancialSummary(this.cost, this.uses, this.reference);
  final int cost;
  final int uses;
  final int? reference;
  CostRecoveryState get costRecoveryState {
    if (reference == null) return CostRecoveryState.unavailable;
    if (cost == 0) return CostRecoveryState.noCost;
    return remainingUses == 0
        ? CostRecoveryState.recovered
        : CostRecoveryState.inProgress;
  }

  int? get averageMinorUnits => uses == 0 ? null : (cost + uses ~/ 2) ~/ uses;
  int? get equivalentMinorUnits => reference == null ? null : uses * reference!;
  int? get savingsMinorUnits =>
      equivalentMinorUnits == null ? null : equivalentMinorUnits! - cost;
  int? get breakEvenUses =>
      reference == null ? null : (cost + reference! - 1) ~/ reference!;
  int? get remainingUses => breakEvenUses == null
      ? null
      : (breakEvenUses! - uses).clamp(0, breakEvenUses!);
  double? get progress =>
      reference == null || cost == 0 ? null : equivalentMinorUnits! / cost;
  double? get savingsPercentage =>
      equivalentMinorUnits == null || equivalentMinorUnits == 0
      ? null
      : savingsMinorUnits! / equivalentMinorUnits! * 100;
}

const maxFinancialInteger = 9007199254740991;

class FinancialCalculator {
  const FinancialCalculator();
  FinancialSummary calculate({
    required int costMinorUnits,
    required Iterable<int> quantities,
    int? referenceMinorUnits,
  }) {
    if (costMinorUnits < 0 || costMinorUnits > maxFinancialInteger) {
      throw ArgumentError.value(costMinorUnits, 'costMinorUnits');
    }
    if (referenceMinorUnits != null &&
        (referenceMinorUnits <= 0 ||
            referenceMinorUnits > maxFinancialInteger)) {
      throw ArgumentError.value(referenceMinorUnits, 'referenceMinorUnits');
    }
    var uses = 0;
    for (final quantity in quantities) {
      if (quantity <= 0 || quantity > maxFinancialInteger - uses) {
        throw ArgumentError.value(quantity, 'quantity');
      }
      uses += quantity;
    }
    if (referenceMinorUnits != null &&
        BigInt.from(uses) * BigInt.from(referenceMinorUnits) >
            BigInt.from(maxFinancialInteger)) {
      throw ArgumentError('Financial values exceed supported precision');
    }
    return FinancialSummary(costMinorUnits, uses, referenceMinorUnits);
  }
}
