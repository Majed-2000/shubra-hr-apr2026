// ============================================================================
// File: shared/services/local_cache.dart
// Purpose: Generic JSON cache over secure_storage with TTL semantics.
//          Used by: offline digital card (feature 5), document vault
//          metadata (feature 9), gov apps config (feature 17).
// Layout: each entry stored as JSON-encoded { savedAt: ISO, ttlSec: int, data: ... }
// ============================================================================

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/logger.dart';

class CachedValue<T> {
  final T data;
  final Duration age;
  final bool expired;
  const CachedValue({required this.data, required this.age, required this.expired});
}

class LocalCache {
  static const _storage = FlutterSecureStorage();
  static String _key(String key) => 'cache_$key';

  /// Store a JSON-encodable value with TTL. After ttl elapses, [get] still
  /// returns the data but marks `expired: true` so callers can decide
  /// (e.g. render-cache-first then background-refresh).
  static Future<void> set(String key, Object value, {Duration ttl = const Duration(days: 7)}) async {
    final envelope = {
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'ttlSec': ttl.inSeconds,
      'data': value,
    };
    await _storage.write(key: _key(key), value: jsonEncode(envelope));
  }

  static Future<CachedValue<T>?> get<T>(String key) async {
    final raw = await _storage.read(key: _key(key));
    if (raw == null || raw.isEmpty) return null;
    try {
      final env = jsonDecode(raw) as Map<String, dynamic>;
      final saved = DateTime.tryParse(env['savedAt'] as String? ?? '');
      if (saved == null) return null;
      final ttl = Duration(seconds: (env['ttlSec'] as int?) ?? 0);
      final age = DateTime.now().toUtc().difference(saved);
      return CachedValue<T>(
        data: env['data'] as T,
        age: age,
        expired: ttl.inSeconds > 0 && age > ttl,
      );
    } catch (e) {
      logD('LocalCache decode failed for $key: $e');
      return null;
    }
  }

  static Future<void> clear(String key) async {
    await _storage.delete(key: _key(key));
  }
}
