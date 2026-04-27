import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'main.dart';
import 'shared/utils/logger.dart';
import 'theme.dart';
import 'widgets.dart';

/// Manager dashboard. Mirrors [Home] but with manager-specific quick
/// actions (approve leaves, review custody, rate employees, broadcast
/// notifications).
class HomeMgr extends StatefulWidget {
  @override
  _HomeMgrState createState() => _HomeMgrState();
}

class _HomeMgrState extends State<HomeMgr> {
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final dioClient = DioClient().client;

  final _storage = const FlutterSecureStorage();
  String username = "";
  Map<String, dynamic> empinfo = {};

  late FirebaseMessaging messaging;

  Future<void> _initFCM() async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken != null) {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        uploadtoken(fcmToken!);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    readName();
    getInfo();
    _initFCM();
  }

  Future<void> uploadtoken(String _token) async {
    try {
      await dioClient.post('/mgr/uploadtoken', data: {'token': _token});
    } catch (e) {}
  }

  Future<void> readName() async {
    String? name = await _storage.read(key: "name");
    if (name != null) {
      setState(() {
        username = name;
      });
    }
  }

  Future<void> getInfo() async {
    try {
      final response = await dioClient.get('/mgr/myinfoview');
      if (response.statusCode == 201) {
        var data = response.data;
        setState(() {
          empinfo = data;
        });
      }
    } catch (e) {
      logD('Request failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentLang = Localizations.localeOf(context).languageCode;
    final t = AppLocalizations.of(context)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: getInfo,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                  child: _buildHeader(context, t, currentLang)),
              if (empinfo.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(t),
                )
              else ...[
                SliverToBoxAdapter(child: _buildBirthdayAndOccasions(t)),
                SliverToBoxAdapter(child: _buildQuickActions(t)),
                SliverToBoxAdapter(child: _buildInfoCard(t)),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 24 + MediaQuery.of(context).padding.bottom,
                  ),
                ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(context, t),
      ),
    );
  }

  // ─── Clean white header ─────────────────────────────────────
  Widget _buildHeader(
      BuildContext context, AppLocalizations t, String currentLang) {
    final padding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, padding + 12, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _chipButton(
                label: currentLang == 'ar' ? 'EN' : 'ع',
                onTap: () {
                  var newLocale = currentLang == 'ar' ? 'en' : 'ar';
                  _storage.write(key: "locale", value: newLocale);
                  localeNotifier.value = Locale(newLocale);
                },
              ),
              const Spacer(),
              Text(
                t.shubra,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              _iconBtn(
                Icons.swap_horiz_rounded,
                onTap: () async {
                  await _storage.write(key: 'current_view', value: 'user');
                  if (!mounted) return;
                  Navigator.pushReplacementNamed(context, "/home");
                },
              ),
              const SizedBox(width: 8),
              _iconBtn(
                Icons.notifications_outlined,
                onTap: () =>
                    Navigator.pushNamed(context, "/notificationsmgr"),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          t.welcome,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text(
                            bi(context, ar: "مدير", en: "MGR"),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _iconBtn(
                Icons.person_outline_rounded,
                onTap: () => Navigator.pushNamed(context, "/profile"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipButton({required String label, required VoidCallback onTap}) {
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: AppColors.surfaceAlt,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: AppColors.onSurface, size: 20),
        ),
      ),
    );
  }

  // ��── Birthday & occasions ───────────────────────────────────
  Widget _buildBirthdayAndOccasions(AppLocalizations t) {
    final hasBd = empinfo['bd'] == true;
    final hasOcc =
        empinfo['occ'] != null && (empinfo['occ'] as List).isNotEmpty;
    if (!hasBd && !hasOcc) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          if (hasBd)
            GlassCard(
              padding: const EdgeInsets.all(14),
              color: const Color(0xFFF0FAF8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(Icons.cake_outlined,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.hbd + " " + (empinfo['info']['emnme1'] ?? ''),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Image.asset(
                      "assets/hbd.jpg",
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
            ),
          if (hasBd && hasOcc) const SizedBox(height: 10),
          if (hasOcc)
            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Text(
                    empinfo['occ'][0]['msg'].toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Image(
                      image: NetworkImage(
                        'https://cloud.shubra.net/uploads/' +
                            empinfo['occ'][0]['attach'].toString(),
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Quick actions ──────────────────────────────────────────
  Widget _buildQuickActions(AppLocalizations t) {
    final actions = [
      _QuickAction(Icons.event_note_outlined, t.leaverequests,
          AppColors.primary, "/leaveRequestsMgr"),
      _QuickAction(Icons.dashboard_customize_outlined, t.custody,
          AppColors.warning, "/custodyMgr"),
      _QuickAction(Icons.star_rate_rounded, t.rate,
          AppColors.secondary, "/emprateMgr"),
      _QuickAction(Icons.notification_add_outlined, t.addnoti,
          AppColors.primary, "/addnoti"),
      _QuickAction(Icons.notifications_outlined, t.notifications,
          AppColors.secondary, "/notificationsmgr"),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
              title: bi(context,
                  ar: "إجرا��ات المدير", en: "Manager Actions"),
              icon: Icons.bolt_rounded),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (_, i) {
              final a = actions[i];
              return GlassCard(
                padding: const EdgeInsets.all(10),
                onTap: () => Navigator.pushNamed(context, a.route),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: a.color.withOpacity(0.10),
                        borderRadius:
                            BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(a.icon, color: a.color, size: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Info card ──────────────────────────────────────────────
  Widget _buildInfoCard(AppLocalizations t) {
    final info = empinfo['info'] ?? {};
    final mgr = empinfo['mgr'] ?? {};
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
              title: t.myinfo, icon: Icons.person_outline_rounded),
          const SizedBox(height: 10),
          GlassCard(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Column(
              children: [
                InfoTile(
                    icon: Icons.person_outline,
                    label: t.name,
                    value: '${info['emnme1'] ?? ''}'),
                const Divider(height: 1, color: AppColors.border),
                InfoTile(
                    icon: Icons.badge_outlined,
                    label: t.empcode,
                    value: '${info['emcd'] ?? ''}'),
                const Divider(height: 1, color: AppColors.border),
                InfoTile(
                    icon: Icons.phone_iphone_rounded,
                    label: t.mobile,
                    value: '${info['empmob'] ?? ''}'),
                const Divider(height: 1, color: AppColors.border),
                InfoTile(
                    icon: Icons.supervisor_account_outlined,
                    label: t.manager,
                    value: '${mgr['emnme1'] ?? ''}'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GlassCard(
            onTap: () => Navigator.pushNamed(context, "/profile"),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.lock_outline_rounded,
                      color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bi(context,
                            ar: "التفاصيل المالية",
                            en: "Financial details"),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bi(context,
                            ar:
                                "الراتب والحساب البنكي والآيبان — مخفية للخصوصية",
                            en: "Salary, bank & IBAN — hidden for privacy"),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty state ────────────────────────────────────────────
  Widget _buildEmptyState(AppLocalizations t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 14),
            Text(t.internet,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ─── Bottom navigation ──────────────────────────────────────
  Widget _buildBottomNav(BuildContext context, AppLocalizations t) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                icon: Icons.home_rounded,
                label: bi(context, ar: "الرئيسية", en: "Home"),
                isActive: true,
                onTap: () {},
              ),
              _navItem(
                icon: Icons.event_note_outlined,
                label: t.leaverequests,
                onTap: () =>
                    Navigator.pushNamed(context, "/leaveRequestsMgr"),
              ),
              _navItem(
                icon: Icons.notifications_outlined,
                label: t.notifications,
                onTap: () =>
                    Navigator.pushNamed(context, "/notificationsmgr"),
              ),
              _navItem(
                icon: Icons.settings_outlined,
                label: bi(context, ar: "الإعدادات", en: "Settings"),
                onTap: () =>
                    Navigator.pushNamed(context, "/settings"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    final color = isActive ? AppColors.primary : AppColors.muted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  const _QuickAction(this.icon, this.label, this.color, this.route);
}
