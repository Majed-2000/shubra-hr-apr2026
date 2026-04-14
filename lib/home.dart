import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shubraepp/main.dart';
import 'DioClient.dart';
import 'l10n/app_localizations.dart';
import 'theme.dart';
import 'widgets.dart';

class Home extends StatefulWidget {
  @override
  _Home createState() => _Home();
}

class _Home extends State<Home> {
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final dioClient = DioClient().client;

  final _storage = const FlutterSecureStorage();
  String username = "";

  late FirebaseMessaging messaging;
  Map<String, dynamic> empinfo = {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
      await dioClient.post('/uploadtoken', data: {'token': _token});
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
      final response = await dioClient.get('/myinfoview');
      if (response.statusCode == 201) {
        var data = response.data;
        setState(() {
          empinfo = data;
        });
      }
    } catch (e) {
      print('Request failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentLang = Localizations.localeOf(context).languageCode;
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(context, currentLang, t),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: getInfo,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, t)),
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
                  height: 32 + MediaQuery.of(context).padding.bottom,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations t) {
    final padding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(18, padding + 14, 18, 30),
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _roundIcon(
                Icons.menu_rounded,
                onTap: () => _scaffoldKey.currentState!.openDrawer(),
              ),
              const Spacer(),
              Text(
                t.shubra,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              _roundIcon(
                Icons.notifications_outlined,
                onTap: () =>
                    Navigator.pushNamed(context, "/notifications"),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.welcome,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roundIcon(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withOpacity(0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildBirthdayAndOccasions(AppLocalizations t) {
    final hasBd = empinfo['bd'] == true;
    final hasOcc =
        empinfo['occ'] != null && (empinfo['occ'] as List).isNotEmpty;
    if (!hasBd && !hasOcc) return const SizedBox(height: 18);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        children: [
          if (hasBd)
            GlassCard(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFFFF6F6),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(Icons.cake_outlined,
                            color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.hbd + " " + (empinfo['info']['emnme1'] ?? ''),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
          if (hasBd && hasOcc) const SizedBox(height: 12),
          if (hasOcc)
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    empinfo['occ'][0]['msg'].toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
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

  Widget _buildQuickActions(AppLocalizations t) {
    final actions = [
      _QuickAction(Icons.time_to_leave_outlined, t.requestleave,
          AppColors.primary, "/requestLeave"),
      _QuickAction(Icons.event_note_outlined, t.leaverequests,
          AppColors.secondary, "/leaveRequests"),
      _QuickAction(Icons.compare_arrows_rounded, t.moves,
          const Color(0xFF8B5CF6), "/moves"),
      _QuickAction(Icons.dashboard_customize_outlined, t.custody,
          const Color(0xFFF59E0B), "/custody"),
      _QuickAction(Icons.star_rate_rounded, t.rate,
          const Color(0xFF0EA5E9), "/emprate"),
      _QuickAction(Icons.report_problem_outlined, t.complaint,
          AppColors.danger, "/complaint"),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
              title: bi(context, ar: "إجراءات سريعة", en: "Quick Actions"),
              icon: Icons.bolt_rounded),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.95,
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
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: a.color.withOpacity(0.12),
                        borderRadius:
                            BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(a.icon, color: a.color, size: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
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

  Widget _buildInfoCard(AppLocalizations t) {
    final info = empinfo['info'] ?? {};
    final nation = empinfo['nation'];
    final mgr = empinfo['mgr2'];
    final fullName = (safeParseName(info['emnma1']) +
            " " +
            safeParseName(info['emnma2']) +
            " " +
            safeParseName(info['emnma3']))
        .trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
              title: t.myinfo, icon: Icons.person_outline_rounded),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 10),
            child: Column(
              children: [
                InfoTile(
                    icon: Icons.person_outline,
                    label: t.name,
                    value: fullName),
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
                    icon: Icons.flag_outlined,
                    label: t.nationality,
                    value:
                        '${(nation != null && nation.isNotEmpty) ? nation[0]['ntnma'] ?? '' : ''}'),
                const Divider(height: 1, color: AppColors.border),
                InfoTile(
                    icon: Icons.supervisor_account_outlined,
                    label: t.manager,
                    value: '${mgr != null ? mgr['mnnma'] ?? '' : ''}'),
                const Divider(height: 1, color: AppColors.border),
                InfoTile(
                    icon: Icons.beach_access_outlined,
                    label: t.vacbal,
                    value: '${empinfo['vacBal'] ?? ''}'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Private details shortcut — salary, bank, IBAN kept behind this
          GlassCard(
            onTap: () => Navigator.pushNamed(context, "/profile"),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.lock_outline_rounded,
                      color: AppColors.primary, size: 22),
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
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
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
                          fontSize: 12,
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

  Widget _buildEmptyState(AppLocalizations t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: AppColors.primary, size: 38),
            ),
            const SizedBox(height: 16),
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

  Drawer _buildDrawer(
      BuildContext context, String currentLang, AppLocalizations t) {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 16, 20, 24),
            decoration: const BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        username.isNotEmpty
                            ? username[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.welcome,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Image.asset("assets/shubra.png",
                    height: 36, alignment: Alignment.centerLeft),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              children: [
                _drawerItem(
                  icon: Icons.language,
                  title: currentLang == 'ar' ? 'English' : 'العربية',
                  onTap: () {
                    var newLocale = currentLang == 'ar' ? 'en' : 'ar';
                    _storage.write(key: "locale", value: newLocale);
                    localeNotifier.value = Locale(newLocale);
                    Navigator.pop(context);
                  },
                ),
                _drawerItem(
                    icon: Icons.person_outline_rounded,
                    title: t.myinfo,
                    onTap: () =>
                        Navigator.pushNamed(context, "/profile")),
                _drawerItem(
                    icon: Icons.update,
                    title: t.updateinfo,
                    onTap: () =>
                        Navigator.pushNamed(context, "/updateInfo")),
                _drawerItem(
                    icon: Icons.notifications_outlined,
                    title: t.notifications,
                    onTap: () =>
                        Navigator.pushNamed(context, "/notifications")),
                _drawerItem(
                    icon: Icons.settings_rounded,
                    title: bi(context, ar: "الإعدادات", en: "Settings"),
                    onTap: () =>
                        Navigator.pushNamed(context, "/settings")),
                _DrawerSection(label: bi(context, ar: "الطلبات", en: "Requests")),
                _drawerItem(
                    icon: Icons.time_to_leave,
                    title: t.requestleave,
                    onTap: () =>
                        Navigator.pushNamed(context, "/requestLeave")),
                _drawerItem(
                    icon: Icons.event_note,
                    title: t.leaverequests,
                    onTap: () =>
                        Navigator.pushNamed(context, "/leaveRequests")),
                _DrawerSection(label: bi(context, ar: "الشركة", en: "Company")),
                _drawerItem(
                    icon: Icons.report_problem_outlined,
                    title: t.complaint,
                    onTap: () =>
                        Navigator.pushNamed(context, "/complaint")),
                _drawerItem(
                    icon: Icons.compare_arrows_rounded,
                    title: t.moves,
                    onTap: () => Navigator.pushNamed(context, "/moves")),
                _drawerItem(
                    icon: Icons.dashboard_customize_outlined,
                    title: t.custody,
                    onTap: () =>
                        Navigator.pushNamed(context, "/custody")),
                _drawerItem(
                    icon: Icons.star_rate_rounded,
                    title: t.rate,
                    onTap: () =>
                        Navigator.pushNamed(context, "/emprate")),
                const SizedBox(height: 10),
                const Divider(color: AppColors.border),
                const SizedBox(height: 6),
                _drawerItem(
                  icon: Icons.logout_rounded,
                  title: t.logout,
                  danger: true,
                  onTap: () async {
                    final storage = FlutterSecureStorage();
                    await storage.deleteAll();
                    Navigator.pushReplacementNamed(context, "/logout");
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final color = danger ? AppColors.danger : AppColors.secondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: danger
                          ? AppColors.danger
                          : AppColors.onSurface,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 13, color: AppColors.muted.withOpacity(0.6)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int safeParse(dynamic value) {
    if (value == null) return 0;
    if (value.toString().isEmpty) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  String safeParseName(dynamic value) {
    if (value == null) return "";
    return value;
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  const _QuickAction(this.icon, this.label, this.color, this.route);
}

class _DrawerSection extends StatelessWidget {
  final String label;
  const _DrawerSection({required this.label, super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.muted,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
