// ============================================================================
// ملف: complaint.dart
// الغرض: نموذج بسيط لتقديم شكوى/مقترح إلى قسم الموارد البشرية.
// المحتوى: عنوان الشكوى + النص. POST /submitComplaint.
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'shared/utils/snackbar.dart';
import 'theme.dart';
import 'widgets.dart';

/// Lets the employee file a complaint with a title and free-form text.
///
/// شاشة تقديم شكوى — عنوان + نص حر، تُرسل لـ HR.
class Complaint extends StatefulWidget {
  @override
  _ComplaintState createState() => _ComplaintState();
}

class _ComplaintState extends State<Complaint> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _notice = TextEditingController();
  final dioClient = DioClient().client;
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _notice.dispose();
    super.dispose();
  }

  /// إرسال الشكوى عبر POST /submitComplaint.
  /// نستعمل FormData (وليس JSON) لأن الـ backend يتعامل مع multipart.
  Future<void> submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      FormData formData = FormData.fromMap({
        "title": _title.text,
        "notice": _notice.text,
      });
      final response =
          await dioClient.post('/submitComplaint', data: formData);
      if (response.statusCode == 201) {
        _title.clear();
        _notice.clear();
        _snack(AppLocalizations.of(context)!.sent);
      } else {
        _snack(AppLocalizations.of(context)!.notsent);
      }
    } catch (e) {
      _snack(AppLocalizations.of(context)!.notsent);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _snack(String msg) => SnackbarHelpers.show(context, msg);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ModernScaffold(
      title: t.compreg,
      subtitle: t.complaint,
      leadingIcon: Icons.report_problem_rounded,
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
                  maxLines: 5,
                  validator: (v) =>
                      v == null || v.isEmpty ? t.entercompdesc : null,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: t.send,
                  icon: Icons.send_rounded,
                  loading: _sending,
                  onPressed: submitComplaint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
