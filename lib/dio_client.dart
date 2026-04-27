import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config/app_config.dart';
import 'shared/utils/logger.dart';

/// HTTP client wrapper around Dio.
///
/// - Injects the stored `access_token` as a Bearer header on every request.
/// - On 401, transparently calls `/refresh` with the saved `refresh_token`,
///   persists the new token pair, and retries the original request once.
class DioClient {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  DioClient() {
    _dio.options.baseUrl = AppConfig.apiBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final accessToken = await _storage.read(key: 'access_token');
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
            final refreshToken = await _storage.read(key: 'refresh_token');
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

              await _storage.write(key: 'access_token', value: newAccessToken);
              await _storage.write(key: 'refresh_token', value: newRefreshToken);

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
