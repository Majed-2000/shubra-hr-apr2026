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
class DioClient {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

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
    _dio.options.baseUrl = AppConfig.apiBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final keys = await _activeKeys();
          final accessToken = await _storage.read(key: keys.accessKey);
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
        } catch (e) {
          logD('Error reading token: $e');
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          try {
            final keys = await _activeKeys();
            final refreshToken = await _storage.read(key: keys.refreshKey);
            if (refreshToken == null) {
              return handler.reject(error);
            }

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
              final newAccessToken = refreshResponse.data['access_token'];
              final newRefreshToken = refreshResponse.data['refresh_token'];

              await _storage.write(key: keys.accessKey, value: newAccessToken);
              await _storage.write(key: keys.refreshKey, value: newRefreshToken);

              final retryRequest = error.requestOptions;
              retryRequest.headers['Authorization'] = 'Bearer $newAccessToken';

              final clonedResponse = await _dio.fetch(retryRequest);
              return handler.resolve(clonedResponse);
            } else {
              logD('Token refresh failed: ${refreshResponse.statusCode}');
              return handler.reject(error);
            }
          } catch (e) {
            logD('Refresh exception: $e');
            return handler.reject(error);
          }
        }

        return handler.next(error);
      },
    ));
  }

  Dio get client => _dio;
}
