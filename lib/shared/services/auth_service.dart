// ============================================================================
// File: shared/services/auth_service.dart
// Purpose: Reusable refresh-token logic, extracted from dio_client.dart's
//          interceptor so biometric login (feature 2) can refresh tokens
//          without going through a failed-request retry path.
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../config/app_config.dart';
import '../utils/logger.dart';

enum RefreshResult { success, invalidToken, networkError }

/// Stateless service: build a fresh Dio per call so this doesn't depend on
/// any interceptors. Mirrors the original logic in `dio_client.dart:79-132`
/// but exposes it as a public, callable method.
class AuthService {
  static const _storage = FlutterSecureStorage();

  static Future<({String accessKey, String refreshKey})> _activeKeys() async {
    final view = await _storage.read(key: 'current_view');
    if (view == 'mgr') {
      final mgrAccess = await _storage.read(key: 'mgr_access_token');
      if (mgrAccess != null) {
        return (accessKey: 'mgr_access_token', refreshKey: 'mgr_refresh_token');
      }
    }
    return (accessKey: 'access_token', refreshKey: 'refresh_token');
  }

  /// Refresh the active-scope access token using its refresh token.
  /// Used by: biometric login flow (return user → check refresh → unlock).
  static Future<RefreshResult> refreshAccessToken() async {
    try {
      final keys = await _activeKeys();
      final refreshToken = await _storage.read(key: keys.refreshKey);
      if (refreshToken == null || refreshToken.isEmpty) {
        return RefreshResult.invalidToken;
      }

      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final res = await dio.post(
        '/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {'Authorization': 'Bearer $refreshToken'},
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      if (res.statusCode == 200) {
        await _storage.write(key: keys.accessKey, value: res.data['access_token']);
        await _storage.write(key: keys.refreshKey, value: res.data['refresh_token']);
        return RefreshResult.success;
      }

      logD('AuthService refresh failed: ${res.statusCode}');
      return RefreshResult.invalidToken;
    } on DioException catch (e) {
      logD('AuthService refresh network error: $e');
      return RefreshResult.networkError;
    } catch (e) {
      logD('AuthService refresh exception: $e');
      return RefreshResult.networkError;
    }
  }

  /// True if any access token is stored (either user or manager scope).
  static Future<bool> hasAnyToken() async {
    final user = await _storage.read(key: 'access_token');
    final mgr = await _storage.read(key: 'mgr_access_token');
    return (user != null && user.isNotEmpty) || (mgr != null && mgr.isNotEmpty);
  }

  /// Wipe all session tokens. Keeps locale, theme, biometric prefs.
  static Future<void> clearSession() async {
    const sessionKeys = [
      'access_token',
      'refresh_token',
      'mgr_access_token',
      'mgr_refresh_token',
      'current_view',
      'is_manager',
      'name',
      'empcode',
    ];
    for (final k in sessionKeys) {
      await _storage.delete(key: k);
    }
  }
}
