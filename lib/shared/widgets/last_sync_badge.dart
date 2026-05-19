// ============================================================================
// File: shared/widgets/last_sync_badge.dart
// Purpose: Compact pill showing relative time since data was last successfully
//          fetched ("محدّث منذ ساعتين / Updated 2h ago"). Renders nothing
//          when data is fresh (<5 min) to avoid clutter.
// Color tiers: muted (<1h), amber (1-24h), red (>24h).
// Feeds from SyncTracker. Tap to call onRefresh if provided.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../theme.dart';
import '../services/sync_tracker.dart';

class LastSyncBadge extends StatefulWidget {
  final String screenKey;
  final VoidCallback? onRefresh;

  const LastSyncBadge({
    super.key,
    required this.screenKey,
    this.onRefresh,
  });

  @override
  State<LastSyncBadge> createState() => _LastSyncBadgeState();
}

class _LastSyncBadgeState extends State<LastSyncBadge> {
  static bool _arRegistered = false;
  DateTime? _lastSynced;

  @override
  void initState() {
    super.initState();
    _registerArabicLocale();
    _refresh();
  }

  @override
  void didUpdateWidget(covariant LastSyncBadge old) {
    super.didUpdateWidget(old);
    if (old.screenKey != widget.screenKey) _refresh();
  }

  void _registerArabicLocale() {
    if (_arRegistered) return;
    timeago.setLocaleMessages('ar', timeago.ArMessages());
    _arRegistered = true;
  }

  Future<void> _refresh() async {
    final t = await SyncTracker.lastSynced(widget.screenKey);
    if (mounted) setState(() => _lastSynced = t);
  }

  @override
  Widget build(BuildContext context) {
    final t = _lastSynced;
    if (t == null) return const SizedBox.shrink();
    final age = DateTime.now().toUtc().difference(t);
    // Hide for fresh data (<5 min).
    if (age.inMinutes < 5) return const SizedBox.shrink();

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final locale = isAr ? 'ar' : 'en';
    final relative = timeago.format(t, locale: locale);

    final color = age.inHours < 1
        ? AppColors.muted
        : age.inHours < 24
            ? AppColors.warning
            : AppColors.danger;

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            isAr ? 'محدّث $relative' : 'Updated $relative',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (widget.onRefresh == null) return pill;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xs),
      onTap: () {
        widget.onRefresh!();
        _refresh();
      },
      child: pill,
    );
  }
}
