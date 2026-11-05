/// Financial calculations use integer minor units until display formatting.
class FinancialSummary {
  const FinancialSummary(this.cost, this.uses, this.reference);
  final int cost;
  final int uses;
  final int? reference;
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

class FinancialCalculator {
  const FinancialCalculator();
  FinancialSummary calculate({
    required int costMinorUnits,
    required Iterable<int> quantities,
    int? referenceMinorUnits,
  }) {
    if (costMinorUnits < 0) {
      throw ArgumentError.value(costMinorUnits, 'costMinorUnits');
    }
    if (referenceMinorUnits != null && referenceMinorUnits <= 0) {
      throw ArgumentError.value(referenceMinorUnits, 'referenceMinorUnits');
    }
    var uses = 0;
    for (final quantity in quantities) {
      if (quantity <= 0) throw ArgumentError.value(quantity, 'quantity');
      uses += quantity;
    }
    return FinancialSummary(costMinorUnits, uses, referenceMinorUnits);
  }
}
