import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'shared/utils/snackbar.dart';
import 'theme.dart';
import 'widgets.dart';

/// Form for updating the employee's contact email and mobile number.
class UpdateInfo extends StatefulWidget {
  @override
  _UpdateInfoState createState() => _UpdateInfoState();
}

class _UpdateInfoState extends State<UpdateInfo> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _mobile = TextEditingController();
  final dioClient = DioClient().client;
  XFile? attach;
  bool _sending = false;

  void loginUser() async {}

  @override
  void initState() {
    super.initState();
  }

  gettoken() async {
    final _storage = const FlutterSecureStorage();
    var token = await _storage.read(key: "access_token");
    if (token != null) {
      Navigator.pushNamed(context, "/home");
    }
  }

  void _snack(String msg) => SnackbarHelpers.show(context, msg);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      FormData formData = FormData.fromMap({
        "email": _email.text,
        "mobile": _mobile.text,
      });
      final response = await dioClient.post('/updateInfo', data: formData);
      if (response.statusCode == 201) {
        _email.clear();
        _mobile.clear();
        _snack(AppLocalizations.of(context)!.sent);
      }
    } catch (e) {
      _snack(AppLocalizations.of(context)!.nodata);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ModernScaffold(
      title: t.updateinfo,
      subtitle: bi(context,
          ar: "تحديث بيانات الاتصال", en: "Update your contact details"),
      leadingIcon: Icons.manage_accounts_rounded,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                LabeledField(
                  label: t.email,
                  controller: _email,
                  icon: Icons.email_outlined,
                  hint: t.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return t.enteremail;
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return t.enteremail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                LabeledField(
                  label: t.mobile,
                  controller: _mobile,
                  icon: Icons.phone_iphone_rounded,
                  hint: t.mobile,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) return t.entermobile;
                    if (!RegExp(r'^\+?\d{9,15}$').hasMatch(value)) {
                      return t.entermobile;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: t.send,
                  icon: Icons.save_rounded,
                  loading: _sending,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
