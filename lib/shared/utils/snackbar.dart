// ============================================================================
// ملف: shared/utils/snackbar.dart
// الغرض: مساعِد مركزي لإظهار رسائل توست (SnackBar) بنفس الشكل في كل الشاشات.
// لماذا نحتاجه: بدلاً من تكرار كود ScaffoldMessenger.of(context).showSnackBar
//              في كل ملف، نستدعي دالة موحّدة → شكل واحد، ألوان واحدة.
// متى يُستخدم: عند نجاح/فشل عملية، أو لإظهار معلومة سريعة للمستخدم.
// مثال:
//   SnackbarHelpers.showSuccess(context, 'تم تقديم الطلب');
//   SnackbarHelpers.showError(context, parseDioError(e, isArabic: true));
// ============================================================================

import 'package:flutter/material.dart';

import '../../theme.dart';

/// Centralised snackbar helpers so every screen surfaces feedback in the
/// same shape. Each call is a no-op if [context] no longer has a Scaffold
/// (e.g. the screen has been popped).
///
/// كلاس بصيغة "Static-only" — لا يُنشَأ instance منه، فقط نداء دوال static.
class SnackbarHelpers {
  // constructor خاص يمنع إنشاء instances. (نمط utility class).
  SnackbarHelpers._();

  /// عرض رسالة عامة بلون اختياري.
  ///
  /// - [context]: BuildContext الحالي للشاشة.
  /// - [message]: نص الرسالة.
  /// - [color]:   لون الخلفية (اختياري، يكون رمادياً افتراضياً).
  static void show(BuildContext context, String message, {Color? color}) {
    // maybeOf بدلاً من of حتى لا يرمي خطأ إذا أُغلقت الشاشة قبل الاستدعاء.
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return; // الشاشة pop-أُغلقت — تجاهل الاستدعاء بصمت.

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        // floating = يطفو فوق المحتوى مع هامش، أجمل من شريط ملتصق.
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }

  /// رسالة خطأ — خلفية حمراء (AppColors.danger).
  static void showError(BuildContext context, String message) =>
      show(context, message, color: AppColors.danger);

  /// رسالة نجاح — خلفية خضراء (AppColors.success).
  static void showSuccess(BuildContext context, String message) =>
      show(context, message, color: AppColors.success);

  /// رسالة معلوماتية — لون افتراضي (رمادي داكن).
  static void showInfo(BuildContext context, String message) =>
      show(context, message);
}
