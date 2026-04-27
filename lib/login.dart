import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shubraepp/main.dart';
import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'shared/utils/snackbar.dart';
import 'theme.dart';
import 'widgets.dart';

/// Employee OTP-based login screen with 120-second resend timer.
class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final dioClient = DioClient().client;

  bool isfilled = false;
  bool _canResend = false;
  bool _loading = false;
  int _secondsRemaining = 120;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    gettoken();
  }

  Future<void> gettoken() async {
    var token = await _storage.read(key: "access_token");
    if (token != null) {
      Navigator.pushReplacementNamed(context, "/home");
    }
  }

  Future<void> requestOtp() async {
    setState(() => _loading = true);
    try {
      final response = await dioClient.post(
        '/login',
        data: {'empcode': _employeeIdController.text},
      );
      final data = response.data;
      if (data['status'] == 'success') {
        _showOtpModal();
        startResendTimer();
      } else {
        _snack(AppLocalizations.of(context)!.wronginfo);
      }
    } catch (e) {
      _snack(AppLocalizations.of(context)!.wronginfo);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> verifyOtp() async {
    try {
      final response = await dioClient.post(
        '/verify-user',
        data: {
          'empcode': _employeeIdController.text,
          'otp': _otpController.text,
        },
      );
      final data = response.data;
      if (response.statusCode == 200 && data['status'] == 'success') {
        await _storage.write(key: 'access_token', value: data['access_token']);
        await _storage.write(key: 'refresh_token', value: data['refresh_token']);
        await _storage.write(key: 'name', value: data['user']['name']);
        final isManager = data['is_manager'] == true;
        await _storage.write(key: 'is_manager', value: isManager ? 'true' : 'false');
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _snack(AppLocalizations.of(context)!.wronginfo);
      }
    } catch (e) {
      _snack(AppLocalizations.of(context)!.wronginfo);
    }
  }

  void _snack(String msg) => SnackbarHelpers.show(context, msg);

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

  Future<void> resendOtp() async {
    if (!_canResend) return;
    await requestOtp();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _employeeIdController.dispose();
    _otpController.dispose();
    super.dispose();
  }

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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bi(context, ar: "٦ أرقام", en: "6 digits"),
                    style: const TextStyle(
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
                              const Icon(Icons.language,
                                  size: 16, color: AppColors.onSurface),
                              const SizedBox(width: 6),
                              Text(
                                currentLang == 'ar' ? 'English' : 'العربية',
                                style: const TextStyle(
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
                  style: const TextStyle(
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
                  style: const TextStyle(
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
                          style: const TextStyle(
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
