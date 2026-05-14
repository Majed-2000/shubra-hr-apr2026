// ============================================================================
// ملف: sessions.dart
// الغرض: عرض الجلسات النشطة (الأجهزة المسجلة دخولها بحساب المستخدم).
// الفائدة: لو فقد المستخدم جهازاً أو اشتبه بدخول غير مصرّح → يمكنه تسجيل
//         خروج الأجهزة الأخرى عن بُعد.
// API:
//   GET  /sessions               → قائمة الجلسات.
//   POST /sessions/revoke-others → إنهاء كل الجلسات عدا الحالية.
// ============================================================================

import 'package:flutter/material.dart';

import 'dio_client.dart';
import 'shared/utils/dio_errors.dart';
import 'shared/utils/logger.dart';
import 'shared/utils/snackbar.dart';
import 'theme.dart';
import 'widgets.dart';

/// Active sessions screen.
///
/// Backend contract (see plan):
///   GET  /sessions             → { status, sessions: [ {id, device_name,
///                                  platform, ip, city, last_active,
///                                  is_current}, ... ] }
///   POST /sessions/revoke-others → { status: "success", revoked: int }
class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final dioClient = DioClient().client;

  bool _loading = true;
  bool _revoking = false;
  String? _error;
  List<_Session> _sessions = const [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  /// جلب قائمة الجلسات من الخادم.
  /// عند الفشل: نخزّن رسالة الخطأ في _error لعرضها كـ EmptyState.
  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await dioClient.get('/sessions');
      final data = res.data;
      final raw = (data is Map ? data['sessions'] : null) as List? ?? const [];
      final parsed =
          raw.whereType<Map>().map((m) => _Session.fromJson(m)).toList();
      if (!mounted) return;
      setState(() {
        _sessions = parsed;
        _loading = false;
      });
    } catch (e) {
      logD('Sessions fetch failed: $e');
      if (!mounted) return;
      setState(() {
        _error = parseDioError(e, isArabic: isArabic(context));
        _loading = false;
      });
    }
  }

  /// تسجيل خروج كل الأجهزة الأخرى (ما عدا الحالي).
  /// نطلب تأكيداً أولاً عبر AlertDialog قبل تنفيذ العملية.
  Future<void> _revokeOthers() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: Text(bi(context,
            ar: "تسجيل الخروج من الأجهزة الأخرى",
            en: "Sign out other devices")),
        content: Text(bi(context,
            ar:
                "سيتم إنهاء جميع الجلسات الأخرى. سيظل الجهاز الحالي مسجلًا. هل تريد المتابعة؟",
            en:
                "All other sessions will be ended. This device will stay signed in. Continue?")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(bi(context, ar: "إلغاء", en: "Cancel")),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              bi(context, ar: "تأكيد", en: "Confirm"),
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _revoking = true);
    try {
      final res = await dioClient.post('/sessions/revoke-others');
      final revoked = (res.data is Map ? res.data['revoked'] : null) ?? 0;
      if (!mounted) return;
      SnackbarHelpers.show(
        context,
        bi(context,
            ar: "تم إنهاء $revoked جلسة",
            en: "Ended $revoked sessions"),
      );
      await _fetch();
    } catch (e) {
      logD('Revoke-others failed: $e');
      if (!mounted) return;
      SnackbarHelpers.show(
        context,
        parseDioError(e, isArabic: isArabic(context)),
      );
    } finally {
      if (mounted) setState(() => _revoking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasOthers = _sessions.any((s) => !s.isCurrent);

    return ModernScaffold(
      title: bi(context, ar: "الجلسات النشطة", en: "Active Sessions"),
      subtitle: bi(context,
          ar: "الأجهزة المسجل دخولها لحسابك",
          en: "Devices signed in to your account"),
      leadingIcon: Icons.devices_other_rounded,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetch,
        child: _loading
            ? const SkeletonList(count: 4)
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    children: [
                      EmptyState(
                        icon: Icons.wifi_off_rounded,
                        title: bi(context,
                            ar: "تعذر تحميل الجلسات",
                            en: "Couldn't load sessions"),
                        subtitle: _error,
                      ),
                    ],
                  )
                : _sessions.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        children: [
                          EmptyState(
                            icon: Icons.devices_other_rounded,
                            title: bi(context,
                                ar: "لا توجد جلسات نشطة",
                                en: "No active sessions"),
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          for (final s in _sessions) ...[
                            _SessionCard(session: s),
                            const SizedBox(height: 10),
                          ],
                          const SizedBox(height: 8),
                          PrimaryButton(
                            label: bi(context,
                                ar: "تسجيل الخروج من الأجهزة الأخرى",
                                en: "Sign out other devices"),
                            icon: Icons.logout_rounded,
                            loading: _revoking,
                            onPressed: hasOthers ? _revokeOthers : null,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
      ),
    );
  }
}

/// بطاقة عرض جلسة واحدة: أيقونة الجهاز + اسم + IP + آخر نشاط.
/// إذا كانت الجلسة الحالية تُظهر شارة "الحالي".
class _SessionCard extends StatelessWidget {
  final _Session session;
  const _SessionCard({required this.session});

  /// أيقونة مناسبة حسب نوع الجهاز (iOS / Android / Web / غير معروف).
  IconData get _icon {
    final p = session.platform.toLowerCase();
    if (p.contains('ios')) return Icons.phone_iphone_rounded;
    if (p.contains('android')) return Icons.phone_android_rounded;
    if (p.contains('web') || p.contains('browser')) {
      return Icons.public_rounded;
    }
    return Icons.devices_other_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(_icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        session.deviceName.isEmpty
                            ? bi(context,
                                ar: "جهاز غير معروف",
                                en: "Unknown device")
                            : session.deviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    if (session.isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius:
                              BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          bi(context, ar: "الحالي", en: "Current"),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _subtitle(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _relativeTime(context, session.lastActive),
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء سطر العنوان الفرعي: "المدينة · IP" أو platform إن لم يوجد شيء آخر.
  String _subtitle(BuildContext context) {
    final parts = <String>[
      if (session.city.isNotEmpty) session.city,
      if (session.ip.isNotEmpty) session.ip,
    ];
    if (parts.isEmpty) return session.platform;
    return parts.join(' · ');
  }

  /// تحويل وقت إلى نص نسبي مفهوم: "نشط الآن"، "قبل 5 دقائق"، "قبل يوم".
  String _relativeTime(BuildContext context, DateTime? t) {
    if (t == null) {
      return bi(context, ar: "وقت غير معروف", en: "Unknown time");
    }
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) {
      return bi(context, ar: "نشط الآن", en: "Active now");
    }
    if (diff.inMinutes < 60) {
      return bi(context,
          ar: "قبل ${diff.inMinutes} دقيقة",
          en: "${diff.inMinutes} min ago");
    }
    if (diff.inHours < 24) {
      return bi(context,
          ar: "قبل ${diff.inHours} ساعة",
          en: "${diff.inHours} h ago");
    }
    if (diff.inDays < 30) {
      return bi(context,
          ar: "قبل ${diff.inDays} يوم",
          en: "${diff.inDays} d ago");
    }
    return bi(context,
        ar: "قبل ${(diff.inDays / 30).floor()} شهر",
        en: "${(diff.inDays / 30).floor()} mo ago");
  }
}

/// DTO للجلسة الواحدة — يُبنى من JSON الخادم.
class _Session {
  final String id;
  final String deviceName;
  final String platform;
  final String ip;
  final String city;
  final DateTime? lastActive;
  final bool isCurrent;

  const _Session({
    required this.id,
    required this.deviceName,
    required this.platform,
    required this.ip,
    required this.city,
    required this.lastActive,
    required this.isCurrent,
  });

  factory _Session.fromJson(Map j) {
    DateTime? parsed;
    final raw = j['last_active'];
    if (raw is String && raw.isNotEmpty) {
      parsed = DateTime.tryParse(raw)?.toLocal();
    }
    return _Session(
      id: (j['id'] ?? '').toString(),
      deviceName: (j['device_name'] ?? '').toString(),
      platform: (j['platform'] ?? '').toString(),
      ip: (j['ip'] ?? '').toString(),
      city: (j['city'] ?? '').toString(),
      lastActive: parsed,
      isCurrent: j['is_current'] == true,
    );
  }
}
