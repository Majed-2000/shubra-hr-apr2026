/// One payroll adjustment row (absence, deduction, allowance, etc.).
/// [code] is the move-type identifier; [amount] is the monetary impact.
class Moves {
  String? name;
  String? code;
  String? date;
  String? amount;
}
