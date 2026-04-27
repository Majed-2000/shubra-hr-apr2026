import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'l10n/app_localizations.dart';
import 'main.dart';
import 'theme.dart';
import 'widgets.dart';

/// Settings — language toggle, account management, logout.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = const FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final currentLang = Localizations.localeOf(context).languageCode;

    return ModernScaffold(
      title: bi(context, ar: "الإعدادات", en: "Settings"),
      subtitle: bi(context,
          ar: "التفضيلات والحساب", en: "Preferences & account"),
      leadingIcon: Icons.settings_rounded,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                const Divider(height: 1, color: AppColors.border),
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
                const Divider(height: 1, color: AppColors.border),
                _SettingTile(
                  icon: Icons.manage_accounts_rounded,
                  iconColor: AppColors.secondary,
                  title: t.updateinfo,
                  onTap: () =>
                      Navigator.pushNamed(context, "/updateInfo"),
                ),
                const Divider(height: 1, color: AppColors.border),
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
          const SizedBox(height: 10),
          ListSectionTitle(
              title: bi(context, ar: "حول", en: "About")),
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
                const Divider(height: 1, color: AppColors.border),
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
          const Center(
            child: Text(
              "v1.0.0",
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
                  style: const TextStyle(
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
