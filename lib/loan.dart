// ============================================================================
// ملف: loan.dart
// الغرض: نموذج بيانات (DTO) يمثل طلب قرض/سلفة واحد من الـ backend.
// متى يُستخدم: في شاشات القروض (request_loan, loan_requests, loan_requests_mgr).
// ملاحظة: الحقول nullable لأن نفس الكلاس يُستخدم في جهة الموظف وجهة المدير.
// ============================================================================

/// One loan request as returned by the backend. Manager view fills [id],
/// [empname], and [emcd]; employee view leaves them null.
///
/// شرح الحقول:
/// - [id]:          معرّف طلب القرض (جهة المدير فقط).
/// - [status]:      حالة القرض (مُعلّق / مقبول / مرفوض).
/// - [status_date]: تاريخ آخر تحديث للحالة.
/// - [loandate]:    تاريخ تقديم الطلب.
/// - [loanamount]:  المبلغ المطلوب بالعملة (عدد صحيح).
/// - [notice]:      سبب القرض أو ملاحظات الموظف.
/// - [emcd]:        كود الموظف — جهة المدير فقط.
/// - [empname]:     اسم الموظف — جهة المدير فقط.
class Loan {
  String? id;
  String? status;
  String? status_date;
  String? loandate;
  int? loanamount;
  String? notice;
  String? emcd;
  String? empname;
}
