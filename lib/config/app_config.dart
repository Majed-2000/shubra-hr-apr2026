// ============================================================================
// ملف: config/app_config.dart
// الغرض: التهيئة المركزية للتطبيق (URLs، أكواد المسؤولين، روابط الصور).
// لماذا مهم: نجمع كل القيم القابلة للتغيير حسب البيئة (dev/staging/prod)
//          في مكان واحد، ونمررها عبر --dart-define وقت البناء.
// أمثلة استخدام:
//   flutter build apk --dart-define=API_BASE_URL=https://staging.shubra.net/api
// ============================================================================

/// Centralised runtime configuration.
///
/// Values are read from `--dart-define` at compile time. Defaults are kept
/// for local development so the app builds without extra flags.
///
/// كلاس بصيغة "static-only" — لا يُنشَأ instance، فقط ندخل عبر AppConfig.x.
class AppConfig {
  /// Backend REST base URL. Override with:
  /// `flutter run --dart-define=API_BASE_URL=https://staging.example.com/api`
  ///
  /// رابط الـ backend الأساسي. كل طلبات Dio تُبنى عليه.
  /// القيمة الافتراضية تعمل في الإنتاج: cloud.shubra.net
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://cloud.shubra.net/api',
  );

  /// Employee codes allowed to impersonate any user via Settings → "Switch user".
  /// The iOS UI just shows the option to these codes; the backend MUST also
  /// enforce admin authorization on `POST /admin/login-as` — never trust the
  /// client's empcode check alone.
  ///
  /// قائمة أكواد الموظفين المسموح لهم بالدخول كأي مستخدم آخر (impersonation).
  /// ⚠️ هذه القائمة في الـ frontend فقط لإظهار/إخفاء زر — الحماية الحقيقية في
  /// الـ backend (لا تثق بالعميل وحده).
  static const List<String> adminEmpcodes = ['10021'];

  /// URL template for fetching an employee's portrait. Default is the
  /// backend proxy at `<apiBaseUrl>/employee-photo/{empcode}` — the proxy
  /// looks up `pictpath` in PYEMPIMG, fetches the binary from the
  /// internal photo server, and streams it back over the same auth
  /// channel iOS already uses. Override (e.g. for a CDN, staging) with:
  ///   `flutter run --dart-define=EMPLOYEE_PHOTO_URL=https://photos.example.com/{empcode}1.JPG`
  /// The `{empcode}` token is substituted at request time.
  ///
  /// قالب رابط صورة الموظف. الـ {empcode} يُستبدَل بكود الموظف وقت الطلب.
  /// إذا تركناه فارغاً → نستخدم proxy الـ backend (GET /employee-photo/{empcode}).
  static const String employeePhotoUrlTemplate = String.fromEnvironment(
    'EMPLOYEE_PHOTO_URL',
    defaultValue: '',
  );

  /// Resolve a concrete photo URL for the given empcode. Returns null
  /// only when the empcode is empty. When the template is unset, falls
  /// back to the backend-proxy default so the iOS build "just works"
  /// once the backend ships `GET /employee-photo/{empcode}`.
  ///
  /// تُرجع رابط صورة موظف معين. خطوات:
  ///   1) إذا الـ empcode فارغ → null (لا صورة).
  ///   2) إذا القالب فارغ → نستخدم backend proxy الافتراضي.
  ///   3) نستبدل {empcode} بالكود الفعلي.
  static String? employeePhotoUrl(String empcode) {
    if (empcode.isEmpty) return null;
    final template = employeePhotoUrlTemplate.isEmpty
        ? '$apiBaseUrl/employee-photo/{empcode}'
        : employeePhotoUrlTemplate;
    return template.replaceAll('{empcode}', empcode);
  }
}
