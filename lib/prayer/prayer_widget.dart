// ============================================================================
// File: prayer/prayer_widget.dart
// Purpose: Compact card showing next prayer name + countdown, intended to
//          sit above the home menu grid. Updates once a minute while visible.
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';
import 'prayer_service.dart';

class PrayerWidget extends StatefulWidget {
  const PrayerWidget({super.key});

  @override
  State<PrayerWidget> createState() => _PrayerWidgetState();
}

class _PrayerWidgetState extends State<PrayerWidget> {
  PrayerData? _data;
  bool _enabled = true;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await PrayerService.widgetEnabled;
    if (!enabled) {
      if (mounted) setState(() => _enabled = false);
      return;
    }
    final data = await PrayerService.computeToday();
    if (!mounted) return;
    setState(() => _data = data);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      // If next prayer passed → recompute. Otherwise just rebuild countdown.
      if (_data != null && DateTime.now().isAfter(_data!.nextTime)) {
        _load();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _prayerLabel(String key) {
    switch (key) {
      case 'fajr':
        return bi(context, ar: 'الفجر', en: 'Fajr');
      case 'dhuhr':
        return bi(context, ar: 'الظهر', en: 'Dhuhr');
      case 'asr':
        return bi(context, ar: 'العصر', en: 'Asr');
      case 'maghrib':
        return bi(context, ar: 'المغرب', en: 'Maghrib');
      case 'isha':
        return bi(context, ar: 'العشاء', en: 'Isha');
    }
    return key;
  }

  String _countdown(DateTime target) {
    final diff = target.difference(DateTime.now());
    if (diff.isNegative) return '';
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    if (h > 0) {
      return bi(context, ar: 'بعد ${h} س ${m} د', en: 'in ${h}h ${m}m');
    }
    return bi(context, ar: 'بعد ${m} دقيقة', en: 'in ${m}m');
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled) return const SizedBox.shrink();
    final d = _data;
    if (d == null) return const SizedBox.shrink();
    final timeFmt = '${d.nextTime.hour.toString().padLeft(2, '0')}:${d.nextTime.minute.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.mosque_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _prayerLabel(d.nextName),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _countdown(d.nextTime),
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeFmt,
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
