// ============================================================================
// File: prayer/prayer_service.dart
// Purpose: Compute today's prayer times (Umm Al-Qura method) offline using
//          adhan_dart. Caches lat/lng to secure_storage so we only ask
//          location once. Falls back to a city default if location denied.
// ============================================================================

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

import '../shared/utils/logger.dart';

class PrayerData {
  final PrayerTimes prayerTimes;
  final String nextName;
  final DateTime nextTime;
  const PrayerData({
    required this.prayerTimes,
    required this.nextName,
    required this.nextTime,
  });
}

class PrayerService {
  static const _storage = FlutterSecureStorage();
  static const kLat = 'prayer_lat';
  static const kLng = 'prayer_lng';
  static const kWidgetEnabled = 'prayer_widget_enabled';

  // Default to Riyadh if no location available.
  static const _defaultLat = 24.7136;
  static const _defaultLng = 46.6753;

  static Future<bool> get widgetEnabled async {
    final raw = await _storage.read(key: kWidgetEnabled);
    return raw != 'false'; // default ON
  }

  static Future<void> setWidgetEnabled(bool v) async {
    await _storage.write(key: kWidgetEnabled, value: v ? 'true' : 'false');
  }

  static Future<PrayerData?> computeToday() async {
    try {
      final coords = await _getCoordinates();
      final params = CalculationMethodParameters.ummAlQura();
      params.madhab = Madhab.shafi;

      final pt = PrayerTimes(
        coordinates: Coordinates(coords.lat, coords.lng),
        date: DateTime.now(),
        calculationParameters: params,
      );

      final now = DateTime.now();
      final next = _nextPrayer(pt, now);
      return PrayerData(
        prayerTimes: pt,
        nextName: next.$1,
        nextTime: next.$2,
      );
    } catch (e) {
      logD('PrayerService.computeToday failed: $e');
      return null;
    }
  }

  static (String, DateTime) _nextPrayer(PrayerTimes pt, DateTime now) {
    final candidates = <(String, DateTime)>[
      ('fajr', pt.fajr.toLocal()),
      ('dhuhr', pt.dhuhr.toLocal()),
      ('asr', pt.asr.toLocal()),
      ('maghrib', pt.maghrib.toLocal()),
      ('isha', pt.isha.toLocal()),
    ];
    for (final c in candidates) {
      if (c.$2.isAfter(now)) return c;
    }
    return ('fajr', pt.fajrAfter.toLocal());
  }

  static Future<({double lat, double lng})> _getCoordinates() async {
    final lat = double.tryParse(await _storage.read(key: kLat) ?? '');
    final lng = double.tryParse(await _storage.read(key: kLng) ?? '');
    if (lat != null && lng != null) return (lat: lat, lng: lng);
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.denied ||
            req == LocationPermission.deniedForever) {
          return (lat: _defaultLat, lng: _defaultLng);
        }
      }
      if (perm == LocationPermission.deniedForever) {
        return (lat: _defaultLat, lng: _defaultLng);
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      await _storage.write(key: kLat, value: pos.latitude.toString());
      await _storage.write(key: kLng, value: pos.longitude.toString());
      return (lat: pos.latitude, lng: pos.longitude);
    } catch (e) {
      logD('PrayerService location failed: $e');
      return (lat: _defaultLat, lng: _defaultLng);
    }
  }
}
