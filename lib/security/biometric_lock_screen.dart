// ============================================================================
// File: security/biometric_lock_screen.dart
// Purpose: Full-screen lock prompt shown on cold start / foreground return
//          when feature 1 (biometric app lock) is enabled.
// Route arguments: target route to push on success (e.g. '/home', '/homeMgr').
// ============================================================================

import 'package:flutter/material.dart';

import '../shared/services/auth_service.dart';
import '../theme.dart';
import '../widgets.dart';
import 'biometric_service.dart';

class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  int _failed = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prompt());
  }

  String? get _target {
    final arg = ModalRoute.of(context)?.settings.arguments;
    return arg is String ? arg : null;
  }

  Future<void> _prompt() async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await BiometricService.authenticate(
      reason: 'افتح تطبيق شبرا',
    );
    if (!mounted) {
      setState(() => _busy = false);
      return;
    }
    switch (result) {
      case BiometricResult.success:
        Navigator.pushReplacementNamed(context, _target ?? '/home');
        return;
      case BiometricResult.enrollmentChanged:
      case BiometricResult.unavailable:
        await BiometricService.reset();
        if (!mounted) return;
        _goLogin();
        return;
      case BiometricResult.locked:
      case BiometricResult.failed:
        setState(() {
          _failed += 1;
          _busy = false;
        });
    }
  }

  Future<void> _goLogin() async {
    await AuthService.clearSession();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline_rounded,
                    size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: 22),
              Text(
                bi(context, ar: 'تطبيق شبرا مقفل', en: 'Shubra HR is locked'),
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _failed >= 3
                    ? bi(context,
                        ar: 'تعذرت المصادقة. استخدم كلمة المرور.',
                        en: 'Biometric failed. Use your password.')
                    : bi(context,
                        ar: 'سجّل دخولك باستخدام Face ID أو البصمة',
                        en: 'Authenticate with Face ID or fingerprint'),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 13.5),
              ),
              const Spacer(),
              PrimaryButton(
                label: bi(context, ar: 'محاولة المصادقة', en: 'Authenticate'),
                icon: Icons.fingerprint_rounded,
                loading: _busy,
                onPressed: _busy ? null : _prompt,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _busy ? null : _goLogin,
                child: Text(
                  bi(context,
                      ar: 'استخدم كلمة المرور بدلاً من ذلك',
                      en: 'Use password instead'),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
