// ============================================================================
// ملف: login.dart
// الغرض: شاشة تسجيل الدخول بنظام OTP (رمز تحقق لمرّة واحدة).
// التدفق:
//   1) المستخدم يُدخل رقم الموظف (empcode).
//   2) نُرسل POST /login → يُرسل الـ backend رمز OTP عبر SMS أو إيميل.
//   3) يظهر dialog لإدخال OTP (6 أرقام) + مؤقت 120 ثانية.
//   4) عند الإدخال نُرسل POST /verify-user → نستلم access_token + refresh_token.
//   5) نخزّن الـ tokens في secure storage ونحوّل إلى /home.
// ميزات إضافية:
//   - زر إعادة إرسال OTP يُفعّل بعد 120 ثانية.
//   - دعم scope مدير (mgr_access_token) إن كان المستخدم مديراً أيضاً.
//   - تبديل اللغة من الزر في الزاوية.
// ============================================================================

import 'dart:async';
import 'package:dio/dio.dart' show DioException, Options;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shubraepp/main.dart';
import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'shared/utils/dio_errors.dart';
import 'shared/utils/logger.dart';
import 'shared/utils/snackbar.dart';
import 'theme.dart';
import 'widgets.dart';

/// Employee OTP-based login screen with 120-second resend timer.
///
/// شاشة دخول الموظف عبر OTP — مع مؤقّت 120 ثانية لإعادة الإرسال.
class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // مفتاح للنموذج لكي نستطيع استدعاء validate() قبل الإرسال.
  final _formKey = GlobalKey<FormState>();
  // متحكّمات الحقول.
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  // وصول لـ secure storage و Dio.
  final _storage = const FlutterSecureStorage();
  final dioClient = DioClient().client;

  bool isfilled = false;        // هل OTP اكتمل 6 أرقام؟ (للتفعيل/التعطيل).
  bool _canResend = false;       // هل يمكن إعادة إرسال OTP الآن؟
  bool _loading = false;         // هل طلب /login جارٍ؟
  int _secondsRemaining = 120;   // عداد الـ resend (يبدأ من 120).
  Timer? _timer;                 // المؤقّت الذي يُنقص الـ counter.

  @override
  void initState() {
    super.initState();
    // عند فتح الشاشة، نفحص إذا كان المستخدم مسجلاً مسبقاً.
    gettoken();
  }

  /// إذا كان token موجود في storage → نتجاوز شاشة الدخول مباشرة.
  /// (هذا حماية إضافية فوق SplashScreen — نادر أن تُستدعى).
  Future<void> gettoken() async {
    var token = await _storage.read(key: "access_token");
    if (token != null) {
      Navigator.pushReplacementNamed(context, "/home");
    }
  }

  /// الخطوة 1: طلب إرسال OTP.
  /// نُرسل empcode إلى /login، الـ backend يُرسل رمزاً عبر SMS/إيميل.
  /// عند النجاح → نفتح dialog إدخال OTP ونشغّل المؤقت.
  Future<void> requestOtp() async {
    setState(() => _loading = true);
    try {
      // POST /login مع empcode في الـ body.
      final response = await dioClient.post(
        '/login',
        data: {'empcode': _employeeIdController.text},
        // Don't throw on 4xx — we want the body's `message` instead of a
        // generic DioException, so the user sees the real reason.
        //
        // مهم: لا نرمي exception على 4xx، نُريد قراءة body لرسالة الخطأ المحددة.
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      final data = response.data;
      final code = response.statusCode ?? 0;
      // نجاح إذا 200 + status == "success".
      if (code == 200 && data is Map && data['status'] == 'success') {
        _showOtpModal();          // افتح dialog إدخال OTP.
        startResendTimer();        // ابدأ عدّ 120 ثانية.
      } else {
        // فشل (مثلاً 404 رقم موظف غير موجود) — نعرض رسالة ودودة.
        logD('login /login failed: $code body=$data');
        _snack(_authErrorFor(code, data, isOtpStep: false));
      }
    } on DioException catch (e) {
      // خطأ شبكي (no internet, timeout, ...) — نحوّله لرسالة عربية مفهومة.
      logD('login /login dio exception: ${e.message} body=${e.response?.data}');
      _snack(parseDioError(e, isArabic: isArabic(context)));
    } catch (e) {
      // أي exception غير متوقع.
      logD('login /login unexpected: $e');
      _snack(AppLocalizations.of(context)!.wronginfo);
    } finally {
      // أوقف مؤشر التحميل بغض النظر عن النتيجة.
      if (mounted) setState(() => _loading = false);
    }
  }

  /// الخطوة 2: تحقق من OTP وسجّل دخول.
  /// نُرسل empcode + otp إلى /verify-user، نستلم الـ tokens ونخزّنها.
  Future<void> verifyOtp() async {
    try {
      final response = await dioClient.post(
        '/verify-user',
        data: {
          'empcode': _employeeIdController.text,
          'otp': _otpController.text,
        },
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      final data = response.data;
      final code = response.statusCode ?? 0;
      if (code == 200 && data is Map && data['status'] == 'success') {
        // ━━━ تخزين بيانات الجلسة في secure storage (مشفّرة) ━━━
        await _storage.write(key: 'access_token', value: data['access_token']);
        await _storage.write(key: 'refresh_token', value: data['refresh_token']);
        await _storage.write(key: 'name', value: data['user']['name']);
        // Persist empcode so settings/admin features can gate themselves
        // without an extra /myinfoview round-trip.
        //
        // نحفظ empcode لاستخدامه في Settings (مثلاً عرض زر admin) بدون نداء إضافي.
        await _storage.write(
            key: 'empcode', value: _employeeIdController.text);
        // هل هذا المستخدم مدير أيضاً؟
        final isManager = data['is_manager'] == true;
        await _storage.write(key: 'is_manager', value: isManager ? 'true' : 'false');
        // current_view = أي واجهة نعرض حالياً (user/mgr) — يحدّد أي tokens نستعمل.
        await _storage.write(key: 'current_view', value: 'user');
        // Manager-scope tokens, if backend returns them. Used by dio_client
        // when current_view == 'mgr' so /mgr/* endpoints get the right scope.
        //
        // إذا المستخدم مدير، الـ backend يُرسل tokens إضافية لنطاق المدير.
        // نخزّنها كي يستطيع DioClient اختيارها لاحقاً.
        if (isManager && data['mgr_access_token'] != null) {
          await _storage.write(
              key: 'mgr_access_token', value: data['mgr_access_token']);
          await _storage.write(
              key: 'mgr_refresh_token', value: data['mgr_refresh_token']);
        }
        // كل شيء محفوظ — انتقل لـ /home واستبدل شاشة الدخول (لا يستطيع العودة لها).
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        logD('login /verify-user failed: $code body=$data');
        _snack(_authErrorFor(code, data, isOtpStep: true));
      }
    } on DioException catch (e) {
      logD('login /verify-user dio exception: ${e.message} body=${e.response?.data}');
      _snack(parseDioError(e, isArabic: isArabic(context)));
    } catch (e) {
      logD('login /verify-user unexpected: $e');
      _snack(AppLocalizations.of(context)!.wronginfo);
    }
  }

  /// Pick the friendliest message available for an auth failure.
  ///
  /// Priority: backend's short `message` / `error` field > a friendly
  /// status-code-specific fallback > generic. Avoids exposing status
  /// codes or technical strings to the user. [isOtpStep] flips a few
  /// fallbacks (e.g. a rejection during verify means "wrong OTP", not
  /// during /login).
  String _authErrorFor(int code, dynamic data, {required bool isOtpStep}) {
    if (data is Map) {
      final raw = data['message'] ?? data['error'] ?? data['detail'];
      final msg = raw?.toString().trim();
      if (msg != null &&
          msg.isNotEmpty &&
          msg.length <= 160 &&
          !msg.contains('\n')) {
        return msg;
      }
    }
    final ar = isArabic(context);
    switch (code) {
      case 400:
      case 422:
        return ar
            ? "البيانات المُدخلة غير صحيحة. تأكد منها وحاول مرة أخرى."
            : "The information you entered is not correct. Please check it and try again.";
      case 401:
        return isOtpStep
            ? (ar
                ? "رمز التحقق غير صحيح. تأكد من الرمز وحاول مرة أخرى."
                : "The verification code is not correct. Please try again.")
            : (ar
                ? "تعذّر تسجيل الدخول. تأكد من البيانات وحاول مرة أخرى."
                : "We couldn't sign you in. Please try again.");
      case 403:
        return ar
            ? "حسابك غير مفعّل حاليًا. يُرجى التواصل مع قسم الموارد البشرية."
            : "Your account is not active. Please contact the HR department.";
      case 404:
        return isOtpStep
            ? (ar
                ? "انتهت صلاحية رمز التحقق. اطلب رمزًا جديدًا."
                : "The verification code has expired. Please request a new one.")
            : (ar
                ? "رقم الموظف غير موجود. تأكد من الرقم أو تواصل مع الموارد البشرية."
                : "Employee number not found. Please check it or contact the HR department.");
      case 409:
      case 410:
        return ar
            ? "انتهت صلاحية رمز التحقق. اطلب رمزًا جديدًا."
            : "The verification code has expired. Please request a new one.";
      case 429:
        return ar
            ? "حاولت كثيرًا. يُرجى الانتظار قليلًا ثم المحاولة مرة أخرى."
            : "Too many attempts. Please wait a moment and try again.";
      default:
        return ar
            ? "تعذّر إتمام العملية. يُرجى المحاولة مرة أخرى."
            : "We couldn't complete the action. Please try again.";
    }
  }

  /// اختصار لإظهار snackbar في هذه الشاشة فقط.
  void _snack(String msg) => SnackbarHelpers.show(context, msg);

  /// تشغيل عدّاد 120 ثانية لإعادة الإرسال.
  /// كل ثانية ننقص _secondsRemaining، وعند الصفر نسمح بإعادة الإرسال.
  void startResendTimer() {
    setState(() {
      _canResend = false;
      _secondsRemaining = 120;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          _timer?.cancel();
        }
      });
    });
  }

  /// إعادة طلب OTP — تستدعي requestOtp فقط إذا انتهى المؤقت.
  Future<void> resendOtp() async {
    if (!_canResend) return;
    await requestOtp();
  }

  @override
  void dispose() {
    // تنظيف الموارد: إلغاء المؤقت وتحرير الـ controllers.
    _timer?.cancel();
    _employeeIdController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  /// عرض dialog إدخال OTP — يحوي:
  ///   - أيقونة قفل + نص "أدخل الرمز".
  ///   - حقل إدخال 6 أرقام (مع formatter لمنع الأحرف).
  ///   - زر إعادة إرسال (معطّل أثناء العد).
  ///   - زر تحقق (مُفعّل عند اكتمال 6 أرقام).
  void _showOtpModal() {
    _secondsRemaining = 120;
    _canResend = false;
    Timer? modalTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateModal) {
          modalTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
            setStateModal(() {
              if (_secondsRemaining > 0) {
                _secondsRemaining--;
              } else {
                _canResend = true;
                modalTimer?.cancel();
              }
            });
          });

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline_rounded,
                        color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    AppLocalizations.of(context)!.otp,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bi(context, ar: "6 أرقام", en: "6 digits"),
                    style: TextStyle(
                        color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '— — — — — —',
                    ),
                    onChanged: (value) {
                      setStateModal(() {
                        isfilled = value.length == 6;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: _canResend
                        ? () async {
                            await resendOtp();
                            setStateModal(() {
                              _secondsRemaining = 120;
                              _canResend = false;
                            });
                          }
                        : null,
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: _canResend
                          ? AppColors.primary
                          : AppColors.muted,
                    ),
                    label: Text(
                      _canResend
                          ? bi(context,
                              ar: "إعادة إرسال الرمز", en: "Resend OTP")
                          : bi(context,
                              ar:
                                  "إعادة الإرسال خلال ${_secondsRemaining} ثانية",
                              en:
                                  "Resend in ${_secondsRemaining}s"),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _canResend
                            ? AppColors.primary
                            : AppColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  PrimaryButton(
                    label: AppLocalizations.of(context)!.veriy,
                    icon: Icons.verified_user_outlined,
                    onPressed: isfilled
                        ? () async {
                            Navigator.pop(context);
                            modalTimer?.cancel();
                            await verifyOtp();
                          }
                        : null,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) => modalTimer?.cancel());
  }

  @override
  Widget build(BuildContext context) {
    String currentLang = Localizations.localeOf(context).languageCode;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              children: [
                // Language toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Material(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                        onTap: () {
                          var newLocale =
                              currentLang == 'ar' ? 'en' : 'ar';
                          _storage.write(key: "locale", value: newLocale);
                          localeNotifier.value = Locale(newLocale);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.language,
                                  size: 16, color: AppColors.onSurface),
                              const SizedBox(width: 6),
                              Text(
                                currentLang == 'ar' ? 'English' : 'العربية',
                                style: TextStyle(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Image.asset("assets/shubra.png", height: 72),
                ),
                const SizedBox(height: 24),
                // Welcome text
                Text(
                  bi(context, ar: "مرحبًا بك", en: "Welcome back"),
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  bi(context,
                      ar: "سجّل دخولك للمتابعة",
                      en: "Sign in to continue"),
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                // Form card
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bi(context,
                              ar: "رقم الموظف", en: "Employee ID"),
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _employeeIdController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.empcode,
                            prefixIcon: const Icon(
                              Icons.badge_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty
                                  ? AppLocalizations.of(context)!
                                      .enterempcode
                                  : null,
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(
                          label: AppLocalizations.of(context)!.login,
                          icon: Icons.login_rounded,
                          loading: _loading,
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              requestOtp();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
