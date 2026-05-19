// ============================================================================
// File: eos/eos_models.dart
// Purpose: Inputs + outputs for the Saudi end-of-service calculator
//          (feature 8). Pure data — no Flutter imports — so the engine
//          stays trivially unit-testable.
// ============================================================================

enum EndReason { termination, resignation }

/// Resignation tier per Article 85.
enum ResignationTier { none, oneThird, twoThirds, full }

class EosInputs {
  final DateTime hireDate;
  final DateTime endDate;
  final EndReason reason;
  final double basicSalary;
  final double housingAllowance;
  final double transportAllowance;

  const EosInputs({
    required this.hireDate,
    required this.endDate,
    required this.reason,
    required this.basicSalary,
    this.housingAllowance = 0,
    this.transportAllowance = 0,
  });

  double get monthlyWage =>
      basicSalary + housingAllowance + transportAllowance;

  double get serviceYears {
    final days = endDate.difference(hireDate).inDays;
    return days / 365.25;
  }
}

class EosResult {
  /// Final amount after applying any resignation tier multiplier.
  final double totalSar;

  /// What the user would receive under termination terms (Article 84).
  /// For termination cases, equals [totalSar]. For resignation, this is
  /// the pre-tier base, useful to show "you'd get X under termination".
  final double terminationBase;

  /// Component for years 1-5 (0.5 month per year).
  final double firstTierAmount;

  /// Component for years 6+ (1 month per year).
  final double secondTierAmount;

  /// Effective resignation tier applied (none for termination cases).
  final ResignationTier resignationTier;

  /// Years of service (decimal, e.g. 6.42).
  final double serviceYears;

  /// Monthly wage used in calc (basic + fixed allowances).
  final double monthlyWage;

  const EosResult({
    required this.totalSar,
    required this.terminationBase,
    required this.firstTierAmount,
    required this.secondTierAmount,
    required this.resignationTier,
    required this.serviceYears,
    required this.monthlyWage,
  });
}
