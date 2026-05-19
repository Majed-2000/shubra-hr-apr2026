// ============================================================================
// ملف: settings.dart
// الغرض: شاشة الإعدادات — تبديل اللغة، إدارة الحساب، تسجيل الخروج.
// ميزة خاصة (Admin): "تبديل المستخدم" (impersonation) — يظهر فقط للأكواد
// المُدرَجة في AppConfig.adminEmpcodes. الـ backend يفرض الصلاحية فعلياً.
// ============================================================================

import 'package:dio/dio.dart' show DioException, Options;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config/app_config.dart';
import 'config/gov_apps.dart';
import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'main.dart';
import 'security/biometric_service.dart';
import 'services/gov_app_launcher.dart';
import 'shared/utils/dio_errors.dart';
import 'shared/utils/logger.dart';
import 'shared/utils/snackbar.dart';
import 'theme.dart';
import 'widgets.dart';

/// Settings — language toggle, account management, logout.
///
/// Also exposes an admin-only "Switch user" entry (visible only when the
/// logged-in empcode is in [AppConfig.adminEmpcodes]). The actual
/// authorization is enforced server-side on `POST /admin/login-as`.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = const FlutterSecureStorage();
  final _dioClient = DioClient().client;

  String? _empcode;
  bool _isImpersonating = false;
  bool _switching = false;

  // ── biometric prefs (feature 1 + 2) ──
  bool _lockEnabled = false;
  bool _loginEnabled = false;
  int _lockTimeoutSec = 60;
  BiometricStatus _bioStatus = BiometricStatus.unavailable;

  @override
  void initState() {
    super.initState();
    _loadAdminState();
    _loadBiometricPrefs();
  }

  Future<void> _loadBiometricPrefs() async {
    final status = await BiometricService.status();
    final lock = await BiometricService.isLockEnabled;
    final login = await BiometricService.isLoginEnabled;
    final timeout = await BiometricService.lockTimeoutSeconds;
    if (!mounted) return;
    setState(() {
      _bioStatus = status;
      _lockEnabled = lock;
      _loginEnabled = login;
      _lockTimeoutSec = timeout;
    });
  }

  Future<void> _toggleLock(bool v) async {
    if (v) {
      final res = await BiometricService.authenticate(
        reason: bi(context,
            ar: 'فعّل قفل التطبيق',
            en: 'Enable app lock'),
      );
      if (res != BiometricResult.success) return;
    }
    await BiometricService.setLockEnabled(v);
    if (mounted) setState(() => _lockEnabled = v);
  }

  Future<void> _toggleLogin(bool v) async {
    if (v) {
      final res = await BiometricService.authenticate(
        reason: bi(context,
            ar: 'فعّل تسجيل الدخول بالبصمة',
            en: 'Enable biometric sign-in'),
      );
      if (res != BiometricResult.success) return;
    }
    await BiometricService.setLoginEnabled(v);
    if (mounted) setState(() => _loginEnabled = v);
  }

  Future<void> _pickTimeout() async {
    final options = const [
      (label: 'Immediately / فوراً', sec: 0),
      (label: '1 min / دقيقة', sec: 60),
      (label: '5 min / 5 دقائق', sec: 300),
      (label: '15 min / 15 دقيقة', sec: 900),
    ];
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final o in options)
              ListTile(
                title: Text(o.label),
                trailing: o.sec == _lockTimeoutSec
                    ? Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, o.sec),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await BiometricService.setLockTimeout(picked);
    if (mounted) setState(() => _lockTimeoutSec = picked);
  }

  /// Pulls the logged-in empcode + impersonation flag from secure storage so
  /// the admin tile can render conditionally. For sessions that pre-date the
  /// login-time empcode persistence, falls back to fetching `/myinfoview`.
  Future<void> _loadAdminState() async {
    var empcode = await _storage.read(key: 'empcode');
    final adminBackup = await _storage.read(key: 'admin_access_token');

    if (empcode == null) {
      try {
        final response = await _dioClient.get('/myinfoview');
        final data = response.data;
        if (data is Map && data['info'] is Map) {
          final fetched = data['info']['emcd']?.toString();
          if (fetched != null && fetched.isNotEmpty) {
            empcode = fetched;
            // Persist for next time so we don't pay the round-trip again.
            await _storage.write(key: 'empcode', value: fetched);
          }
        }
      } catch (e) {
        logD('settings empcode fallback fetch failed: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _empcode = empcode;
      _isImpersonating = adminBackup != null;
    });
  }

  bool get _isAdmin =>
      _empcode != null && AppConfig.adminEmpcodes.contains(_empcode);

  // ─── Admin: switch to another user ──────────────────────────────────

  Future<void> _promptSwitchUser() async {
    final controller = TextEditingController();
    final target = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.swap_horiz_rounded,
            color: AppColors.primary, size: 36),
        title: Text(bi(context, ar: "تبديل المستخدم", en: "Switch user")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              bi(context,
                  ar: "أدخل رقم الموظف الذي تريد الدخول كحسابه. سيتم "
                      "حفظ جلستك الحالية ويمكنك العودة إليها لاحقًا.",
                  en: "Enter the employee number you want to log in as. "
                      "Your current session is saved and can be restored."),
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText:
                    bi(context, ar: "رقم الموظف", en: "Employee code"),
                prefixIcon: const Icon(Icons.badge_outlined,
                    color: AppColors.primary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(bi(context, ar: "إلغاء", en: "Cancel")),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            child: Text(bi(context, ar: "تبديل", en: "Switch")),
          ),
        ],
      ),
    );

    if (target == null || target.isEmpty || !mounted) return;
    if (target == _empcode) {
      SnackbarHelpers.showInfo(
        context,
        bi(context,
            ar: "أنت بالفعل بهذا الحساب", en: "You are already this user"),
      );
      return;
    }
    await _doSwitchUser(target);
  }

  Future<void> _doSwitchUser(String targetEmpcode) async {
    setState(() => _switching = true);
    try {
      final response = await _dioClient.post(
        '/admin/login-as',
        data: {'empcode': targetEmpcode},
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      final data = response.data;
      final code = response.statusCode ?? 0;
      if (code == 200 && data is Map && data['status'] == 'success') {
        // Stash current (admin) tokens so we can restore later.
        await _backupCurrentTokensAsAdmin();
        // Replace the active session with the target user's tokens.
        await _writeNewSession(data, targetEmpcode);
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
            context, '/home', (route) => false);
        return;
      }
      logD('admin/login-as failed: $code body=$data');
      if (!mounted) return;
      _showFailure(_friendlyError(code, data), httpCode: code);
    } on DioException catch (e) {
      logD('admin/login-as dio: ${e.message} body=${e.response?.data}');
      if (!mounted) return;
      _showFailure(parseDioError(e, isArabic: isArabic(context)),
          httpCode: e.response?.statusCode);
    } catch (e) {
      logD('admin/login-as unexpected: $e');
      if (!mounted) return;
      _showFailure(AppLocalizations.of(context)!.nodata);
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  /// Save the currently-active tokens as admin_* so we can restore later.
  /// Only writes the backup if it doesn't already exist (so chained switches
  /// don't lose the original admin session).
  Future<void> _backupCurrentTokensAsAdmin() async {
    final existing = await _storage.read(key: 'admin_access_token');
    if (existing != null) return;
    final access = await _storage.read(key: 'access_token');
    final refresh = await _storage.read(key: 'refresh_token');
    final name = await _storage.read(key: 'name');
    final empcode = await _storage.read(key: 'empcode');
    final isManager = await _storage.read(key: 'is_manager');
    final mgrAccess = await _storage.read(key: 'mgr_access_token');
    final mgrRefresh = await _storage.read(key: 'mgr_refresh_token');
    if (access != null) {
      await _storage.write(key: 'admin_access_token', value: access);
    }
    if (refresh != null) {
      await _storage.write(key: 'admin_refresh_token', value: refresh);
    }
    if (name != null) await _storage.write(key: 'admin_name', value: name);
    if (empcode != null) {
      await _storage.write(key: 'admin_empcode', value: empcode);
    }
    if (isManager != null) {
      await _storage.write(key: 'admin_is_manager', value: isManager);
    }
    if (mgrAccess != null) {
      await _storage.write(key: 'admin_mgr_access_token', value: mgrAccess);
    }
    if (mgrRefresh != null) {
      await _storage.write(key: 'admin_mgr_refresh_token', value: mgrRefresh);
    }
  }

  /// Write the target user's tokens into the active session keys.
  Future<void> _writeNewSession(Map data, String empcode) async {
    await _storage.write(key: 'access_token', value: data['access_token']);
    await _storage.write(key: 'refresh_token', value: data['refresh_token']);
    final user = data['user'];
    if (user is Map && user['name'] != null) {
      await _storage.write(key: 'name', value: user['name'].toString());
    }
    await _storage.write(key: 'empcode', value: empcode);
    final isManager = data['is_manager'] == true;
    await _storage.write(
        key: 'is_manager', value: isManager ? 'true' : 'false');
    await _storage.write(key: 'current_view', value: 'user');
    if (isManager && data['mgr_access_token'] != null) {
      await _storage.write(
          key: 'mgr_access_token', value: data['mgr_access_token']);
      await _storage.write(
          key: 'mgr_refresh_token', value: data['mgr_refresh_token']);
    } else {
      await _storage.delete(key: 'mgr_access_token');
      await _storage.delete(key: 'mgr_refresh_token');
    }
  }

  // ─── Admin: restore original session ────────────────────────────────

  Future<void> _restoreAdmin() async {
    setState(() => _switching = true);
    try {
      final access = await _storage.read(key: 'admin_access_token');
      final refresh = await _storage.read(key: 'admin_refresh_token');
      if (access == null || refresh == null) {
        if (!mounted) return;
        _showFailure(bi(context,
            ar: "لا توجد جلسة إدارية محفوظة",
            en: "No saved admin session"));
        return;
      }
      await _storage.write(key: 'access_token', value: access);
      await _storage.write(key: 'refresh_token', value: refresh);
      final adminName = await _storage.read(key: 'admin_name');
      if (adminName != null) {
        await _storage.write(key: 'name', value: adminName);
      }
      final adminEmp = await _storage.read(key: 'admin_empcode');
      if (adminEmp != null) {
        await _storage.write(key: 'empcode', value: adminEmp);
      }
      final adminMgr = await _storage.read(key: 'admin_is_manager');
      if (adminMgr != null) {
        await _storage.write(key: 'is_manager', value: adminMgr);
      }
      final adminMgrAccess =
          await _storage.read(key: 'admin_mgr_access_token');
      final adminMgrRefresh =
          await _storage.read(key: 'admin_mgr_refresh_token');
      if (adminMgrAccess != null) {
        await _storage.write(
            key: 'mgr_access_token', value: adminMgrAccess);
      } else {
        await _storage.delete(key: 'mgr_access_token');
      }
      if (adminMgrRefresh != null) {
        await _storage.write(
            key: 'mgr_refresh_token', value: adminMgrRefresh);
      } else {
        await _storage.delete(key: 'mgr_refresh_token');
      }
      await _storage.write(key: 'current_view', value: 'user');

      // Wipe the backup; admin is back in their own session.
      for (final k in [
        'admin_access_token',
        'admin_refresh_token',
        'admin_name',
        'admin_empcode',
        'admin_is_manager',
        'admin_mgr_access_token',
        'admin_mgr_refresh_token',
      ]) {
        await _storage.delete(key: k);
      }

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      logD('restoreAdmin failed: $e');
      if (!mounted) return;
      _showFailure(AppLocalizations.of(context)!.nodata);
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  String _friendlyError(int code, dynamic data) {
    final isJsonError = data is Map;
    if (isJsonError) {
      final raw = data['message'] ?? data['error'] ?? data['detail'];
      final msg = raw?.toString().trim();
      if (msg != null &&
          msg.isNotEmpty &&
          msg.length <= 160 &&
          !msg.contains('\n')) {
        return msg;
      }
    }
    final ar = isArabic(context);
    switch (code) {
      case 403:
        return ar
            ? "ليست لديك صلاحية الدخول كمستخدم آخر."
            : "You're not authorized to log in as another user.";
      case 404:
        // 404 with a JSON error → backend says "employee not found".
        // 404 without JSON (HTML page) → the endpoint itself is missing.
        return isJsonError
            ? (ar
                ? "رقم الموظف غير موجود."
                : "Employee number not found.")
            : (ar
                ? "هذه العملية غير متوفرة على الخادم بعد. (لم يتم بناء /admin/login-as)"
                : "This action isn't available on the server yet. (/admin/login-as not implemented)");
      default:
        return ar
            ? "تعذّر تبديل المستخدم. حاول مرة أخرى."
            : "Couldn't switch user. Please try again.";
    }
  }

  Future<void> _showFailure(String body, {int? httpCode}) async {
    if (!mounted) return;
    final ar = isArabic(context);
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.error_outline_rounded,
            color: AppColors.danger, size: 36),
        title: Text(ar ? "تعذّر إتمام العملية" : "Couldn't complete"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(body),
            if (httpCode != null && httpCode != 0) ...[
              const SizedBox(height: 12),
              Text(
                '${ar ? "كود الخطأ" : "Error code"}: $httpCode',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ar ? "حسنًا" : "OK"),
          ),
        ],
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final currentLang = Localizations.localeOf(context).languageCode;
    final showAdminTile = _isAdmin && !_isImpersonating;
    final showRestoreTile = _isImpersonating;

    return ModernScaffold(
      title: bi(context, ar: "الإعدادات", en: "Settings"),
      subtitle: bi(context,
          ar: "التفضيلات والحساب", en: "Preferences & account"),
      leadingIcon: Icons.settings_rounded,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (showRestoreTile) ...[
            GlassCard(
              padding: EdgeInsets.zero,
              child: _SettingTile(
                icon: Icons.admin_panel_settings_rounded,
                iconColor: AppColors.warning,
                title: bi(context,
                    ar: "العودة إلى حسابك الإداري",
                    en: "Restore your admin session"),
                onTap: _switching ? () {} : _restoreAdmin,
              ),
            ),
            const SizedBox(height: 10),
          ],
          ListSectionTitle(title: bi(context, ar: "عام", en: "General")),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingTile(
                  icon: Icons.language_rounded,
                  iconColor: AppColors.secondary,
                  title: bi(context, ar: "اللغة", en: "Language"),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      currentLang == 'ar' ? 'العربية' : 'English',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  onTap: () async {
                    final newLocale = currentLang == 'ar' ? 'en' : 'ar';
                    await _storage.write(key: "locale", value: newLocale);
                    localeNotifier.value = Locale(newLocale);
                  },
                ),
                Divider(height: 1, color: AppColors.border),
                _SettingTile(
                  icon: Icons.notifications_outlined,
                  iconColor: AppColors.primary,
                  title: t.notifications,
                  onTap: () =>
                      Navigator.pushNamed(context, "/notifications"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ListSectionTitle(title: bi(context, ar: "الحساب", en: "Account")),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingTile(
                  icon: Icons.person_outline_rounded,
                  iconColor: AppColors.secondary,
                  title: t.myinfo,
                  onTap: () => Navigator.pushNamed(context, "/profile"),
                ),
                Divider(height: 1, color: AppColors.border),
                _SettingTile(
                  icon: Icons.manage_accounts_rounded,
                  iconColor: AppColors.secondary,
                  title: t.updateinfo,
                  onTap: () =>
                      Navigator.pushNamed(context, "/updateInfo"),
                ),
                Divider(height: 1, color: AppColors.border),
                _SettingTile(
                  icon: Icons.devices_other_rounded,
                  iconColor: AppColors.warning,
                  title: bi(context,
                      ar: "الجلسات النشطة", en: "Active Sessions"),
                  onTap: () =>
                      Navigator.pushNamed(context, "/sessions"),
                ),
              ],
            ),
          ),
          if (_bioStatus == BiometricStatus.available) ...[
            const SizedBox(height: 10),
            ListSectionTitle(title: bi(context, ar: "الأمان", en: "Security")),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary:
                        Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                    title: Text(bi(context,
                        ar: "قفل التطبيق بالبصمة", en: "App lock")),
                    subtitle: Text(bi(context,
                        ar: "اطلب بصمة عند فتح التطبيق",
                        en: "Require biometric to open the app")),
                    value: _lockEnabled,
                    activeColor: AppColors.primary,
                    onChanged: _toggleLock,
                  ),
                  if (_lockEnabled)
                    Divider(height: 1, color: AppColors.border),
                  if (_lockEnabled)
                    _SettingTile(
                      icon: Icons.timer_outlined,
                      iconColor: AppColors.secondary,
                      title: bi(context,
                          ar: "مدة القفل بعد الخمول",
                          en: "Auto-lock timeout"),
                      trailing: Text(
                        _lockTimeoutSec == 0
                            ? bi(context, ar: 'فوراً', en: 'Immediately')
                            : _lockTimeoutSec < 60
                                ? '${_lockTimeoutSec}s'
                                : '${_lockTimeoutSec ~/ 60} min',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: _pickTimeout,
                    ),
                  Divider(height: 1, color: AppColors.border),
                  SwitchListTile(
                    secondary:
                        Icon(Icons.fingerprint_rounded, color: AppColors.primary),
                    title: Text(bi(context,
                        ar: "تسجيل الدخول بالبصمة",
                        en: "Biometric sign-in")),
                    subtitle: Text(bi(context,
                        ar: "بدلاً من رمز SMS كل مرة",
                        en: "Skip the SMS OTP next time")),
                    value: _loginEnabled,
                    activeColor: AppColors.primary,
                    onChanged: _toggleLogin,
                  ),
                ],
              ),
            ),
          ],
          if (showAdminTile) ...[
            const SizedBox(height: 10),
            ListSectionTitle(
                title: bi(context, ar: "الإدارة", en: "Admin")),
            GlassCard(
              padding: EdgeInsets.zero,
              child: _SettingTile(
                icon: Icons.swap_horiz_rounded,
                iconColor: AppColors.primary,
                title: bi(context,
                    ar: "تبديل المستخدم", en: "Switch user"),
                onTap: _switching ? () {} : _promptSwitchUser,
              ),
            ),
          ],
          const SizedBox(height: 10),
          ListSectionTitle(
              title: bi(context,
                  ar: "الخدمات الحكومية", en: "Government Services")),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (int i = 0; i < govApps.length; i++) ...[
                  _SettingTile(
                    icon: govApps[i].icon,
                    iconColor: AppColors.primary,
                    title: bi(context,
                        ar: govApps[i].arName, en: govApps[i].enName),
                    trailing: Icon(Icons.open_in_new_rounded,
                        size: 18, color: AppColors.muted),
                    onTap: () async {
                      final ok = await GovAppLauncher.launch(govApps[i]);
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(bi(context,
                                ar: "تعذّر فتح التطبيق",
                                en: "Couldn't open the app")),
                          ),
                        );
                      }
                    },
                  ),
                  if (i < govApps.length - 1)
                    Divider(height: 1, color: AppColors.border),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          ListSectionTitle(title: bi(context, ar: "حول", en: "About")),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: AppColors.accent,
                  title: bi(context,
                      ar: "حول تطبيق شبرا", en: "About Shubra HR"),
                  onTap: () => Navigator.pushNamed(context, "/about"),
                ),
                Divider(height: 1, color: AppColors.border),
                _SettingTile(
                  icon: Icons.shield_outlined,
                  iconColor: AppColors.success,
                  title: bi(context,
                      ar: "الخصوصية والأمان",
                      en: "Privacy & Security"),
                  onTap: () =>
                      Navigator.pushNamed(context, "/privacy"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: t.logout,
            icon: Icons.logout_rounded,
            onPressed: () async {
              await _storage.deleteAll();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, "/logout");
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              "v2.0.0",
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: AppColors.muted.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
