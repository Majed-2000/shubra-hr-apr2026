import 'dart:async';
import 'package:dio/dio.dart' show Options;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'DioClient.dart';
import 'l10n/app_localizations.dart';
import 'main.dart';
import 'theme.dart';
import 'widgets.dart';

class LoginMgr extends StatefulWidget {
  @override
  _LoginMgrState createState() => _LoginMgrState();
}

class _LoginMgrState extends State<LoginMgr> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final dioClient = DioClient().client;

  bool _canResend = false;
  bool _loading = false;
  bool _otpFilled = false;
  int _secondsRemaining = 120;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    var token = await _storage.read(key: "access_token");
    if (token != null) {
      Navigator.pushReplacementNamed(context, "/homeMgr");
    }
  }

  Future<void> requestOtp() async {
    setState(() => _loading = true);
    try {
      final response = await dioClient.post(
        '/mgr/login',
        data: {'empcode': _employeeIdController.text},
      );
      var data = response.data;
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
        '/verify-mgr',
        data: {
          'empcode': _employeeIdController.text,
          'otp': _otpController.text,
        },
        options: Options(validateStatus: (status) => status! < 500),
      );
      final data = response.data;
      if (data['status'] == 'success') {
        await _storage.write(key: 'access_token', value: data['access_token']);
        await _storage.write(key: 'refresh_token', value: data['refresh_token']);
        await _storage.write(key: 'type', value: "mgr");
        await _storage.write(key: 'name', value: data['mgr']['name']);
        Navigator.pushReplacementNamed(context, '/homeMgr');
      } else if (response.statusCode == 409) {
        _snack("OTP is invalid, expired, or already used");
      } else {
        _snack(AppLocalizations.of(context)!.wronginfo);
      }
    } catch (e) {
      _snack("Something went wrong, try again later.");
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

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
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.pop,
                    ),
                    child: const Icon(Icons.lock_outline_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    AppLocalizations.of(context)!.otp,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '— — — — — —',
                    ),
                    onChanged: (v) {
                      setStateModal(() => _otpFilled = v.length == 6);
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
                    icon: Icon(Icons.refresh_rounded,
                        size: 18,
                        color: _canResend
                            ? AppColors.primary
                            : AppColors.muted),
                    label: Text(
                      _canResend
                          ? bi(context,
                              ar: "إعادة إرسال الرمز", en: "Resend OTP")
                          : bi(context,
                              ar:
                                  "إعادة الإرسال خلال ${_secondsRemaining} ثانية",
                              en: "Resend in ${_secondsRemaining}s"),
                      style: TextStyle(
                        fontSize: 13.5,
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
                    onPressed: _otpFilled
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: size.height * 0.45,
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const Spacer(),
                      Material(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(30),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () {
                            var newLocale =
                                currentLang == 'ar' ? 'en' : 'ar';
                            _storage.write(key: "locale", value: newLocale);
                            localeNotifier.value = Locale(newLocale);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.language,
                                    size: 17, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  currentLang == 'ar' ? 'English' : 'العربية',
                                  style: const TextStyle(
                                    color: Colors.white,
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
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.asset("assets/shubra.png", height: 88),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    bi(context, ar: "بوابة المدير", en: "Manager Portal"),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bi(context,
                        ar: "سجّل الدخول برقم المدير",
                        en: "Sign in with your manager ID"),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 34),
                  GlassCard(
                    padding: const EdgeInsets.all(22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bi(context,
                                ar: "رقم المدير", en: "Manager ID"),
                            style: const TextStyle(
                              color: AppColors.onSurface,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _employeeIdController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!.empcode,
                              prefixIcon: const Icon(
                                Icons.admin_panel_settings_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty
                                    ? AppLocalizations.of(context)!
                                        .enterempcode
                                    : null,
                          ),
                          const SizedBox(height: 22),
                          PrimaryButton(
                            label: AppLocalizations.of(context)!.signinmgr,
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
        ],
      ),
    );
  }
}
