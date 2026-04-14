import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shubraepp/main.dart';
import 'DioClient.dart';
import 'l10n/app_localizations.dart';
import 'theme.dart';
import 'widgets.dart';

class Login extends StatefulWidget {
  @override
  _Login createState() => _Login();
}

class _Login extends State<Login> {
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
        await _storage.write(key: 'type', value: "user");
        await _storage.write(key: 'name', value: data['user']['name']);
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _snack(AppLocalizations.of(context)!.wronginfo);
      }
    } catch (e) {
      _snack(AppLocalizations.of(context)!.wronginfo);
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
                  const SizedBox(height: 6),
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: size.height * 0.45,
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _BubblePainter()),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _LangChip(
                        currentLang: currentLang,
                        onTap: () {
                          var newLocale =
                              currentLang == 'ar' ? 'en' : 'ar';
                          _storage.write(key: "locale", value: newLocale);
                          localeNotifier.value = Locale(newLocale);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
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
                  const Text(
                    "Welcome back",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Sign in to continue",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13.5,
                      letterSpacing: 0.2,
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
                                ar: "رقم الموظف",
                                en: "Employee ID"),
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
                          const SizedBox(height: 22),
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
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Expanded(
                                  child: Divider(color: AppColors.border)),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                child: Text(
                                    bi(context, ar: "أو", en: "or"),
                                    style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12)),
                              ),
                              const Expanded(
                                  child: Divider(color: AppColors.border)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/loginmgr');
                              },
                              icon: const Icon(
                                Icons.admin_panel_settings_outlined,
                                color: AppColors.secondary,
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.signinmgr,
                                style: const TextStyle(
                                    color: AppColors.secondary),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: AppColors.secondary, width: 1.4),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                              ),
                            ),
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

class _LangChip extends StatelessWidget {
  final String currentLang;
  final VoidCallback onTap;
  const _LangChip({required this.currentLang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language, size: 17, color: Colors.white),
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
    );
  }
}

class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()..color = Colors.white.withOpacity(0.08);
    final p2 = Paint()..color = Colors.white.withOpacity(0.05);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.08), 70, p1);
    canvas.drawCircle(
        Offset(size.width * 0.15, size.height * 0.32), 50, p2);
    canvas.drawCircle(
        Offset(size.width * 0.95, size.height * 0.38), 30, p2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
