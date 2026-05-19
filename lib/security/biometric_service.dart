// ============================================================================
// File: security/biometric_service.dart
// Purpose: Thin wrapper around local_auth + secure_storage for biometric
//          app lock (feature 1) and biometric login (feature 2).
// ============================================================================

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

import '../shared/utils/logger.dart';

enum BiometricStatus {
  unavailable,    // device has no biometric hardware
  notEnrolled,    // hardware exists but no biometric set up
  available,      // ready to authenticate
}

enum BiometricResult {
  success,
  failed,         // user dismissed or failed
  unavailable,    // hardware/OS issue
  locked,         // too many tries — OS-level lockout
  enrollmentChanged, // device biometric set was modified since enroll
}

class BiometricService {
  static const _storage = FlutterSecureStorage();
  static final _auth = LocalAuthentication();

  /// Storage keys (kept centralized to avoid typos elsewhere).
  static const kLockEnabled = 'lock_screen_enabled';
  static const kLockTimeoutSec = 'lock_timeout_seconds';
  static const kLoginEnabled = 'biometric_login_enabled';
  static const kEnrolledAt = 'biometric_enrolled_at';
  static const kEnrolledTypes = 'biometric_enrolled_types';
  static const kNudgeDismissed = 'biometric_nudge_dismissed';

  static Future<BiometricStatus> status() async {
    try {
      final available = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      if (!available || !supported) return BiometricStatus.unavailable;
      final list = await _auth.getAvailableBiometrics();
      if (list.isEmpty) return BiometricStatus.notEnrolled;
      return BiometricStatus.available;
    } catch (e) {
      logD('BiometricService.status error: $e');
      return BiometricStatus.unavailable;
    }
  }

  /// Prompt the OS biometric sheet. Returns a typed result.
  static Future<BiometricResult> authenticate({required String reason}) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // allow device passcode as fallback
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (!ok) return BiometricResult.failed;
      // Compare enrolled biometric set against snapshot. If different,
      // require re-enroll (defends against attacker enrolling their face).
      final stored = await _storage.read(key: kEnrolledTypes);
      final current = (await _auth.getAvailableBiometrics()).map((e) => e.name).join(',');
      if (stored != null && stored.isNotEmpty && stored != current) {
        return BiometricResult.enrollmentChanged;
      }
      return BiometricResult.success;
    } on PlatformException catch (e) {
      logD('BiometricService.authenticate platform error: ${e.code}');
      if (e.code == auth_error.notAvailable || e.code == auth_error.passcodeNotSet) {
        return BiometricResult.unavailable;
      }
      if (e.code == auth_error.lockedOut || e.code == auth_error.permanentlyLockedOut) {
        return BiometricResult.locked;
      }
      return BiometricResult.failed;
    } catch (e) {
      logD('BiometricService.authenticate error: $e');
      return BiometricResult.failed;
    }
  }

  // ── Preference helpers ────────────────────────────────────────────

  static Future<bool> get isLockEnabled async =>
      (await _storage.read(key: kLockEnabled)) == 'true';

  static Future<int> get lockTimeoutSeconds async =>
      int.tryParse(await _storage.read(key: kLockTimeoutSec) ?? '60') ?? 60;

  static Future<bool> get isLoginEnabled async =>
      (await _storage.read(key: kLoginEnabled)) == 'true';

  static Future<bool> get wasNudgeDismissed async =>
      (await _storage.read(key: kNudgeDismissed)) == 'true';

  static Future<void> setLockEnabled(bool v) async {
    await _storage.write(key: kLockEnabled, value: v ? 'true' : 'false');
    if (v) await _snapshotEnrollment();
  }

  static Future<void> setLockTimeout(int seconds) async {
    await _storage.write(key: kLockTimeoutSec, value: seconds.toString());
  }

  static Future<void> setLoginEnabled(bool v) async {
    await _storage.write(key: kLoginEnabled, value: v ? 'true' : 'false');
    if (v) await _snapshotEnrollment();
  }

  static Future<void> markNudgeDismissed() async {
    await _storage.write(key: kNudgeDismissed, value: 'true');
  }

  static Future<void> _snapshotEnrollment() async {
    try {
      final list = await _auth.getAvailableBiometrics();
      await _storage.write(
        key: kEnrolledTypes,
        value: list.map((e) => e.name).join(','),
      );
      await _storage.write(
        key: kEnrolledAt,
        value: DateTime.now().toUtc().toIso8601String(),
      );
    } catch (e) {
      logD('snapshotEnrollment error: $e');
    }
  }

  /// Wipe biometric flags (called when biometric is removed from device,
  /// or when refresh-token failure forces re-OTP).
  static Future<void> reset() async {
    await _storage.delete(key: kLockEnabled);
    await _storage.delete(key: kLoginEnabled);
    await _storage.delete(key: kEnrolledAt);
    await _storage.delete(key: kEnrolledTypes);
  }
}
