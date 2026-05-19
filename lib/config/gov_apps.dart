// ============================================================================
// File: config/gov_apps.dart
// Purpose: Static list of Saudi government apps with App Store / Play Store
//          fallback URLs. Used by feature 17 — quick launchers from Settings.
// ============================================================================

import 'package:flutter/material.dart';

class GovApp {
  final String key;
  final String arName;
  final String enName;
  final IconData icon;
  final String iosStoreUrl;
  final String androidStoreUrl;
  final String? webUrl;

  const GovApp({
    required this.key,
    required this.arName,
    required this.enName,
    required this.icon,
    required this.iosStoreUrl,
    required this.androidStoreUrl,
    this.webUrl,
  });
}

/// The 3 most-used Saudi gov apps for an HR-app audience. Confirmed App Store
/// IDs and Play Store package names. URL schemes are NOT public, so we open
/// the store link and let the OS forward to the installed app if present.
const List<GovApp> govApps = [
  GovApp(
    key: 'tawakkalna',
    arName: 'توكلنا',
    enName: 'Tawakkalna',
    icon: Icons.verified_user_outlined,
    iosStoreUrl: 'https://apps.apple.com/sa/app/tawakkalna/id1506236754',
    androidStoreUrl: 'https://play.google.com/store/apps/details?id=sa.gov.nic.twkhayat',
  ),
  GovApp(
    key: 'absher',
    arName: 'أبشر',
    enName: 'Absher',
    icon: Icons.fingerprint,
    iosStoreUrl: 'https://apps.apple.com/sa/app/absher/id1024907492',
    androidStoreUrl: 'https://play.google.com/store/apps/details?id=sa.gov.moi',
  ),
  GovApp(
    key: 'gosi',
    arName: 'التأمينات الاجتماعية',
    enName: 'GOSI',
    icon: Icons.shield_outlined,
    iosStoreUrl: 'https://apps.apple.com/sa/app/gosi-online/id1019316752',
    androidStoreUrl: 'https://play.google.com/store/apps/details?id=sa.gov.gosi.gosionline',
    webUrl: 'https://www.gosi.gov.sa',
  ),
];
