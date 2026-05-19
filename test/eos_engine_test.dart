// ============================================================================
// File: test/eos_engine_test.dart
// Purpose: Boundary tests for the EOS calculator. Saudi labor law has
//          discrete tier boundaries (5y, 10y, 2y) that are bait for off-by-one
//          bugs — explicit tests guard them.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:shubraepp/eos/eos_engine.dart';
import 'package:shubraepp/eos/eos_models.dart';

void main() {
  group('EosEngine — termination (Article 84)', () {
    test('exactly 5 years → all in first tier', () {
      final r = EosEngine.calculate(EosInputs(
        hireDate: DateTime(2020, 1, 1),
        endDate: DateTime(2025, 1, 1),
        reason: EndReason.termination,
        basicSalary: 10000,
      ));
      expect(r.serviceYears, closeTo(5.0, 0.05));
      expect(r.firstTierAmount, closeTo(25000, 100)); // 0.5 * 10000 * 5
      expect(r.secondTierAmount, closeTo(0, 100));
    });

    test('exactly 10 years → 5y first tier + 5y second tier', () {
      final r = EosEngine.calculate(EosInputs(
        hireDate: DateTime(2015, 1, 1),
        endDate: DateTime(2025, 1, 1),
        reason: EndReason.termination,
        basicSalary: 10000,
      ));
      expect(r.serviceYears, closeTo(10.0, 0.05));
      expect(r.firstTierAmount, closeTo(25000, 100));   // 0.5 * 10000 * 5
      expect(r.secondTierAmount, closeTo(50000, 200));  // 1.0 * 10000 * 5
      expect(r.totalSar, closeTo(75000, 300));
    });

    test('includes housing + transport in wage basis', () {
      final r = EosEngine.calculate(EosInputs(
        hireDate: DateTime(2024, 1, 1),
        endDate: DateTime(2025, 1, 1),
        reason: EndReason.termination,
        basicSalary: 8000,
        housingAllowance: 2000,
        transportAllowance: 500,
      ));
      // 1 year * 0.5 month * 10500 = 5250
      expect(r.monthlyWage, 10500);
      expect(r.totalSar, closeTo(5250, 100));
    });

    test('partial year prorated', () {
      final r = EosEngine.calculate(EosInputs(
        hireDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 7, 1), // ~0.5 year
        reason: EndReason.termination,
        basicSalary: 10000,
      ));
      // 0.5y * 0.5 * 10000 = 2500
      expect(r.totalSar, closeTo(2500, 100));
    });
  });

  group('EosEngine — resignation tiers (Article 85)', () {
    final wage10k = (DateTime hire, DateTime end) => EosInputs(
          hireDate: hire,
          endDate: end,
          reason: EndReason.resignation,
          basicSalary: 10000,
        );

    test('< 2 years → zero', () {
      final r = EosEngine.calculate(
        wage10k(DateTime(2024, 1, 1), DateTime(2025, 6, 1)),
      );
      expect(r.totalSar, 0);
      expect(r.resignationTier, ResignationTier.none);
    });

    test('4 years → 1/3 tier', () {
      final r = EosEngine.calculate(
        wage10k(DateTime(2021, 1, 1), DateTime(2025, 1, 1)),
      );
      expect(r.resignationTier, ResignationTier.oneThird);
      // base = 0.5 * 10000 * 4 = 20000; 1/3 = 6666.67
      expect(r.totalSar, closeTo(20000 / 3, 200));
    });

    test('7 years → 2/3 tier', () {
      final r = EosEngine.calculate(
        wage10k(DateTime(2018, 1, 1), DateTime(2025, 1, 1)),
      );
      expect(r.resignationTier, ResignationTier.twoThirds);
      // termination base = (0.5 * 10000 * 5) + (1.0 * 10000 * 2) = 45000
      // 2/3 = 30000
      expect(r.totalSar, closeTo(30000, 500));
    });

    test('exactly 10 years → full tier', () {
      final r = EosEngine.calculate(
        wage10k(DateTime(2015, 1, 1), DateTime(2025, 1, 1)),
      );
      expect(r.resignationTier, ResignationTier.full);
      expect(r.totalSar, closeTo(75000, 500));
    });

    test('4.99 years stays in 1/3 tier (boundary)', () {
      final r = EosEngine.calculate(
        wage10k(DateTime(2020, 1, 5), DateTime(2025, 1, 1)),
      );
      expect(r.resignationTier, ResignationTier.oneThird);
    });
  });
}
