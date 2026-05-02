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

  /// Employee codes allowed to impersonate any user via Settings → "Switch user".
  /// The iOS UI just shows the option to these codes; the backend MUST also
  /// enforce admin authorization on `POST /admin/login-as` — never trust the
  /// client's empcode check alone.
  static const List<String> adminEmpcodes = ['10021'];

  /// URL template for fetching an employee's portrait. Default is the
  /// backend proxy at `<apiBaseUrl>/employee-photo/{empcode}` — the proxy
  /// looks up `pictpath` in PYEMPIMG, fetches the binary from the
  /// internal photo server, and streams it back over the same auth
  /// channel iOS already uses. Override (e.g. for a CDN, staging) with:
  ///   `flutter run --dart-define=EMPLOYEE_PHOTO_URL=https://photos.example.com/{empcode}1.JPG`
  /// The `{empcode}` token is substituted at request time.
  static const String employeePhotoUrlTemplate = String.fromEnvironment(
    'EMPLOYEE_PHOTO_URL',
    defaultValue: '',
  );

  /// Resolve a concrete photo URL for the given empcode. Returns null
  /// only when the empcode is empty. When the template is unset, falls
  /// back to the backend-proxy default so the iOS build "just works"
  /// once the backend ships `GET /employee-photo/{empcode}`.
  static String? employeePhotoUrl(String empcode) {
    if (empcode.isEmpty) return null;
    final template = employeePhotoUrlTemplate.isEmpty
        ? '$apiBaseUrl/employee-photo/{empcode}'
        : employeePhotoUrlTemplate;
    return template.replaceAll('{empcode}', empcode);
  }
}
