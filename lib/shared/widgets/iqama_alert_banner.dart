// ============================================================================
// File: shared/widgets/iqama_alert_banner.dart
// Purpose: Home-screen banner warning of upcoming iqama expiry (feature 16).
//          Reads iqama_expiry + nationality from the profile or MockRepo
//          when feature flag is off. Saudi nationals + null expiry → hidden.
// Tiers: 60-31d amber, 30-15d orange, 14-1d red, expired red persistent.
// ============================================================================

import 'package:flutter/material.dart';

import '../../shared/services/feature_flags.dart';
import '../../shared/services/mock_repo.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'info_banner.dart';

class IqamaAlertBanner extends StatefulWidget {
  /// Profile map from /myinfoview (the 'info' sub-map).
  final Map<String, dynamic>? profileInfo;
  const IqamaAlertBanner({super.key, this.profileInfo});

  @override
  State<IqamaAlertBanner> createState() => _IqamaAlertBannerState();
}

class _IqamaAlertBannerState extends State<IqamaAlertBanner> {
  bool _dismissed = false;

  ({DateTime expiry, String nationality})? _resolve() {
    String? expiryRaw;
    String? nationality;
    final info = widget.profileInfo;
    if (info != null) {
      expiryRaw = (info['iqama_expiry'] ??
              info['id_expiry'] ??
              info['residency_expiry'])
          ?.toString();
      nationality = (info['nationality'] ?? info['nat_code'])?.toString();
    }
    if (expiryRaw == null || nationality == null) {
      // Backend hasn't shipped fields yet. Fall back to mock when
      // dev/QA flag is on; otherwise hide.
      if (!FeatureFlags.iqamaAlertEnabled && !FeatureFlags.useMockData) {
        return null;
      }
      final mock = MockRepo.iqamaInfo();
      expiryRaw ??= mock['iqama_expiry'] as String;
      nationality ??= mock['nationality'] as String;
    }
    final expiry = DateTime.tryParse(expiryRaw);
    if (expiry == null) return null;
    return (expiry: expiry, nationality: nationality);
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final resolved = _resolve();
    if (resolved == null) return const SizedBox.shrink();
    if (resolved.nationality.toUpperCase() == 'SA') {
      return const SizedBox.shrink();
    }
    final days = resolved.expiry.difference(DateTime.now()).inDays;

    InfoBannerTier tier;
    IconData icon;
    String title;
    if (days <= 0) {
      tier = InfoBannerTier.error;
      icon = Icons.error_outline_rounded;
      title = bi(context,
          ar: 'انتهت إقامتك منذ ${-days} يوم — تواصل مع الموارد البشرية',
          en: 'Iqama expired ${-days} days ago — contact HR');
    } else if (days <= 14) {
      tier = InfoBannerTier.error;
      icon = Icons.warning_amber_rounded;
      title = bi(context,
          ar: 'عاجل: تنتهي إقامتك خلال $days يوم',
          en: 'Urgent: iqama expires in $days days');
    } else if (days <= 30) {
      tier = InfoBannerTier.warning;
      icon = Icons.warning_amber_rounded;
      title = bi(context,
          ar: 'جدّد إقامتك — متبقي $days يوم',
          en: 'Renew your iqama — $days days left');
    } else if (days <= 60) {
      tier = InfoBannerTier.warning;
      icon = Icons.info_outline_rounded;
      title = bi(context,
          ar: 'تنتهي إقامتك خلال $days يوم',
          en: 'Iqama expires in $days days');
    } else {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: InfoBanner(
        tier: tier,
        icon: icon,
        title: title,
        ctaLabel: bi(context, ar: 'طلب تجديد الإقامة', en: 'Request renewal'),
        onCta: () {
          Navigator.pushNamed(context, '/complaint');
        },
        onDismiss: days > 0
            ? () => setState(() => _dismissed = true)
            : null, // can't dismiss expired
      ),
    );
  }
}
