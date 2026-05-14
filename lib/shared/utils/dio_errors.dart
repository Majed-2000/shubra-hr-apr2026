// ============================================================================
// ملف: shared/utils/dio_errors.dart
// الغرض: تحويل أخطاء Dio (مكتبة HTTP) إلى رسائل ودودة باللغتين العربية/الإنجليزية.
// لماذا نحتاجه: المستخدم النهائي (موظف أو موظفة، أحياناً ٦٠+ سنة) لا يفهم
//              "DioException: bad response 502" — يحتاج رسالة بسيطة.
// منطق الاختيار:
//   1. إذا أرسل الـ backend رسالة جاهزة في الـ body → نعرضها (نثق بها).
//   2. وإلا → نُصنّف الخطأ حسب نوعه (timeout, 5xx, 4xx, الخ) ونعرض رسالة عامة.
//   3. وإلا → رسالة عامة جداً "حدث خطأ، حاول مرة أخرى".
// كل التفاصيل التقنية تُسجَّل عبر logD() للمطوّر فقط (لا تظهر للمستخدم).
// ============================================================================

import 'package:dio/dio.dart';

import 'logger.dart';

/// Pulls a friendly message out of a Dio failure.
///
/// Designed for non-technical users (incl. 60+): the returned text contains
/// no status codes, no exception type names, and no raw stack-trace lines.
/// The technical detail still gets written via [logD] so developers can
/// debug from console output.
///
/// Priority:
///   1. Backend body's `message` / `error` / `detail` field — the team owns
///      that copy and we trust it to be user-friendly.
///   2. Friendly category fallback derived from the failure shape (server
///      down, no internet, slow connection, request rejected, …).
///   3. Generic "something went wrong, try again".
///
/// - [e]:         الكائن الذي وقع (نتحقق إن كان DioException فعلاً).
/// - [isArabic]:  هل المستخدم يستخدم الواجهة العربية؟ يحدّد لغة الرسالة.
String parseDioError(Object e, {required bool isArabic}) {
  // إذا لم يكن خطأ Dio أصلاً (مثلاً TypeError) — رسالة عامة وانتهى.
  if (e is! DioException) {
    logD('parseDioError: non-Dio error: $e');
    return _generic(isArabic);
  }

  // Always log the technical truth for devs.
  // نُسجّل كل التفاصيل التقنية في الـ debug log فقط — مفيدة للمطوّر، مخفية عن المستخدم.
  logD(
    'parseDioError: type=${e.type.name} '
    'code=${e.response?.statusCode} '
    'path=${e.requestOptions.path} '
    'msg=${e.message} '
    'body=${e.response?.data}',
  );

  // 1. Backend-provided message — trust it. Only show if it's reasonably
  // short (long technical strings are almost certainly a stack-style dump
  // and would scare users).
  //
  // الخطوة 1: نحاول استخراج رسالة من الـ backend.
  // نقبل المفاتيح: message أو error أو detail (FastAPI/Django/Express يستعملون أحدها).
  final data = e.response?.data;
  String? backendMsg;
  if (data is Map) {
    final raw = data['message'] ?? data['error'] ?? data['detail'];
    backendMsg = raw?.toString().trim();
  } else if (data is String) {
    // أحياناً الـ backend يُرجع نصاً مباشراً (وليس JSON).
    backendMsg = data.trim();
  }
  // شروط القبول:
  // - النص موجود وغير فارغ.
  // - قصير (<= 160 حرفاً) — النصوص الطويلة جداً هي عادة stack traces.
  // - بدون أسطر جديدة (\n) — السطر الواحد فقط هو رسالة موجّهة للمستخدم.
  // - لا يبدو كـ stack trace (يحتوي على Exception, #0, etc.).
  if (backendMsg != null &&
      backendMsg.isNotEmpty &&
      backendMsg.length <= 160 &&
      !backendMsg.contains('\n') &&
      !_looksLikeStackTrace(backendMsg)) {
    return backendMsg;
  }

  // 2. Friendly category by failure shape.
  // الخطوة 2: تصنيف حسب رمز الحالة HTTP.
  final code = e.response?.statusCode ?? 0;
  if (code >= 500) {
    // 5xx = خطأ خادم — مشكلة عندنا، ليس عند المستخدم.
    return isArabic
        ? 'الخدمة غير متوفرة حاليًا. يُرجى المحاولة بعد قليل.'
        : 'The service is unavailable right now. Please try again in a moment.';
  }
  if (code >= 400) {
    // 4xx = طلب مرفوض — عادةً بيانات خاطئة أو مصادقة منتهية.
    return isArabic
        ? 'تعذّر إتمام الطلب. تأكد من البيانات وحاول مرة أخرى.'
        : "Couldn't complete the request. Check your details and try again.";
  }

  // الخطوة 3: تصنيف حسب نوع الفشل الشبكي (لا يوجد رمز HTTP أصلاً).
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
      // فشل الاتصال بالخادم أو إرسال الطلب — شبكة بطيئة.
      return isArabic
          ? 'الاتصال بالإنترنت بطيء. تأكد من الشبكة وحاول مرة أخرى.'
          : 'Your internet connection seems slow. Please check it and try again.';
    case DioExceptionType.receiveTimeout:
      // أرسلنا الطلب لكن الخادم تأخّر في الرد.
      return isArabic
          ? 'استغرق الخادم وقتًا طويلاً للرد. يُرجى المحاولة لاحقًا.'
          : 'The server is taking too long to respond. Please try again later.';
    case DioExceptionType.connectionError:
      // لا يوجد اتصال إنترنت أصلاً.
      return isArabic
          ? 'تعذّر الاتصال بالإنترنت. يُرجى التأكد من الشبكة.'
          : "Couldn't connect to the internet. Please check your connection.";
    case DioExceptionType.badCertificate:
      // شهادة SSL غير صالحة — غالباً تاريخ الجهاز خطأ.
      return isArabic
          ? 'تعذّر التحقق من أمان الاتصال. تأكد من تاريخ الجهاز ثم حاول مرة أخرى.'
          : "Couldn't verify a secure connection. Please check your device's date and try again.";
    case DioExceptionType.cancel:
      // المستخدم/الكود ألغى الطلب يدوياً.
      return isArabic ? 'تم إلغاء الطلب.' : 'The request was cancelled.';
    case DioExceptionType.badResponse:
    case DioExceptionType.unknown:
      // نتركها لتسقط على الرسالة العامة في النهاية.
      break;
  }

  return _generic(isArabic);
}

/// رسالة عامة احتياطية عندما لا نستطيع تصنيف الخطأ.
String _generic(bool isArabic) => isArabic
    ? 'حدث خطأ غير متوقع. يُرجى المحاولة مرة أخرى.'
    : 'Something went wrong. Please try again.';

/// Heuristic — if the backend message looks like a Dart/Java stack trace
/// or a JSON-serialised exception, we prefer the friendly fallback so the
/// user doesn't see something like
/// "DioException [bad response]: HTTP 502 ... at #0 ...".
///
/// طريقة بسيطة (heuristic) لمعرفة هل النص شبيه بـ stack trace:
/// إذا احتوى على كلمات شائعة في الأخطاء (Exception, #0, "  at ", إلخ)
/// نعتبره تقني ولا نعرضه للمستخدم.
bool _looksLikeStackTrace(String s) {
  return s.contains('Exception:') ||
      s.contains('Error:') ||
      s.startsWith('#0') ||
      s.contains('  at ') ||
      s.contains('DioException') ||
      s.contains('SocketException') ||
      s.contains('FormatException') ||
      s.contains('TimeoutException');
}
