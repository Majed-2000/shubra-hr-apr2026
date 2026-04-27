/// Centralised runtime configuration.
///
/// Values are read from `--dart-define` at compile time. Defaults are kept
/// for local development so the app builds without extra flags.
class AppConfig {
  /// Backend REST base URL. Override with:
  /// `flutter run --dart-define=API_BASE_URL=https://staging.example.com/api`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://cloud.shubra.net/api',
  );
}
