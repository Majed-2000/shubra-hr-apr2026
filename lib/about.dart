// ============================================================================
// ملف: about.dart
// الغرض: شاشة "حول التطبيق" — شعار الشركة، اسم التطبيق، رقم الإصدار، المطوّر.
// تستخدم package_info_plus لقراءة رقم الإصدار من pubspec.yaml تلقائياً.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'theme.dart';
import 'widgets.dart';

/// About screen — branding, app version, credits.
///
/// شاشة معلومات التطبيق: الشعار، الإصدار، فريق التطوير.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (!mounted) return;
      setState(() => _version = info.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ModernScaffold(
      title: bi(context, ar: "حول التطبيق", en: "About"),
      subtitle: bi(context, ar: "تطبيق شبرا للموارد", en: "Shubra HR"),
      leadingIcon: Icons.info_outline_rounded,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surface, // themed — flips with dark mode
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Image.asset("assets/shubra.png", height: 64),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    bi(context, ar: "شبرا", en: "Shubra HR"),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSurface,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      bi(context,
                          ar: "الإصدار $_version",
                          en: "Version $_version"),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    bi(context,
                        ar:
                            "تطبيق متكامل لخدمات الموارد البشرية في شبرا — لإدارة الإجازات ومتابعة الحضور وطلبات السلف والبقاء على تواصل مع فريقك.",
                        en:
                            "An all-in-one HR companion for Shubra employees and managers — manage leaves, track attendance, handle loans, and stay connected with your team."),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 13.5,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _AboutTile(
                    icon: Icons.public_rounded,
                    iconColor: AppColors.secondary,
                    title: bi(context,
                        ar: "الموقع الإلكتروني", en: "Website"),
                    subtitle: "cloud.shubra.net",
                    onTap: () =>
                        Navigator.pushNamed(context, "/website"),
                  ),
                  Divider(height: 1, color: AppColors.border),
                  _AboutTile(
                    icon: Icons.shield_outlined,
                    iconColor: AppColors.success,
                    title: bi(context,
                        ar: "سياسة الخصوصية", en: "Privacy Policy"),
                    subtitle: bi(context,
                        ar: "كيف نتعامل مع بياناتك",
                        en: "How we handle your data"),
                    onTap: () =>
                        Navigator.pushNamed(context, "/privacy"),
                  ),
                  Divider(height: 1, color: AppColors.border),
                  _AboutTile(
                    icon: Icons.description_outlined,
                    iconColor: AppColors.accent,
                    title: bi(context,
                        ar: "شروط الاستخدام",
                        en: "Terms of Service"),
                    subtitle: bi(context,
                        ar: "شروط استخدام التطبيق",
                        en: "App usage terms"),
                    onTap: () =>
                        Navigator.pushNamed(context, "/terms"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              bi(context,
                  ar:
                      "© 2026 جميع الحقوق محفوظة - شركة شبرا الطائف التجارية",
                  en:
                      "© 2026 All rights reserved - Shubra Al-Taif Trading Co."),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              bi(context,
                  ar: "إدارة التحول الرقمي",
                  en: "Digital Transformation Department"),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _AboutTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14.5)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            color: AppColors.muted, fontSize: 12.5)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: AppColors.muted.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
