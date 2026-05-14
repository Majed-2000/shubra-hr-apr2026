// ============================================================================
// ملف: dio_client.dart
// الغرض: غلاف (wrapper) حول مكتبة Dio لإدارة:
//   - الـ base URL والـ timeouts.
//   - حقن الـ access_token في كل طلب تلقائياً.
//   - تجديد الـ token عند انتهائه (401) وإعادة محاولة الطلب.
//   - فصل scope الموظف (access_token) عن scope المدير (mgr_access_token).
// كيف يُستخدم:
//   final dio = DioClient().client;
//   final response = await dio.get('/employee/info');
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config/app_config.dart';
import 'shared/utils/logger.dart';

/// HTTP client wrapper around Dio.
///
/// Picks an access token based on `current_view` so a user who is also a
/// manager can have two scopes side-by-side: the regular `access_token`
/// for employee endpoints, and `mgr_access_token` for `/mgr/*` endpoints.
/// Falls back to the user token when the manager pair isn't stored.
///
/// النمط: dual-token scope.
/// السبب: نفس المستخدم قد يكون موظفاً ومديراً في نفس الوقت — لكل واجهة token
///       منفصل لتجنّب اختلاط الصلاحيات.
class DioClient {
  /// الـ instance الفعلي من Dio (محمي، نعرّضه عبر [client]).
  final Dio _dio = Dio();

  /// secure storage مشفّر — مكان آمن لتخزين الـ tokens (لا shared_preferences).
  final _storage = const FlutterSecureStorage();

  /// يقرّر أي مفاتيح storage نستعملها للقراءة/الكتابة (موظف أم مدير).
  ///
  /// المنطق:
  ///   - إذا current_view == 'mgr' وموجود mgr_access_token → استعمل scope المدير.
  ///   - وإلا → استعمل scope الموظف (الافتراضي).
  /// يُرجع record فيه اسمَي المفتاحين (record syntax = Dart 3+).
  Future<({String accessKey, String refreshKey})> _activeKeys() async {
    final view = await _storage.read(key: 'current_view');
    if (view == 'mgr') {
      final mgrAccess = await _storage.read(key: 'mgr_access_token');
      if (mgrAccess != null) {
        return (accessKey: 'mgr_access_token', refreshKey: 'mgr_refresh_token');
      }
    }
    return (accessKey: 'access_token', refreshKey: 'refresh_token');
  }

  DioClient() {
    // الإعدادات الأساسية: الـ URL وقت timeout.
    _dio.options.baseUrl = AppConfig.apiBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    // Interceptor = نقطة تنصت على كل طلب/استجابة.
    _dio.interceptors.add(InterceptorsWrapper(
      // ───── onRequest: قبل إرسال أي طلب ─────
      onRequest: (options, handler) async {
        try {
          // نختار أي token (موظف/مدير) ثم نضيفه في Authorization header.
          final keys = await _activeKeys();
          final accessToken = await _storage.read(key: keys.accessKey);
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
        } catch (e) {
          // نلوّغ الخطأ لكن لا نوقف الطلب (قد يكون endpoint عام بدون مصادقة).
          logD('Error reading token: $e');
        }
        // نمرر الطلب لمواصلة سلسلة الـ interceptors → الإرسال الفعلي.
        return handler.next(options);
      },

      // ───── onError: عند فشل أي طلب ─────
      onError: (DioException error, handler) async {
        // نهتم فقط بـ 401 (token منتهٍ) — باقي الأخطاء نمررها كما هي.
        if (error.response?.statusCode == 401) {
          try {
            final keys = await _activeKeys();
            final refreshToken = await _storage.read(key: keys.refreshKey);
            if (refreshToken == null) {
              // لا يوجد refresh token → لا يمكن التجديد، نرفض الخطأ.
              return handler.reject(error);
            }

            // نطلب tokens جديدة من /refresh.
            // validateStatus < 500 = نقبل 4xx لنفحصها يدوياً (لا يُلقي exception).
            final refreshResponse = await _dio.post(
              '/refresh',
              data: {
                'refresh_token': refreshToken,
              },
              options: Options(
                headers: {
                  'Authorization': 'Bearer $refreshToken',
                },
                validateStatus: (status) => status != null && status < 500,
              ),
            );
            if (refreshResponse.statusCode == 200) {
              // نجح التجديد — نخزّن الـ tokens الجديدة.
              final newAccessToken = refreshResponse.data['access_token'];
              final newRefreshToken = refreshResponse.data['refresh_token'];

              await _storage.write(key: keys.accessKey, value: newAccessToken);
              await _storage.write(key: keys.refreshKey, value: newRefreshToken);

              // نُعيد محاولة الطلب الأصلي مع الـ token الجديد.
              final retryRequest = error.requestOptions;
              retryRequest.headers['Authorization'] = 'Bearer $newAccessToken';

              final clonedResponse = await _dio.fetch(retryRequest);
              // resolve = نُرجع الاستجابة الناجحة كأن الطلب الأصلي نجح من المرة الأولى.
              return handler.resolve(clonedResponse);
            } else {
              // فشل التجديد (refresh token منتهٍ أيضاً).
              // نمسح الـ tokens الفاسدة كي يعود SplashScreen يوجّه المستخدم
              // إلى شاشة الدخول عند فتح التطبيق مرة أخرى.
              logD('Token refresh failed: ${refreshResponse.statusCode} — clearing session');
              await _clearSession();
              return handler.reject(error);
            }
          } catch (e) {
            // exception أثناء التجديد (شبكة عادةً).
            // ⚠️ لا نمسح الـ tokens — قد تكون الشبكة فقط مقطوعة وستعود لاحقاً.
            logD('Refresh exception: $e');
            return handler.reject(error);
          }
        }

        // ليس 401 → نمرّر الخطأ للـ caller كما هو.
        return handler.next(error);
      },
    ));
  }

  /// getter لكشف الـ Dio instance المُعدّ، لكي يستعمله بقية الكود.
  Dio get client => _dio;

  /// مسح كل tokens الجلسة الحالية (user + mgr) مع الإبقاء على اللغة.
  /// يُستدعى عند فشل التجديد — يجبر المستخدم على إعادة الدخول
  /// عند الـ SplashScreen القادم.
  Future<void> _clearSession() async {
    try {
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      await _storage.delete(key: 'mgr_access_token');
      await _storage.delete(key: 'mgr_refresh_token');
      await _storage.delete(key: 'current_view');
      await _storage.delete(key: 'is_manager');
      await _storage.delete(key: 'name');
      await _storage.delete(key: 'empcode');
    } catch (e) {
      logD('Clear session failed: $e');
    }
  }
}
