// ============================================================================
// File: shared/services/feature_flags.dart
// Purpose: Gate backend-dependent features (documents, tickets, iqama) while
//          backend catches up. Defaults to OFF in production; flip via
//          --dart-define for TestFlight/debug builds:
//   flutter build ipa --release --dart-define=FF_DOCUMENT_VAULT=true \
//                                --dart-define=FF_TICKETS=true \
//                                --dart-define=FF_IQAMA_ALERT=true
// ============================================================================

class FeatureFlags {
  static const bool documentVaultEnabled = bool.fromEnvironment(
    'FF_DOCUMENT_VAULT',
    defaultValue: false,
  );

  static const bool ticketsEnabled = bool.fromEnvironment(
    'FF_TICKETS',
    defaultValue: false,
  );

  static const bool iqamaAlertEnabled = bool.fromEnvironment(
    'FF_IQAMA_ALERT',
    defaultValue: false,
  );

  /// Use mock fixtures even when a real endpoint exists.
  /// Useful for QA in TestFlight before backend goes live.
  static const bool useMockData = bool.fromEnvironment(
    'FF_USE_MOCK',
    defaultValue: false,
  );
}
