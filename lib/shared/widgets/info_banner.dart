// ============================================================================
// File: shared/widgets/info_banner.dart
// Purpose: Generic colored banner with optional CTA and dismiss button.
//          Tiers: info (primary), warning (amber), error (red).
// Used by: iqama alert (feature 16), biometric-removed notice (feature 1),
//          future announcements / outage notices.
// ============================================================================

import 'package:flutter/material.dart';

import '../../theme.dart';

enum InfoBannerTier { info, warning, error }

class InfoBanner extends StatelessWidget {
  final InfoBannerTier tier;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final VoidCallback? onDismiss;

  const InfoBanner({
    super.key,
    required this.tier,
    required this.title,
    this.subtitle,
    this.icon,
    this.ctaLabel,
    this.onCta,
    this.onDismiss,
  });

  Color get _accent {
    switch (tier) {
      case InfoBannerTier.info:
        return AppColors.primary;
      case InfoBannerTier.warning:
        return AppColors.warning;
      case InfoBannerTier.error:
        return AppColors.danger;
    }
  }

  IconData get _defaultIcon {
    switch (tier) {
      case InfoBannerTier.info:
        return Icons.info_outline;
      case InfoBannerTier.warning:
        return Icons.warning_amber_rounded;
      case InfoBannerTier.error:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _accent;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? _defaultIcon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
                if (ctaLabel != null && onCta != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: onCta,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        ctaLabel!,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, size: 18, color: AppColors.muted),
              onPressed: onDismiss,
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
