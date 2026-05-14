// ============================================================================
// ملف: new_account_mgr.dart
// الغرض: شاشة إنشاء حساب مدير (admin) عبر POST /mgr/register.
// الفرق عن new_account.dart: نطاق "manager" بدلاً من "user"؛ ينتقل إلى /homeMgr.
// متى يُستخدم: عند تسجيل مدير جديد في النظام.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'main.dart';
import 'shared/utils/snackbar.dart';
import 'theme.dart';
import 'widgets.dart';

/// Manager registration: email + IQAMA + password.
///
/// تسجيل مدير جديد عبر بريد + إقامة + كلمة مرور.
class NewAccountMGR extends StatefulWidget {
  @override
  State<NewAccountMGR> createState() => _NewAccountMGRState();
}

class _NewAccountMGRState extends State<NewAccountMGR> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _iqama = TextEditingController();
  final dioClient = DioClient().client;
  final _storage = const FlutterSecureStorage();
  bool _sending = false;

  @override
  void dispose() {
    _employeeIdController.dispose();
    _passwordController.dispose();
    _iqama.dispose();
    super.dispose();
  }

  void _snack(String m) => SnackbarHelpers.show(context, m);

  /// إرسال نموذج تسجيل المدير.
  /// POST /mgr/register → عند النجاح يستلم tokens بنطاق "manager"
  /// ويُحوَّل إلى /homeMgr (لوحة المدير، ليست لوحة الموظف).
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      // POST مع البيانات (email هنا هو رقم الموظف رغم اسمه — تاريخي).
      final response = await dioClient.post('/mgr/register', data: {
        'email': _employeeIdController.text,
        'iqama': _iqama.text,
        'password': _passwordController.text,
      });
      final data = response.data;
      if (response.statusCode == 201) {
        if (data['error'] != null) {
          _snack(AppLocalizations.of(context)!.wronginfo);
        } else {
          // تخزين tokens المدير في الـ scope الصحيح (mgr_*) — ليس access_token العام.
          // كتابة access_token/refresh_token مع type:"mgr" تُسبب force-logout
          // عند فتح التطبيق مرة أخرى (SplashScreen يكشف legacy type).
          await _storage.write(
              key: 'mgr_access_token', value: data['access_token']);
          await _storage.write(
              key: 'mgr_refresh_token', value: data['refresh_token']);
          // current_view يحدد أي tokens تُستخدم في DioClient.
          await _storage.write(key: 'current_view', value: 'mgr');
          await _storage.write(key: 'is_manager', value: 'true');
          await _storage.write(key: 'name', value: data['mgr']['name']);
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/homeMgr');
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
              const SizedBox(height: 4),
              Text(
                bi(context, ar: "إنشاء حساب مدير", en: "Manager registration"),
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
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
                            validator: (v) => v == null || v.isEmpty
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
                            validator: (v) => v == null || v.isEmpty
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
                                validator: (v) => v == null || v.isEmpty
                                    ? t.enterpassword
                                    : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          PrimaryButton(
                            label: t.register,
                            icon: Icons.admin_panel_settings_outlined,
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
