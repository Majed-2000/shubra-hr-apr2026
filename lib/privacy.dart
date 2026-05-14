// ============================================================================
// ملف: privacy.dart
// الغرض: صفحة "الخصوصية والأمان" — معلومات قانونية + مسؤولية المستخدم.
// المحتوى ثابت (لا API) — أقسام نصية تشرح: OTP، حماية الحساب، التعامل مع البيانات.
// ============================================================================

import 'package:flutter/material.dart';

import 'theme.dart';
import 'widgets.dart';

/// Privacy & Security — OTP responsibility, account safety, data handling.
///
/// صفحة الخصوصية والأمان — نصوص قانونية ثابتة.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModernScaffold(
      title: bi(context, ar: "الخصوصية والأمان", en: "Privacy & Security"),
      subtitle: bi(context,
          ar: "مسؤوليتك ومسؤوليتنا", en: "Your responsibility and ours"),
      leadingIcon: Icons.shield_outlined,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionHeader(
            title: bi(context,
                ar: "مسؤولية رمز التحقق (OTP)",
                en: "OTP responsibility"),
            icon: Icons.vpn_key_outlined,
          ),
          const SizedBox(height: 10),
          GlassCard(
            child: Text(
              bi(context,
                  ar:
                      "الموظف يتحمل المسؤولية الكاملة عند مشاركة رمز التحقق (OTP) مع أي طرف آخر. مشاركة الرمز ممنوعة من الأساس، وفي حال حدوث ذلك، لن نتحمل أي مسؤولية عن سوء الاستخدام الذي قد ينتج عنها.",
                  en:
                      "The employee is fully responsible for sharing the OTP with any third party. Sharing the code is forbidden in the first place; if it does happen, we will not be liable for any misuse that follows."),
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 14,
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: bi(context, ar: "نصائح للأمان", en: "Account safety"),
            icon: Icons.verified_user_outlined,
          ),
          const SizedBox(height: 10),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bullet(
                  text: bi(context,
                      ar: "لا تشارك رمز الدخول مع أي شخص — حتى زملاء العمل.",
                      en:
                          "Never share your login code with anyone — including coworkers."),
                ),
                _Bullet(
                  text: bi(context,
                      ar: "سجّل الخروج عند استخدام جهاز مشترك.",
                      en: "Log out when using a shared device."),
                ),
                _Bullet(
                  text: bi(context,
                      ar:
                          "راجع قائمة الجلسات النشطة بانتظام، وأنهِ أي جهاز لا تعرفه.",
                      en:
                          "Review your active sessions regularly and end any device you don't recognize."),
                ),
                _Bullet(
                  text: bi(context,
                      ar: "أبلغ عن أي نشاط مشبوه فور ملاحظته.",
                      en: "Report any suspicious activity as soon as you spot it."),
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: bi(context,
                ar: "كيف نتعامل مع بياناتك", en: "How we handle your data"),
            icon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 10),
          GlassCard(
            child: Text(
              bi(context,
                  ar:
                      "بياناتك محفوظة على خوادم شبرا، وتُستخدم فقط لتشغيل خدمات الموارد البشرية (الإجازات، السلف، الحضور، الرواتب). لا نبيع بياناتك ولا نشاركها مع أي طرف خارجي.",
                  en:
                      "Your data is stored on Shubra servers and is used only to run our HR services (leaves, loans, attendance, payroll). We never sell or share it with any third party."),
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 14,
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              bi(context,
                  ar: "الإصدار 1.0 — قد يُحدَّث بدون إشعار مسبق.",
                  en: "v1.0 — may be updated without notice."),
              style: TextStyle(color: AppColors.muted, fontSize: 11.5),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  final bool isLast;
  const _Bullet({required this.text, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 7),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 13.5,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
