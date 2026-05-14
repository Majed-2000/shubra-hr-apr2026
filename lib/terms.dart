// ============================================================================
// ملف: terms.dart
// الغرض: صفحة "شروط الاستخدام" — نص قانوني يحدّد قواعد استخدام التطبيق.
// محتوى ثابت — لا اتصال بالـ backend.
// ============================================================================

import 'package:flutter/material.dart';

import 'theme.dart';
import 'widgets.dart';

/// Terms of Service — initial v1.0; legal can replace later.
///
/// صفحة شروط الاستخدام — نص ثابت يمكن لـ legal تعديله لاحقاً.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModernScaffold(
      title: bi(context, ar: "شروط الاستخدام", en: "Terms of Service"),
      subtitle: bi(context,
          ar: "الإصدار 1.0", en: "Version 1.0"),
      leadingIcon: Icons.description_outlined,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Block(
            title: bi(context, ar: "قبول الشروط", en: "Acceptance"),
            body: bi(context,
                ar:
                    "باستخدامك تطبيق شبرا للموارد البشرية فإنك توافق على هذه الشروط. إن لم توافق، يُرجى عدم استخدام التطبيق.",
                en:
                    "By using the Shubra HR app, you agree to these terms. If you do not agree, please stop using the app."),
          ),
          _Block(
            title: bi(context,
                ar: "الاستخدام المسموح", en: "Permitted use"),
            body: bi(context,
                ar:
                    "التطبيق مخصص لخدمات الموارد البشرية الذاتية للموظفين وللمديرين المعتمدين فقط: الإجازات، السلف، الحضور، الرواتب، والتفاعل مع فريق العمل.",
                en:
                    "The app is intended for HR self-service by employees and approved managers only: leaves, loans, attendance, payroll, and team interactions."),
          ),
          _Block(
            title: bi(context,
                ar: "التزامات المستخدم", en: "User obligations"),
            body: bi(context,
                ar:
                    "تلتزم بإدخال بيانات صحيحة، والحفاظ على سرية رمز الدخول، وعدم إساءة استخدام أي خدمة. أي نشاط احتيالي يعرض الحساب للإيقاف الفوري.",
                en:
                    "You agree to provide accurate data, keep your login code confidential, and refrain from misusing any feature. Fraudulent activity may result in immediate suspension."),
          ),
          _Block(
            title: bi(context,
                ar: "إنهاء الخدمة", en: "Termination"),
            body: bi(context,
                ar:
                    "ينتهي حقك في استخدام التطبيق تلقائيًا بانتهاء علاقة العمل مع شبرا. تحتفظ الشركة بحق إيقاف الوصول في أي وقت لأسباب أمنية أو إدارية.",
                en:
                    "Your right to use the app ends automatically when your employment with Shubra ends. The company reserves the right to revoke access at any time for security or administrative reasons."),
          ),
          _Block(
            title: bi(context,
                ar: "تحديث الشروط", en: "Updates"),
            body: bi(context,
                ar:
                    "قد تُحدَّث هذه الشروط دون إشعار مسبق. استمرارك في الاستخدام يعني موافقتك على النسخة الأحدث.",
                en:
                    "These terms may be updated without prior notice. Continued use implies acceptance of the latest version."),
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final String title;
  final String body;
  final bool isLast;
  const _Block({
    required this.title,
    required this.body,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 13.5,
                height: 1.65,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
