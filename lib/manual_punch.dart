// ============================================================================
// ملف: manual_punch.dart
// الغرض: ديالوق مخفي لتسجيل بصمة (حضور/انصراف) يدوياً لأي موظف.
// الوصول: ضغطة مطوّلة على بطاقة "سجل الحضور" — فقط للـ empcode 10021.
// API: POST /manualPunch  body: { empcode, trns_type } — trns_type: 0=حضور, 1=انصراف.
// ملاحظة: الـ backend هو الذي يفرض القيد على 10021 (403 لأي شخص آخر).
//          الـ client-side check موجود فقط لإخفاء الديالوق كـ UX.
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'shared/utils/dio_errors.dart';
import 'shared/utils/logger.dart';
import 'shared/utils/snackbar.dart';
import 'theme.dart';
import 'widgets.dart';

/// يفتح ديالوق تسجيل بصمة يدوية — للاستخدام الإداري فقط.
Future<void> showManualPunchDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _ManualPunchDialog(),
  );
}

class _ManualPunchDialog extends StatefulWidget {
  const _ManualPunchDialog();

  @override
  State<_ManualPunchDialog> createState() => _ManualPunchDialogState();
}

class _ManualPunchDialogState extends State<_ManualPunchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _empcode = TextEditingController();
  final _dio = DioClient().client;

  // null = ولا واحد قيد التشغيل، '0' = حضور، '1' = انصراف.
  String? _busy;

  @override
  void dispose() {
    _empcode.dispose();
    super.dispose();
  }

  /// trns_type: '0' = حضور، '1' = انصراف (يتطابق مع منطق getAttendance).
  Future<void> _submit(String trnsType) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = trnsType);
    final t = AppLocalizations.of(context)!;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    try {
      final response = await _dio.post(
        '/manualPunch',
        data: {
          'empcode': _empcode.text.trim(),
          'trns_type': trnsType,
        },
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      final code = response.statusCode ?? 0;
      final body = response.data;
      final ok = code >= 200 &&
          code < 300 &&
          body is Map &&
          (body['status'] == 'success' || body['success'] == 'success');
      if (!mounted) return;
      if (ok) {
        SnackbarHelpers.showSuccess(context, t.manualPunchSuccess);
        Navigator.of(context).pop();
      } else {
        final msg = (body is Map ? body['message']?.toString() : null) ??
            (arabic
                ? 'رمز الخطأ: $code'
                : 'Status: $code');
        logD('manualPunch failed: code=$code body=$body');
        SnackbarHelpers.showError(context, '${t.manualPunchFailed}: $msg');
      }
    } on DioException catch (e) {
      if (!mounted) return;
      SnackbarHelpers.showError(
          context, parseDioError(e, isArabic: arabic));
    } catch (e) {
      logD('manualPunch exception: $e');
      if (!mounted) return;
      SnackbarHelpers.showError(context, t.manualPunchFailed);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final loading = _busy != null;
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.fingerprint_rounded,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.manualPunchTitle,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LabeledField(
                label: t.manualPunchEmpcode,
                controller: _empcode,
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                enabled: !loading,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? t.enterempcode : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _PunchButton(
                      label: t.manualPunchCheckIn,
                      icon: Icons.login_rounded,
                      color: AppColors.success,
                      loading: _busy == '0',
                      onPressed: loading ? null : () => _submit('0'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PunchButton(
                      label: t.manualPunchCheckOut,
                      icon: Icons.logout_rounded,
                      color: AppColors.danger,
                      loading: _busy == '1',
                      onPressed: loading ? null : () => _submit('1'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: loading ? null : () => Navigator.of(context).pop(),
                child: Text(
                  t.cancel,
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// زر بصمة بلون مخصّص (أخضر للحضور، أحمر للانصراف).
/// مشابه لـ PrimaryButton لكن يقبل لوناً مخصصاً.
class _PunchButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback? onPressed;

  const _PunchButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: enabled ? onPressed : null,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: enabled ? color : color.withOpacity(0.4),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
