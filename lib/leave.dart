// ============================================================================
// ملف: leave.dart
// الغرض: نموذج بيانات (DTO) يمثل طلب إجازة واحد كما يأتي من الـ backend.
// متى يُستخدم: في شاشات الإجازات (request_leave, leave_requests, leave_requests_mgr).
// ملاحظة: جميع الحقول nullable لأن endpoint الموظف يعيد جزءاً من الحقول،
//        وendpoint المدير يعيد حقولاً إضافية (id, empname, emcd, url).
// ============================================================================

/// One leave request as returned by the backend.
///
/// `nullable everything` is intentional — the manager-side endpoint
/// returns extra fields ([id], [empname], [emcd], [url]) that the
/// employee-side endpoint omits.
///
/// شرح الحقول:
/// - [id]:          معرّف الطلب (يصل من جهة المدير فقط).
/// - [status]:      حالة الطلب (مُعلّق / مقبول / مرفوض).
/// - [status_date]: تاريخ آخر تحديث للحالة.
/// - [leavedate]:   تاريخ بداية الإجازة.
/// - [leavedateto]: تاريخ نهاية الإجازة.
/// - [nodays]:      عدد أيام الإجازة.
/// - [notice]:      ملاحظة الموظف أو سبب الإجازة.
/// - [emcd]:        كود الموظف (empcode) — جهة المدير فقط.
/// - [url]:         رابط المرفق (مثلاً تقرير طبي للإجازة المرضية).
/// - [empname]:     اسم الموظف — جهة المدير فقط.
/// - [addeddays]:   أيام إضافية يقترحها/يضيفها المدير.
/// - [type]:        نوع الإجازة (سنوية، مرضية، اضطرارية، إلخ).
class Leave {
  String? id;
  String? status;
  String? status_date;
  String? leavedate;
  String? leavedateto;
  int? nodays;
  String? notice;
  String? emcd;
  String? url;
  String? empname;
  int? addeddays;
  String? type;
}
