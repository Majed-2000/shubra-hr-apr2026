// ============================================================================
// ملف: home.dart
// الغرض: لوحة الموظف الرئيسية — أول شاشة بعد تسجيل الدخول.
// المحتوى:
//   - Header: ترحيب باسم المستخدم + صورته + زر بدّل للوحة المدير (إن كان).
//   - بطاقات الأرصدة: إجازات متبقية، قروض حالية، عُهد.
//   - Quick actions: اختصارات للشاشات المهمة (طلب إجازة، طلب قرض، ...).
//   - بطاقة معلومات: تفاصيل سريعة عن الموظف.
// API:
//   GET /myinfoview → معلومات الموظف الكاملة.
//   POST /uploadtoken → تسجيل FCM token مع الـ backend.
// ============================================================================

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shubraepp/main.dart';
import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'manual_punch.dart';
import 'prayer/prayer_widget.dart';
import 'shared/services/feature_flags.dart';
import 'shared/utils/logger.dart';
import 'shared/widgets/iqama_alert_banner.dart';
import 'theme.dart';
import 'widgets.dart';

/// Employee dashboard — header, balance/stats, quick actions, info card.
///
/// لوحة الموظف — أول شاشة بعد الدخول. تعرض رصيد الإجازات، القروض،
/// والاختصارات السريعة لكل الوظائف.
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final dioClient = DioClient().client;

  final _storage = const FlutterSecureStorage();
  String username = "";
  bool isManager = false;
  bool _loadFailed = false;
  // empcode الحالي للتحكم في ميزة إخفية (long-press على بطاقة الحضور).
  // null حتى ينتهي القراءة من secure storage.
  String? _empcode;

  late FirebaseMessaging messaging;
  Map<String, dynamic> empinfo = {};

  /// تهيئة Firebase Cloud Messaging:
  /// طلب الصلاحية، ثم الحصول على FCM token وتسجيله مع الـ backend.
  /// (هذا تكرار للمنطق في main.dart — مقصود ليضمن تحديث الـ token عند كل دخول).
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
    // 3 عمليات بالتوازي عند فتح الشاشة:
    readName();    // قراءة اسم المستخدم من storage (سريع، لا شبكة).
    getInfo();     // طلب بيانات الموظف من الـ backend.
    _initFCM();    // تهيئة الإشعارات.
  }

  /// إرسال FCM token إلى الـ backend ليستطيع إرسال إشعارات مستهدفة.
  /// نتجاهل أي error هنا (ليس حرجاً إذا فشل).
  Future<void> uploadtoken(String _token) async {
    try {
      await dioClient.post('/uploadtoken', data: {'token': _token});
    } catch (e) {}
  }

  /// قراءة اسم المستخدم وعَلَم isManager من secure storage.
  /// نملأ الـ UI بهما فوراً ثم نطلب البيانات الكاملة عبر getInfo().
  Future<void> readName() async {
    String? name = await _storage.read(key: "name");
    String? mgrFlag = await _storage.read(key: "is_manager");
    String? empcode = await _storage.read(key: "empcode");
    if (mounted) {
      setState(() {
        if (name != null) username = name;
        isManager = mgrFlag == 'true';
        _empcode = empcode;
      });
    }
  }

  /// جلب معلومات الموظف الكاملة من /myinfoview.
  /// يحدّث empinfo و is_manager.
  /// عند الفشل: _loadFailed = true لعرض حالة خطأ.
  Future<void> getInfo() async {
    try {
      final response = await dioClient.get('/myinfoview');
      if (response.statusCode == 201) {
        var data = response.data;
        // Backend may include is_manager in /myinfoview to keep the role
        // flag fresh between logins (handles grant/revoke without re-login).
        if (data is Map && data.containsKey('is_manager')) {
          final freshFlag = data['is_manager'] == true;
          await _storage.write(
              key: 'is_manager', value: freshFlag ? 'true' : 'false');
          if (mounted && freshFlag != isManager) {
            setState(() => isManager = freshFlag);
          }
        }
        if (!mounted) return;
        setState(() {
          empinfo = data;
          _loadFailed = false;
        });
      }
    } catch (e) {
      logD('Home /myinfoview failed: $e');
      if (!mounted) return;
      setState(() => _loadFailed = true);
    }
  }

  /// بناء الشاشة. تستخدم CustomScrollView مع slivers لكي يكون الـ header
  /// والقوائم متجانسة في نفس الـ scroll. يدعم سحب للتحديث (RefreshIndicator).
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
              SliverToBoxAdapter(child: _buildHeader(context, t, currentLang)),
              if (empinfo.isEmpty) ...[
                if (_loadFailed)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(t),
                  )
                else
                  SliverToBoxAdapter(child: _buildSkeleton(context)),
              ] else ...[
                SliverToBoxAdapter(child: _buildStatsRow(t)),
                SliverToBoxAdapter(
                  child: IqamaAlertBanner(
                    profileInfo: (empinfo['info'] is Map)
                        ? Map<String, dynamic>.from(empinfo['info'] as Map)
                        : null,
                  ),
                ),
                const SliverToBoxAdapter(
                    child: Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: PrayerWidget(),
                )),
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

  // ─── Clean white header ──────────────────────────────────────
  /// بناء الـ header الأبيض:
  ///   - سطر علوي: زر اللغة + شعار + زر "المدير" (إن كان) + جرس الإشعارات.
  ///   - سطر ترحيب: حرف الاسم في دائرة + "مرحباً [الاسم]".
  Widget _buildHeader(
      BuildContext context, AppLocalizations t, String currentLang) {
    final padding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, padding + 12, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Top bar: theme toggle — logo — notifications
          // ملاحظة: تبديل اللغة انتقل إلى شاشة Settings — هنا نضع زر
          // dark/light mode بدلاً منه لأنه أكثر استعمالاً.
          Row(
            children: [
              _iconBtn(
                // الأيقونة تعرض الوضع الذي سننتقل إليه عند الضغط:
                // currently light → show moon (tap to go dark).
                // currently dark → show sun (tap to go light).
                themeNotifier.value == ThemeMode.dark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_outlined,
                onTap: () async {
                  final newMode = themeNotifier.value == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
                  await _storage.write(
                      key: "theme_mode",
                      value: newMode == ThemeMode.dark ? "dark" : "light");
                  themeNotifier.value = newMode;
                },
              ),
              const Spacer(),
              Text(
                t.shubra,
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              if (isManager) ...[
                Material(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    onTap: () async {
                      await _storage.write(key: 'current_view', value: 'mgr');
                      if (!mounted) return;
                      Navigator.pushReplacementNamed(context, "/homeMgr");
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.admin_panel_settings_outlined,
                            size: 16,
                            color: AppColors.onSurface,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            bi(context, ar: "المدير", en: "Manager"),
                            style: TextStyle(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              _iconBtn(
                Icons.notifications_outlined,
                onTap: () =>
                    Navigator.pushNamed(context, "/notifications"),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Greeting row
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
                    Text(
                      t.welcome,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
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

  // ─── Stats row ──────────────────────────────────────────────
  /// صف بطاقات الإحصاءات الرئيسية (الإجازات، القروض، الراتب، الحضور).
  Widget _buildStatsRow(AppLocalizations t) {
    final info = empinfo['info'] ?? {};
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              icon: Icons.beach_access_outlined,
              label: t.vacbal,
              value: '${empinfo['vacBal'] ?? '0'}',
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              icon: Icons.badge_outlined,
              label: t.empcode,
              value: '${info['emcd'] ?? ''}',
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Birthday & occasions ───────────────────────────────────
  /// قسم أعياد الميلاد والمناسبات (تهاني للزملاء).
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
  /// شبكة الاختصارات السريعة (طلب إجازة، طلب قرض، الحضور، ...).
  /// كل اختصار = أيقونة + label + نداء Navigator.pushNamed.
  Widget _buildQuickActions(AppLocalizations t) {
    final actions = [
      _QuickAction(Icons.time_to_leave_outlined, t.requestleave,
          AppColors.primary, "/requestLeave"),
      _QuickAction(Icons.event_note_outlined, t.leaverequests,
          AppColors.secondary, "/leaveRequests"),
      _QuickAction(Icons.compare_arrows_rounded, t.moves,
          AppColors.primary, "/moves"),
      _QuickAction(Icons.fingerprint_rounded, t.attendanceLog,
          AppColors.success, "/attendance"),
      _QuickAction(Icons.payments_rounded, t.salaryDetails,
          AppColors.primary, "/salaryDetails"),
      _QuickAction(Icons.calculate_rounded,
          bi(context, ar: "مكافأة نهاية الخدمة", en: "End-of-Service"),
          AppColors.primary, "/eosCalculator"),
      if (FeatureFlags.documentVaultEnabled || FeatureFlags.useMockData)
        _QuickAction(Icons.folder_outlined,
            bi(context, ar: "مستنداتي", en: "My Documents"),
            AppColors.secondary, "/documents"),
      if (FeatureFlags.ticketsEnabled || FeatureFlags.useMockData)
        _QuickAction(Icons.support_agent_rounded,
            bi(context, ar: "الدعم والشكاوى", en: "Support & Tickets"),
            AppColors.danger, "/tickets"),
      _QuickAction(Icons.badge_rounded, t.digitalCard,
          AppColors.secondary, "/digitalCard"),
      _QuickAction(Icons.groups_rounded, t.colleagues,
          AppColors.primary, "/colleagues"),
      _QuickAction(Icons.dashboard_customize_outlined, t.custody,
          AppColors.warning, "/custody"),
      _QuickAction(Icons.star_rate_rounded, t.rate,
          AppColors.secondary, "/emprate"),
      _QuickAction(Icons.report_problem_outlined, t.complaint,
          AppColors.danger, "/complaint"),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
              title: bi(context, ar: "إجراءات سريعة", en: "Quick Actions"),
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
              // ميزة مخفية: ضغطة مطوّلة على بطاقة "سجل الحضور" تفتح
              // ديالوق تسجيل بصمة يدوياً — لكنها مفعّلة فقط لـ empcode 10021.
              // باقي المستخدمين: onLongPress = null → لا شيء يحدث (صامت تماماً).
              final isAttendanceTile = a.route == "/attendance";
              final canManualPunch =
                  isAttendanceTile && _empcode == "10021";
              return GlassCard(
                padding: const EdgeInsets.all(10),
                onTap: () => Navigator.pushNamed(context, a.route),
                onLongPress: canManualPunch
                    ? () => showManualPunchDialog(context)
                    : null,
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
                      style: TextStyle(
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
  /// بطاقة معلومات الموظف التفصيلية (الإدارة، الوظيفة، التاريخ، ...).
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
                    value: fullName),
                Divider(height: 1, color: AppColors.border),
                InfoTile(
                    icon: Icons.badge_outlined,
                    label: t.empcode,
                    value: '${info['emcd'] ?? ''}'),
                Divider(height: 1, color: AppColors.border),
                InfoTile(
                    icon: Icons.phone_iphone_rounded,
                    label: t.mobile,
                    value: '${info['empmob'] ?? ''}'),
                Divider(height: 1, color: AppColors.border),
                InfoTile(
                    icon: Icons.flag_outlined,
                    label: t.nationality,
                    value:
                        '${(nation != null && nation.isNotEmpty) ? nation[0]['ntnma'] ?? '' : ''}'),
                Divider(height: 1, color: AppColors.border),
                InfoTile(
                    icon: Icons.supervisor_account_outlined,
                    label: t.manager,
                    value: '${mgr != null ? mgr['mnnma'] ?? '' : ''}'),
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
                        style: TextStyle(
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
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty state ────────────────────────────────────────────
  /// واجهة الخطأ عند فشل تحميل البيانات — مع زر "إعادة المحاولة".
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
                style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ─── Skeleton placeholder (first-load shimmer) ──────────────
  /// واجهة "هيكل وهمي" أثناء التحميل الأولي (شبكية + بطاقات وهمية).
  Widget _buildSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row — 2 cards side by side
          Row(
            children: [
              Expanded(child: _skeletonStatsCard()),
              const SizedBox(width: 10),
              Expanded(child: _skeletonStatsCard()),
            ],
          ),
          const SizedBox(height: 18),
          // Section title placeholder
          Row(
            children: [
              const Skeleton(width: 22, height: 22, radius: 6),
              const SizedBox(width: 8),
              const Skeleton(width: 120, height: 16),
            ],
          ),
          const SizedBox(height: 12),
          // Quick-actions grid — 6 squares
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (_, __) => const Skeleton(radius: 16),
          ),
          const SizedBox(height: 18),
          // Info-card title + body
          Row(
            children: [
              const Skeleton(width: 22, height: 22, radius: 6),
              const SizedBox(width: 8),
              const Skeleton(width: 100, height: 16),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _skeletonInfoRow(),
                Divider(height: 1, color: AppColors.border),
                _skeletonInfoRow(),
                Divider(height: 1, color: AppColors.border),
                _skeletonInfoRow(),
                Divider(height: 1, color: AppColors.border),
                _skeletonInfoRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonStatsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Skeleton.box(size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Skeleton(width: 70, height: 11),
                SizedBox(height: 6),
                Skeleton(width: 90, height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonInfoRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Skeleton.box(size: 36, radius: 8),
          const SizedBox(width: 12),
          const Skeleton(width: 80, height: 13),
          const Spacer(),
          const Skeleton(width: 110, height: 13),
        ],
      ),
    );
  }

  // ─── Bottom navigation ──────────────────────────────────────
  /// شريط التنقل السفلي (Bottom Navigation): الرئيسية، البطاقة، الإعدادات، ...
  Widget _buildBottomNav(BuildContext context, AppLocalizations t) {
    return Container(
      decoration: BoxDecoration(
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
                    Navigator.pushNamed(context, "/leaveRequests"),
              ),
              _navItem(
                icon: Icons.notifications_outlined,
                label: t.notifications,
                onTap: () =>
                    Navigator.pushNamed(context, "/notifications"),
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
