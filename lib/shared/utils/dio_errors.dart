import 'package:dio/dio.dart';

/// Pulls a human-readable message out of a Dio failure.
///
/// The backend returns errors in several shapes (`message`, `error`, `success`,
/// `detail`); this checks them in priority order and falls back to the raw
/// network exception message. Callers pass [isArabic] so a generic fallback
/// can be rendered in the right language when nothing usable is in the body.
String parseDioError(Object e, {required bool isArabic}) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = (data['message'] ??
              data['error'] ??
              data['success'] ??
              data['detail'])
          ?.toString();
      if (msg != null && msg.isNotEmpty) return msg;
    }
    if (data is String && data.isNotEmpty) return data;
    if (e.message != null && e.message!.isNotEmpty) return e.message!;
  }
  return isArabic ? 'خطأ في الشبكة' : 'Network error';
}
