// ============================================================================
// ملف: constants/leave_types.dart
// الغرض: تعداد (enum) موحّد لكل أنواع الإجازات التي يدعمها التطبيق.
// لماذا مهم: بدلاً من استخدام strings مثل "01", "02" في كل الكود (سهلة الخطأ
//          عند تغييرها)، نجمع كل المعلومات (كود، اسم، أيقونة، سياسة) في مكان واحد.
// الأنواع: خارجية، داخلية، وفاة، زواج، إنجاب، حج.
// السياسات المُضمنة:
//   - isRegular / isSpecial: هل تُخصم من الرصيد؟
//   - requiresAttachment: هل تحتاج مرفق إثبات؟
//   - localizedName: اسم مترجم حسب لغة الواجهة.
//   - presentation: زوج (أيقونة + لون) للعرض في شبكة الاختيار.
// ============================================================================

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';

/// All leave types the backend can return. Each entry binds together the
/// server `vccd` code, its localized label, the icon/color used in the type
/// grid, and policy flags consumed by the request form.
///
/// Keep this enum as the single source of truth for leave-code behavior:
/// switch statements on raw strings drift apart over time, this does not.
enum LeaveType {
  /// External vacation — counted against balance.
  /// إجازة خارجية (سفر خارج البلد) — تُخصم من الرصيد السنوي.
  outVac('01'),

  /// Internal vacation — counted against balance, default selection.
  /// إجازة داخلية — تُخصم من الرصيد، الخيار الافتراضي.
  inVac('02'),

  /// Bereavement leave.
  /// إجازة وفاة (عزاء) — لا تُخصم من الرصيد، تتطلب مرفق.
  dieVac('04'),

  /// Marriage leave.
  /// إجازة زواج — لا تُخصم من الرصيد، تتطلب مرفق (عقد).
  marryVac('05'),

  /// Maternity / paternity leave.
  /// إجازة أمومة/أبوة — لا تُخصم من الرصيد، تتطلب شهادة ميلاد.
  childVac('06'),

  /// Hajj leave.
  /// إجازة حج — لا تُخصم من الرصيد، تتطلب إثبات.
  hajjVac('07');

  /// كود النوع كما يتعامل معه الـ backend (مثلاً "01" للخارجية).
  final String code;
  const LeaveType(this.code);

  /// تحويل كود نصي (يأتي من الـ backend) إلى enum.
  /// يُعيد null إذا الكود غير معروف (حماية للأمام إذا أضاف الباك-إند نوعاً جديداً).
  static LeaveType? fromCode(String? code) {
    if (code == null) return null;
    for (final t in values) {
      if (t.code == code) return t;
    }
    return null;
  }

  /// Regular vacation (out/in). These deduct from the user's balance and
  /// don't require an attachment.
  /// الإجازات العادية (داخلية/خارجية) — تُخصم من الرصيد بدون مرفق.
  bool get isRegular => this == outVac || this == inVac;

  /// Special vacation types (bereavement, marriage, childbirth, hajj) are
  /// not deducted from the balance and require supporting documentation.
  /// الإجازات الخاصة — لا تُخصم وتحتاج إثبات.
  bool get isSpecial => !isRegular;

  /// True for codes that the form must block until the user attaches a file.
  /// هل النموذج يجب أن يمنع الإرسال حتى يُرفق المستخدم ملفاً؟
  /// (نمط Dart 3 switch expression).
  bool get requiresAttachment => switch (this) {
        dieVac || marryVac || childVac || hajjVac => true,
        _ => false,
      };

  /// Localized display name for the type grid and confirmation dialog.
  /// يعيد الاسم المترجم حسب لغة الواجهة الحالية.
  String localizedName(AppLocalizations t) => switch (this) {
        outVac => t.outvac,
        inVac => t.invac,
        dieVac => t.dievac,
        marryVac => t.marryvac,
        childVac => t.childvac,
        hajjVac => t.hajjvac,
      };

  /// Icon + accent color for the type grid card.
  /// يُعيد tuple فيه (أيقونة، لون) لاستخدامها في VacationTypeCard.
  (IconData, Color) get presentation => switch (this) {
        outVac => (Icons.flight_takeoff_rounded, AppColors.primary),
        inVac => (Icons.home_work_rounded, AppColors.secondary),
        dieVac => (Icons.heart_broken_rounded, AppColors.muted),
        marryVac => (Icons.favorite_rounded, Color(0xFFE11D48)),
        childVac => (Icons.child_care_rounded, AppColors.secondary),
        hajjVac => (Icons.mosque_rounded, AppColors.success),
      };
}
