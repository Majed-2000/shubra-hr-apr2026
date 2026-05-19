// ============================================================================
// File: shared/services/sync_tracker.dart
// Purpose: Per-screen "last successful fetch" timestamps for the LastSyncBadge
//          widget (feature 14). Persisted to secure_storage so the badge
//          survives cold starts and correctly shows "offline data from 2h ago".
// Keys: sync_<screenKey> → ISO8601 string
// ============================================================================

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SyncTracker {
  static const _storage = FlutterSecureStorage();
  static String _key(String screenKey) => 'sync_$screenKey';

  /// Call inside a fetch method right after the response is committed to state.
  static Future<void> markSynced(String screenKey) async {
    await _storage.write(
      key: _key(screenKey),
      value: DateTime.now().toUtc().toIso8601String(),
    );
  }

  static Future<DateTime?> lastSynced(String screenKey) async {
    final raw = await _storage.read(key: _key(screenKey));
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// Remove a screen's timestamp (e.g. on logout).
  static Future<void> clear(String screenKey) async {
    await _storage.delete(key: _key(screenKey));
  }
}
