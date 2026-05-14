// ============================================================================
// ملف: shared/utils/logger.dart
// الغرض: دالة تسجيل (log) واحدة تعمل في وضع التطوير فقط.
// لماذا نحتاجها: استدعاء print العادي يبقى في الإصدارات النهائية وقد يُسرّب
//              بيانات حساسة (tokens، أرقام بنكية، إلخ) للسجلات النظامية.
//              هذه الدالة تتم إزالتها تلقائياً عبر شجرة الـ tree-shaking
//              عندما يكون kDebugMode == false.
// كيف تُستخدم: logD('message') بدلاً من print في أي مكان بالكود.
// ============================================================================

import 'package:flutter/foundation.dart';

/// Debug-only log. Compiled out of release builds.
///
/// Use instead of `print` so production binaries stay quiet and never leak
/// data to system logs.
///
/// مثال:
///   logD('user logged in: $empcode');
///   logD(response.data);
void logD(Object? message) {
  // kDebugMode ثابت compile-time — كل الكود داخل الـ if يُحذف في الـ release.
  if (kDebugMode) {
    // debugPrint أفضل من print لأنه يقصّ السطور الطويلة على شاشات Android.
    debugPrint(message?.toString());
  }
}
