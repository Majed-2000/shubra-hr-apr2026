import 'package:dio/dio.dart';

/// Pulls a human-readable message out of a Dio failure.
///
/// Priority:
///   1. Backend body's `message` / `error` / `detail` field.
///   2. HTTP status code (5xx → server error with code, 4xx with empty body
///      → fallback by code).
///   3. DioExceptionType-specific reason (timeout, unreachable host,
///      certificate, cancellation).
///   4. Raw `e.message`.
///   5. Generic "network error".
///
/// Callers pass [isArabic] so the message is rendered in the right
/// language when the backend body is empty.
String parseDioError(Object e, {required bool isArabic}) {
  if (e is! DioException) {
    return isArabic ? 'خطأ في الشبكة' : 'Network error';
  }

  // 1. Body-driven message wins — backend usually has the most specific text.
  final response = e.response;
  final data = response?.data;
  if (data is Map) {
    final raw = data['message'] ?? data['error'] ?? data['detail'];
    final msg = raw?.toString().trim();
    if (msg != null && msg.isNotEmpty) return msg;
  }
  if (data is String && data.trim().isNotEmpty) return data.trim();

  // 2. Got a response (so the server responded) but no useful body.
  final code = response?.statusCode;
  if (code != null) {
    if (code >= 500) {
      return isArabic
          ? "خطأ في الخادم ($code) — حاول لاحقًا"
          : "Server error ($code) — try again later";
    }
    if (code >= 400) {
      return isArabic
          ? "تعذر إتمام الطلب ($code)"
          : "Request rejected ($code)";
    }
  }

  // 3. No response — connection-layer failure. Tell the user *which* one.
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      return isArabic
          ? "انتهت مهلة الاتصال — تحقق من الإنترنت"
          : "Connection timed out — check your internet";
    case DioExceptionType.sendTimeout:
      return isArabic
          ? "انتهت مهلة إرسال الطلب — تحقق من الإنترنت"
          : "Send timed out — check your internet";
    case DioExceptionType.receiveTimeout:
      return isArabic
          ? "انتهت مهلة استقبال الرد من الخادم"
          : "Server took too long to respond";
    case DioExceptionType.badCertificate:
      return isArabic
          ? "خطأ في شهادة الأمان (SSL)"
          : "SSL certificate error";
    case DioExceptionType.connectionError:
      return isArabic
          ? "تعذر الوصول إلى الخادم — تحقق من اتصال الإنترنت"
          : "Couldn't reach the server — check your internet";
    case DioExceptionType.cancel:
      return isArabic ? "تم إلغاء الطلب" : "Request cancelled";
    case DioExceptionType.badResponse:
    case DioExceptionType.unknown:
      break;
  }

  // 4. Last resort — raw exception message (sometimes useful, sometimes
  // a long stack trace). Trim aggressively.
  final raw = e.message?.trim();
  if (raw != null && raw.isNotEmpty) {
    final firstLine = raw.split('\n').first.trim();
    if (firstLine.length <= 200) return firstLine;
  }

  return isArabic ? 'خطأ في الشبكة' : 'Network error';
}
