// ============================================================================
// File: eos/eos_engine.dart
// Purpose: Pure Dart calculator for Saudi end-of-service benefit per
//          Article 84 (termination) and Article 85 (resignation tiers).
// References:
//   - Article 84: half-month wage per year for first 5 years, one-month
//     wage per year after, prorated for partial years.
//   - Article 85: resignation pays a fraction of the standard accrual
//     based on years served:
//       <2y   → 0
//       2-5y  → 1/3
//       5-10y → 2/3
//       10y+  → full
// Tested in test/eos_engine_test.dart (boundary cases, partial-year math).
// ============================================================================

import 'eos_models.dart';

class EosEngine {
  static EosResult calculate(EosInputs i) {
    final years = i.serviceYears;
    final wage = i.monthlyWage;

    // ── Article 84 base calculation ──
    final firstTierYears = years.clamp(0, 5).toDouble();
    final secondTierYears = (years - 5).clamp(0, double.infinity).toDouble();

    final firstTierAmount = 0.5 * wage * firstTierYears;
    final secondTierAmount = 1.0 * wage * secondTierYears;
    final terminationBase = firstTierAmount + secondTierAmount;

    // ── Article 85 resignation tiers ──
    ResignationTier tier;
    double multiplier;
    if (i.reason == EndReason.termination) {
      tier = ResignationTier.none;
      multiplier = 1.0;
    } else {
      if (years < 2) {
        tier = ResignationTier.none;
        multiplier = 0.0;
      } else if (years < 5) {
        tier = ResignationTier.oneThird;
        multiplier = 1 / 3;
      } else if (years < 10) {
        tier = ResignationTier.twoThirds;
        multiplier = 2 / 3;
      } else {
        tier = ResignationTier.full;
        multiplier = 1.0;
      }
    }

    final total = terminationBase * multiplier;

    return EosResult(
      totalSar: total,
      terminationBase: terminationBase,
      firstTierAmount: firstTierAmount * multiplier,
      secondTierAmount: secondTierAmount * multiplier,
      resignationTier: tier,
      serviceYears: years,
      monthlyWage: wage,
    );
  }
}
