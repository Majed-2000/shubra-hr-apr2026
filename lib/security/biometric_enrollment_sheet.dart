// ============================================================================
// File: security/biometric_enrollment_sheet.dart
// Purpose: One-time bottom sheet shown right after the first successful OTP
//          login on a fresh device, offering to enable Face ID for next login.
// ============================================================================

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';
import 'biometric_service.dart';

class BiometricEnrollmentSheet {
  /// Show the sheet if biometric is available and the user hasn't already
  /// dismissed it (or enabled biometric login).
  static Future<void> maybeShow(BuildContext context) async {
    if (await BiometricService.isLoginEnabled) return;
    if (await BiometricService.wasNudgeDismissed) return;
    final status = await BiometricService.status();
    if (status != BiometricStatus.available) return;
    if (!context.mounted) return;
    await _show(context);
  }

  static Future<void> _show(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.fingerprint_rounded,
                  size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              bi(ctx,
                  ar: 'سجّل دخولك بـ Face ID المرة القادمة؟',
                  en: 'Sign in with Face ID next time?'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              bi(ctx,
                  ar: 'دخول أسرع بدون انتظار رمز التحقق عبر SMS',
                  en: 'Faster sign-in without waiting for the SMS OTP'),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13.5, height: 1.5),
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: bi(ctx, ar: 'تفعيل', en: 'Enable'),
              icon: Icons.check_rounded,
              onPressed: () async {
                final res = await BiometricService.authenticate(
                  reason: bi(ctx,
                      ar: 'فعّل تسجيل الدخول بالبصمة',
                      en: 'Enable biometric sign-in'),
                );
                if (res == BiometricResult.success) {
                  await BiometricService.setLoginEnabled(true);
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                await BiometricService.markNudgeDismissed();
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: Text(
                bi(ctx, ar: 'ليس الآن', en: 'Not now'),
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
