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
String parseDioError(Object e, {required bool isArabic}) {
  if (e is! DioException) {
    logD('parseDioError: non-Dio error: $e');
    return _generic(isArabic);
  }

  // Always log the technical truth for devs.
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
  final data = e.response?.data;
  String? backendMsg;
  if (data is Map) {
    final raw = data['message'] ?? data['error'] ?? data['detail'];
    backendMsg = raw?.toString().trim();
  } else if (data is String) {
    backendMsg = data.trim();
  }
  if (backendMsg != null &&
      backendMsg.isNotEmpty &&
      backendMsg.length <= 160 &&
      !backendMsg.contains('\n') &&
      !_looksLikeStackTrace(backendMsg)) {
    return backendMsg;
  }

  // 2. Friendly category by failure shape.
  final code = e.response?.statusCode ?? 0;
  if (code >= 500) {
    return isArabic
        ? 'الخدمة غير متوفرة حاليًا. يُرجى المحاولة بعد قليل.'
        : 'The service is unavailable right now. Please try again in a moment.';
  }
  if (code >= 400) {
    return isArabic
        ? 'تعذّر إتمام الطلب. تأكد من البيانات وحاول مرة أخرى.'
        : "Couldn't complete the request. Check your details and try again.";
  }

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
      return isArabic
          ? 'الاتصال بالإنترنت بطيء. تأكد من الشبكة وحاول مرة أخرى.'
          : 'Your internet connection seems slow. Please check it and try again.';
    case DioExceptionType.receiveTimeout:
      return isArabic
          ? 'استغرق الخادم وقتًا طويلاً للرد. يُرجى المحاولة لاحقًا.'
          : 'The server is taking too long to respond. Please try again later.';
    case DioExceptionType.connectionError:
      return isArabic
          ? 'تعذّر الاتصال بالإنترنت. يُرجى التأكد من الشبكة.'
          : "Couldn't connect to the internet. Please check your connection.";
    case DioExceptionType.badCertificate:
      return isArabic
          ? 'تعذّر التحقق من أمان الاتصال. تأكد من تاريخ الجهاز ثم حاول مرة أخرى.'
          : "Couldn't verify a secure connection. Please check your device's date and try again.";
    case DioExceptionType.cancel:
      return isArabic ? 'تم إلغاء الطلب.' : 'The request was cancelled.';
    case DioExceptionType.badResponse:
    case DioExceptionType.unknown:
      break;
  }

  return _generic(isArabic);
}

String _generic(bool isArabic) => isArabic
    ? 'حدث خطأ غير متوقع. يُرجى المحاولة مرة أخرى.'
    : 'Something went wrong. Please try again.';

/// Heuristic — if the backend message looks like a Dart/Java stack trace
/// or a JSON-serialised exception, we prefer the friendly fallback so the
/// user doesn't see something like
/// "DioException [bad response]: HTTP 502 ... at #0 ...".
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
