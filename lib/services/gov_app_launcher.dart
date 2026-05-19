// ============================================================================
// File: services/gov_app_launcher.dart
// Purpose: Open a Saudi gov app (Tawakkalna / Absher / GOSI) — uses the
//          platform-specific store URL, which the OS forwards to the
//          installed app if present.
// ============================================================================

import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

import '../config/gov_apps.dart';
import '../shared/utils/logger.dart';

class GovAppLauncher {
  static Future<bool> launch(GovApp app) async {
    final primary = Platform.isIOS ? app.iosStoreUrl : app.androidStoreUrl;
    final ok = await _tryLaunch(primary);
    if (ok) return true;
    final fallback = app.webUrl;
    if (fallback != null) return _tryLaunch(fallback);
    return false;
  }

  static Future<bool> _tryLaunch(String url) async {
    try {
      final uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      logD('GovAppLauncher failed for $url: $e');
      return false;
    }
  }
}
