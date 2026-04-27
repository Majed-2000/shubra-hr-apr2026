import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'logger.dart';

/// Builds a single User-Agent string from device + app info, used by the
/// Dio client so the backend's session row stores something readable
/// like "Shubra/1.0.0 (Galaxy S26 Ultra; Android 15)" instead of the
/// default "Dart/3.x".
///
/// Call [init] once at app start (before runApp) — subsequent reads
/// of [userAgent] / [platformLabel] / [deviceLabel] are sync.
class DeviceFingerprint {
  static String _userAgent = 'Shubra';
  static String _platformLabel = '';
  static String _deviceLabel = '';
  static bool _initialized = false;

  static String get userAgent => _userAgent;
  static String get platformLabel => _platformLabel;
  static String get deviceLabel => _deviceLabel;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      final pkg = await PackageInfo.fromPlatform();
      final appVersion = pkg.version.isEmpty ? '0.0.0' : pkg.version;

      final info = DeviceInfoPlugin();
      String device = '';
      String os = '';
      if (Platform.isAndroid) {
        final a = await info.androidInfo;
        // a.name is Settings.Global.DEVICE_NAME — on stock Samsung this is
        // the marketing name ("Galaxy S26 Ultra"). Falls back to the SKU
        // form ("samsung SM-S938B") if the user cleared/changed it.
        final friendly = a.name.trim();
        device = friendly.isNotEmpty
            ? friendly
            : '${a.manufacturer} ${a.model}'.trim();
        os = 'Android ${a.version.release}';
      } else if (Platform.isIOS) {
        final i = await info.iosInfo;
        device = i.utsname.machine;
        if (device.isEmpty) device = i.model;
        os = '${i.systemName} ${i.systemVersion}';
      } else {
        device = Platform.operatingSystem;
        os = Platform.operatingSystemVersion;
      }

      _platformLabel = os;
      _deviceLabel = device;
      _userAgent = 'Shubra/$appVersion ($device; $os)';
    } catch (e) {
      logD('DeviceFingerprint init failed: $e');
      // Leave defaults; UA stays "Shubra" so backend at least sees a tag.
    }
    _initialized = true;
  }
}
