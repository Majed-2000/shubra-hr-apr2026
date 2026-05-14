// ============================================================================
// ملف: add_notification.dart
// الغرض: نموذج المدير لإنشاء إعلان جديد وبثّه لكل الفريق.
// الحقول: عنوان + نص الإعلان.
// API: POST /sendnotification (FormData) — يُرسل push notification لكل الموظفين.
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'shared/utils/logger.dart';
import 'shared/utils/snackbar.dart';
import 'theme.dart';
import 'widgets.dart';

/// Manager-side composer for broadcasting an announcement to the team.
///
/// نموذج إنشاء إعلان للمدير — عنوان + نص، يُبث لكل الفريق كـ push notification.
class AddNotification extends StatefulWidget {
  @override
  _AddNotificationState createState() => _AddNotificationState();
}

class _AddNotificationState extends State<AddNotification> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _notice = TextEditingController();
  final dioClient = DioClient().client;

  bool _isLoading = false;

  @override
  void dispose() {
    _title.dispose();
    _notice.dispose();
    super.dispose();
  }

  void _snack(String m) => SnackbarHelpers.show(context, m);

  /// إرسال الإعلان عبر POST /sendnotification.
  ///
  /// ملاحظة: في حال فشل الإرسال بـ HTTP 500 فالسبب على الأغلب backend
  /// (Laravel + Oracle Oci8) — مثل خطأ ORA-00942 (table or view does not
  /// exist). هذه أخطاء قاعدة بيانات لا يستطيع التطبيق إصلاحها — نعرض
  /// رسالة واضحة للمستخدم وتفاصيل تشخيصية في الـ console لمطوّر الباك-إند.
  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final formData = FormData.fromMap({
        'title': _title.text,
        'desc': _notice.text,
      });
      final response = await dioClient.post(
        '/sendnotification',
        data: formData,
        // < 600 يعني لا نرمي exception على 4xx/5xx — نقرأ body بدلاً.
        options: Options(validateStatus: (s) => s != null && s < 600),
      );
      final code = response.statusCode ?? 0;
      final body = response.data;
      final ok = code >= 200 &&
          code < 300 &&
          ((body is Map &&
                  (body['success'] == 'success' ||
                      body['status'] == 'success' ||
                      body['status'] == true ||
                      body['ok'] == true)) ||
              body is! Map);
      if (ok) {
        _title.clear();
        _notice.clear();
        if (mounted) _snack(AppLocalizations.of(context)!.sent);
      } else {
        // نلتقط الـ Oracle error code/message من Laravel HTML debug page
        // (الـ body طوله ~1MB لذا لا نطبعه كاملاً).
        final diagnostic = _extractBackendError(body);
        logD('addNotification failed: code=$code diagnostic=$diagnostic');
        if (mounted) {
          _snack('${AppLocalizations.of(context)!.notsent} '
              '($code${diagnostic.isNotEmpty ? ": $diagnostic" : ""})');
        }
      }
    } catch (e) {
      logD('addNotification exception: $e');
      if (mounted) _snack(AppLocalizations.of(context)!.notsent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// يستخرج أهم الأسطر من response body عند فشل الـ backend.
  /// Laravel debug HTML طويل جداً (1MB+) لكن السطور المهمة قليلة:
  /// اسم الـ Exception + رسالة الـ Oracle.
  String _extractBackendError(dynamic body) {
    if (body == null) return '';
    final s = body.toString();
    // أنماط نبحث عنها بالترتيب — أول مطابقة تفوز.
    final patterns = <RegExp>[
      RegExp(r'ORA-\d{5}[^\n<]{0,120}'),
      RegExp(r'Oci8Exception[^\n<]{0,120}'),
      RegExp(r'SQLSTATE\[[^\]]+\][^\n<]{0,120}'),
      RegExp(r'"message"\s*:\s*"([^"]{0,160})"'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(s);
      if (m != null) {
        // إن كانت مجموعة capture موجودة استعملها، وإلا النص الكامل.
        return (m.groupCount >= 1 ? m.group(1) : m.group(0)) ??
            m.group(0)!;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ModernScaffold(
      title: t.addnoti,
      subtitle: bi(context, ar: "إرسال إعلان", en: "Send an announcement"),
      leadingIcon: Icons.campaign_rounded,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LabeledField(
                  label: t.compadd,
                  controller: _title,
                  icon: Icons.title_rounded,
                  hint: t.compadd,
                  validator: (v) =>
                      v == null || v.isEmpty ? t.entercompadd : null,
                ),
                const SizedBox(height: 18),
                LabeledField(
                  label: t.description,
                  controller: _notice,
                  icon: Icons.description_outlined,
                  hint: t.description,
                  maxLines: 6,
                  validator: (v) =>
                      v == null || v.isEmpty ? t.entercompdesc : null,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: t.send,
                  icon: Icons.send_rounded,
                  loading: _isLoading,
                  onPressed: _sendNotification,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
