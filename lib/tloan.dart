// ============================================================================
// ملف: tloan.dart
// الغرض: نموذج بيانات (DTO) يمثل قرضاً مصروفاً (token loan) مع تقدّم السداد.
// متى يُستخدم: في شاشتي token_loans.dart و my_loans.dart.
// ============================================================================

/// One disbursed loan with its repayment progress: [paid] vs [amount].
///
/// شرح الحقول:
/// - [code]:   رمز/معرّف القرض (token).
/// - [date]:   تاريخ صرف القرض.
/// - [amount]: المبلغ الإجمالي للقرض.
/// - [paid]:   المبلغ المسدّد حتى الآن من المرتب.
class tLoan {
  String? code;
  String? date;
  String? amount;
  String? paid;
}
