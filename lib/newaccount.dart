import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'DioClient.dart';
import 'l10n/app_localizations.dart';
import 'main.dart';
import 'theme.dart';
import 'widgets.dart';

class NewAccount extends StatefulWidget {
  @override
  _Newaccount createState() => _Newaccount();
}

class _Newaccount extends State<NewAccount> {
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

  gettoken() async {
    var token = await _storage.read(key: "access_token");
    if (token != null) {
      Navigator.pushNamed(context, "/home");
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
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
          await _storage.write(key: 'type', value: "user");
          await _storage.write(key: 'name', value: data['user']['name']);
          Navigator.pushNamed(context, '/home');
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: size.height * 0.4,
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const Spacer(),
                      Material(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(30),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () {
                            final newLocale =
                                currentLang == 'ar' ? 'en' : 'ar';
                            _storage.write(key: "locale", value: newLocale);
                            localeNotifier.value = Locale(newLocale);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.language,
                                    size: 17, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  currentLang == 'ar' ? 'English' : 'العربية',
                                  style: const TextStyle(
                                    color: Colors.white,
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
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.asset("assets/shubra.png", height: 80),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.newaccountreg,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 26),
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
                                style: const TextStyle(
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
        ],
      ),
    );
  }
}
