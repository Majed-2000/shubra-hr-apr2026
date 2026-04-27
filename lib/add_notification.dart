import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'shared/utils/snackbar.dart';
import 'theme.dart';
import 'widgets.dart';

/// Manager-side composer for broadcasting an announcement to the team.
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

  Future<void> submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      FormData formData = FormData.fromMap({
        "title": _title.text,
        "desc": _notice.text,
      });
      final response =
          await dioClient.post('/sendnotification', data: formData);
      if (response.data['success'] == "success") {
        _title.clear();
        _notice.clear();
        _snack(AppLocalizations.of(context)!.sent);
      } else {
        _snack(AppLocalizations.of(context)!.notsent);
      }
    } catch (e) {
      _snack(AppLocalizations.of(context)!.notsent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
