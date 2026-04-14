import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  DioClient() {
    _dio.options.baseUrl = 'https://cloud.shubra.net/api';
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
          print('Error reading token: $e');
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
              print('Token refresh failed: ${refreshResponse.statusCode}');
              return handler.reject(error);
            }
          } catch (e) {
            print('Refresh exception: $e');
            return handler.reject(error);
          }
        }

        return handler.next(error);
      },
    ));
  }

  Dio get client => _dio;
}
