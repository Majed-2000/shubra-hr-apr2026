// ============================================================================
// ملف: new_account.dart
// الغرض: شاشة إنشاء حساب جديد للموظف.
// التدفق:
//   1) المستخدم يُدخل رقم الموظف + الإقامة + كلمة المرور.
//   2) POST /register → عند النجاح يستلم tokens مباشرة (بدون OTP).
//   3) نخزّن tokens ونحوّل إلى /home.
// متى يُستخدم: عند أول استخدام للتطبيق (موظف جديد لم يربط حسابه بعد).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'main.dart';
import 'shared/utils/snackbar.dart';
import 'theme.dart';
import 'widgets.dart';

/// Employee self-registration: empcode + IQAMA + password.
///
/// شاشة تسجيل ذاتي للموظف: empcode + إقامة + كلمة مرور.
class NewAccount extends StatefulWidget {
  @override
  _NewaccountState createState() => _NewaccountState();
}

class _NewaccountState extends State<NewAccount> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _iqama = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final dioClient = DioClient().client;
  final _storage = const FlutterSecureStorage();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    gettoken();
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _iqama.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  gettoken() async {
    var token = await _storage.read(key: "access_token");
    if (!mounted) return;
    if (token != null) {
      // pushReplacementNamed بدلاً من pushNamed كي لا يستطيع المستخدم العودة
      // إلى شاشة التسجيل عبر زر الرجوع.
      Navigator.pushReplacementNamed(context, "/home");
    }
  }

  void _snack(String m) => SnackbarHelpers.show(context, m);

  /// إرسال النموذج: تحقّق ثم POST /register.
  /// عند النجاح: نخزّن tokens وننتقل إلى /home.
  Future<void> _submit() async {
    // تحقق من النموذج (validator لكل حقل).
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      // POST /register مع بيانات التسجيل.
      final response = await dioClient.post('/register', data: {
        'empcode': _employeeIdController.text,
        'password': _passwordController.text,
        'iqama': _iqama.text,
      });
      var data = response.data;
      if (response.statusCode == 201) {
        if (data['error'] != null) {
          _snack(AppLocalizations.of(context)!.wronginfo);
        } else {
          await _storage.write(
              key: 'access_token', value: data['access_token']);
          await _storage.write(
              key: 'refresh_token', value: data['refresh_token']);
          await _storage.write(key: 'name', value: data['user']['name']);
          final isManager = data['is_manager'] == true;
          await _storage.write(
              key: 'is_manager', value: isManager ? 'true' : 'false');
          await _storage.write(key: 'current_view', value: 'user');
          // حفظ empcode (مثل login.dart) كي يعمل زر admin "Switch user" بدون نداء إضافي.
          await _storage.write(
              key: 'empcode', value: _employeeIdController.text);
          if (!mounted) return;
          // pushReplacementNamed يمنع الرجوع لشاشة التسجيل عبر زر الرجوع.
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (_) {
      _snack(AppLocalizations.of(context)!.failednewreg);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final currentLang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            children: [
              Row(
                children: [
                  Material(
                    color: AppColors.surfaceAlt,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: EdgeInsets.all(9),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.onSurface, size: 18),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                      onTap: () {
                        final newLocale =
                            currentLang == 'ar' ? 'en' : 'ar';
                        _storage.write(key: "locale", value: newLocale);
                        localeNotifier.value = Locale(newLocale);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.language,
                                size: 16, color: AppColors.onSurface),
                            const SizedBox(width: 6),
                            Text(
                              currentLang == 'ar' ? 'English' : 'العربية',
                              style: TextStyle(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Image.asset("assets/shubra.png", height: 64),
              ),
              const SizedBox(height: 16),
              Text(
                t.newaccountreg,
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
                  GlassCard(
                    padding: const EdgeInsets.all(22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          LabeledField(
                            label: t.empcode,
                            controller: _employeeIdController,
                            icon: Icons.badge_outlined,
                            hint: t.empcode,
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v == null || v.isEmpty
                                    ? t.enterempcode
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          LabeledField(
                            label: t.iqama,
                            controller: _iqama,
                            icon: Icons.credit_card_outlined,
                            hint: t.iqama,
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v == null || v.isEmpty
                                    ? t.enteriqama
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.password,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: t.password,
                                  prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      color: AppColors.primary,
                                      size: 20),
                                ),
                                validator: (v) =>
                                    v == null || v.isEmpty
                                        ? t.enterpassword
                                        : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          PrimaryButton(
                            label: t.newaccountreg,
                            icon: Icons.person_add_rounded,
                            loading: _sending,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
