import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'theme.dart';
// ignore: unused_import
import 'widgets.dart';

/// Profile screen — avatar, identity, vacation balance, and a
/// tap-to-reveal financial card (salary / bank / IBAN, masked by default).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = const FlutterSecureStorage();
  final dioClient = DioClient().client;

  String name = "";
  Map<String, dynamic> info = {};
  String type = "user";
  bool loading = true;
  bool _revealFinance = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final n = await _storage.read(key: "name");
    final tp = await _storage.read(key: "current_view");
    if (n != null) name = n;
    if (tp != null) type = tp;
    try {
      final path = type == "mgr" ? '/mgr/myinfoview' : '/myinfoview';
      final response = await dioClient.get(path);
      if (response.statusCode == 201) {
        info = Map<String, dynamic>.from(response.data);
      }
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  String _safeName(dynamic v) => v == null ? '' : v.toString();

  int _safeInt(dynamic v) {
    if (v == null) return 0;
    return int.tryParse(v.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final profileInfo = info['info'] ?? {};
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final fullName = type == 'mgr'
        ? _safeName(profileInfo['emnme1'])
        : (_safeName(profileInfo['emnma1']) +
                " " +
                _safeName(profileInfo['emnma2']) +
                " " +
                _safeName(profileInfo['emnma3']))
            .trim();

    return ModernScaffold(
      title: t.myinfo,
      subtitle: type == 'mgr'
          ? bi(context, ar: "ملف المدير", en: "Manager profile")
          : bi(context, ar: "ملف الموظف", en: "Employee profile"),
      leadingIcon: Icons.person_outline_rounded,
      body: loading
          ? _buildSkeleton()
          : info.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 60),
                    EmptyState(
                      icon: Icons.person_off_rounded,
                      title: t.internet,
                      subtitle: bi(context,
                          ar: "تعذر تحميل الملف الشخصي.",
                          en: "Unable to load your profile."),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Avatar card
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.10),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              fullName.isEmpty ? name : fullName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                type == 'mgr'
                                    ? bi(context,
                                        ar: "مدير", en: "MANAGER")
                                    : bi(context,
                                        ar: "موظف", en: "EMPLOYEE"),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Personal info card
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 6),
                        child: Column(
                          children: [
                            InfoTile(
                                icon: Icons.badge_outlined,
                                label: t.empcode,
                                value: '${profileInfo['emcd'] ?? ''}'),
                            const Divider(
                                height: 1, color: AppColors.border),
                            InfoTile(
                                icon: Icons.phone_iphone_rounded,
                                label: t.mobile,
                                value: '${profileInfo['empmob'] ?? ''}'),
                            if (type != 'mgr') ...[
                              const Divider(
                                  height: 1, color: AppColors.border),
                              InfoTile(
                                  icon: Icons.beach_access_outlined,
                                  label: t.vacbal,
                                  value: '${info['vacBal'] ?? ''}'),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Financial details — hidden behind reveal toggle
                      _buildFinancialCard(t, profileInfo),
                      const SizedBox(height: 14),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: GlassCard(
                              onTap: () => Navigator.pushNamed(
                                  context, "/updateInfo"),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Icon(
                                      Icons.edit_rounded,
                                      color: AppColors.secondary,
                                      size: 24),
                                  const SizedBox(height: 8),
                                  Text(t.updateinfo,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                      )),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassCard(
                              onTap: () => Navigator.pushNamed(
                                  context, "/complaint"),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Icon(
                                      Icons.support_agent_rounded,
                                      color: AppColors.primary,
                                      size: 24),
                                  const SizedBox(height: 8),
                                  Text(t.complaint,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                      )),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar + name
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: const [
                Skeleton.box(size: 76, radius: 38),
                SizedBox(height: 14),
                Skeleton(width: 180, height: 16),
                SizedBox(height: 8),
                Skeleton(width: 120, height: 12),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Info card with rows
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _profileSkeletonRow(),
                const Divider(height: 1, color: AppColors.border),
                _profileSkeletonRow(),
                const Divider(height: 1, color: AppColors.border),
                _profileSkeletonRow(),
                const Divider(height: 1, color: AppColors.border),
                _profileSkeletonRow(),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Finance card placeholder
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Skeleton(width: 140, height: 14),
                SizedBox(height: 16),
                Skeleton(width: 220, height: 28),
                SizedBox(height: 6),
                Skeleton(width: 100, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileSkeletonRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: const [
          Skeleton.box(size: 36, radius: 8),
          SizedBox(width: 12),
          Skeleton(width: 80, height: 12),
          Spacer(),
          Skeleton(width: 110, height: 13),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(AppLocalizations t, Map profileInfo) {
    final basicSalary = type == 'mgr'
        ? _safeInt(profileInfo['slbse'])
        : (_safeInt(profileInfo['slbse']) +
            _safeInt(profileInfo['sladd']) +
            _safeInt(profileInfo['trns']) +
            _safeInt(profileInfo['monhvl']) +
            _safeInt(profileInfo['insr']) +
            _safeInt(profileInfo['itmvlu03']));

    String mask(String v) {
      if (v.isEmpty) return '—';
      return '•' * v.length;
    }

    Widget revealValue(String raw) {
      return Text(
        _revealFinance ? (raw.isEmpty ? '—' : raw) : mask(raw),
        style: const TextStyle(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      );
    }

    final bank = '${profileInfo['bkaccno'] ?? ''}';
    final iban = '${profileInfo['iban'] ?? ''}';
    final salaryStr = basicSalary == 0 ? '' : basicSalary.toString();

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header with toggle
          InkWell(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg)),
            onTap: () => setState(() => _revealFinance = !_revealFinance),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.10),
                      borderRadius:
                          BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Icon(
                      _revealFinance
                          ? Icons.lock_open_rounded
                          : Icons.lock_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
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
                              ar: "اضغط للكشف — لحفظ الخصوصية",
                              en: "Tap to reveal — keeps data private"),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _revealFinance
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 4),
            child: Column(
              children: [
                _financeRow(
                  icon: Icons.payments_outlined,
                  label: t.basicsal,
                  child: revealValue(salaryStr),
                ),
                const Divider(height: 1, color: AppColors.border),
                _financeRow(
                  icon: Icons.account_balance_outlined,
                  label: t.bankno,
                  child: revealValue(bank),
                ),
                const Divider(height: 1, color: AppColors.border),
                _financeRow(
                  icon: Icons.credit_card_outlined,
                  label: t.iban,
                  child: revealValue(iban),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _financeRow({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child:
                Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
                fontSize: 13.5,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Align(
              alignment: Alignment.centerRight,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
