import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'shared/utils/dio_errors.dart';
import 'shared/utils/logger.dart';
import 'shared/utils/snackbar.dart';
import 'theme.dart';
import 'widgets.dart';

/// Manager + colleagues directory — current employee's direct manager
/// at the top, then everyone reporting to the same manager.
class Colleagues extends StatefulWidget {
  const Colleagues({super.key});

  @override
  State<Colleagues> createState() => _ColleaguesState();
}

class _ColleaguesState extends State<Colleagues> {
  final dioClient = DioClient().client;

  bool _isLoading = true;
  _Person? _manager;
  List<_Person> _colleagues = const [];
  bool _hasData = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final response = await dioClient.get('/colleagues');
      final data = Map<String, dynamic>.from(response.data as Map);

      _manager = data['manager'] != null
          ? _Person.fromJson(Map<String, dynamic>.from(data['manager']))
          : null;
      _colleagues = ((data['colleagues'] as List?) ?? const [])
          .map((e) => _Person.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _hasData = true;
    } on DioException catch (e) {
      logD('Colleagues fetch failed: $e');
      if (!mounted) return;
      _hasData = false;
      SnackbarHelpers.showError(
        context,
        parseDioError(e, isArabic: isArabic(context)),
      );
    } catch (e) {
      logD('Colleagues unexpected error: $e');
      if (!mounted) return;
      _hasData = false;
      SnackbarHelpers.showError(
        context,
        isArabic(context)
            ? 'حدث خطأ غير متوقع. يُرجى المحاولة مرة أخرى.'
            : 'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    final ok = await launchUrl(uri);
    if (!ok && mounted) {
      SnackbarHelpers.showError(
        context,
        AppLocalizations.of(context)!.callFailed,
      );
    }
  }

  Future<void> _email(String address) async {
    final uri = Uri(scheme: 'mailto', path: address);
    final ok = await launchUrl(uri);
    if (!ok && mounted) {
      SnackbarHelpers.showError(
        context,
        AppLocalizations.of(context)!.emailFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ModernScaffold(
      title: t.colleagues,
      subtitle: t.colleaguesSubtitle,
      leadingIcon: Icons.groups_rounded,
      body: _isLoading
          ? const SkeletonList()
          : !_hasData
              ? ListView(
                  children: [
                    const SizedBox(height: 60),
                    EmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: t.nodata,
                      subtitle: t.internet,
                    ),
                  ],
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _fetch,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _buildManagerSection(context, t),
                      const SizedBox(height: 18),
                      _buildColleaguesHeader(context, t),
                      const SizedBox(height: 8),
                      if (_colleagues.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: EmptyState(
                            icon: Icons.people_outline_rounded,
                            title: t.nodata,
                            subtitle: t.noColleagues,
                          ),
                        )
                      else
                        for (final p in _colleagues) ...[
                          _ColleagueCard(
                            person: p,
                            onCall: p.hasMobile
                                ? () => _call(p.mobile!)
                                : null,
                            onEmail: p.hasEmail
                                ? () => _email(p.email!)
                                : null,
                          ),
                          const SizedBox(height: 10),
                        ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildManagerSection(BuildContext context, AppLocalizations t) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                t.directManager,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_manager == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                t.noManager,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            _PersonDetailBlock(
              person: _manager!,
              compact: false,
              onCall: _manager!.hasMobile
                  ? () => _call(_manager!.mobile!)
                  : null,
              onEmail: _manager!.hasEmail
                  ? () => _email(_manager!.email!)
                  : null,
            ),
        ],
      ),
    );
  }

  Widget _buildColleaguesHeader(BuildContext context, AppLocalizations t) {
    return Row(
      children: [
        const Icon(Icons.groups_2_rounded,
            color: AppColors.secondary, size: 20),
        const SizedBox(width: 8),
        Text(
          t.colleaguesCount(_colleagues.length),
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _PersonDetailBlock extends StatelessWidget {
  final _Person person;
  final bool compact;
  final VoidCallback? onCall;
  final VoidCallback? onEmail;

  const _PersonDetailBlock({
    required this.person,
    required this.compact,
    this.onCall,
    this.onEmail,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final localized = person.localizedName(context);
    final initials = localized.isNotEmpty ? localized[0].toUpperCase() : '?';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: compact ? 42 : 50,
              height: compact ? 42 : 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 16 : 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localized,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 14 : 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  if (person.jobTitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        person.jobTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _InfoLine(
          icon: Icons.badge_outlined,
          value: '${t.empcode}: ${person.empcode}',
        ),
        if (person.hasMobile) ...[
          const SizedBox(height: 4),
          _InfoLine(
            icon: Icons.phone_iphone_rounded,
            value: person.mobile!,
          ),
        ],
        if (person.hasEmail) ...[
          const SizedBox(height: 4),
          _InfoLine(
            icon: Icons.alternate_email_rounded,
            value: person.email!,
          ),
        ],
        if (onCall != null || onEmail != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (onCall != null)
                Expanded(
                  child: _ActionButton(
                    icon: Icons.call_rounded,
                    label: t.callBtn,
                    color: AppColors.success,
                    onTap: onCall!,
                  ),
                ),
              if (onCall != null && onEmail != null)
                const SizedBox(width: 10),
              if (onEmail != null)
                Expanded(
                  child: _ActionButton(
                    icon: Icons.email_rounded,
                    label: t.emailBtn,
                    color: AppColors.primary,
                    onTap: onEmail!,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ColleagueCard extends StatelessWidget {
  final _Person person;
  final VoidCallback? onCall;
  final VoidCallback? onEmail;

  const _ColleagueCard({
    required this.person,
    this.onCall,
    this.onEmail,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: _PersonDetailBlock(
        person: person,
        compact: true,
        onCall: onCall,
        onEmail: onEmail,
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String value;
  const _InfoLine({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Person {
  final String empcode;
  final String nameAr;
  final String nameEn;
  final String jobTitle;
  final String? mobile;
  final String? email;

  _Person({
    required this.empcode,
    required this.nameAr,
    required this.nameEn,
    required this.jobTitle,
    this.mobile,
    this.email,
  });

  factory _Person.fromJson(Map<String, dynamic> json) {
    return _Person(
      empcode: json['empcode']?.toString() ?? '',
      nameAr: (json['name_ar']?.toString() ?? '').trim(),
      nameEn: (json['name_en']?.toString() ?? '').trim(),
      jobTitle: (json['job_title']?.toString() ?? '').trim(),
      mobile: _nullableTrim(json['mobile']),
      email: _nullableTrim(json['email']),
    );
  }

  static String? _nullableTrim(Object? v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  bool get hasMobile => mobile != null;
  bool get hasEmail => email != null;

  String localizedName(BuildContext context) {
    final ar = isArabic(context);
    final preferred = ar ? nameAr : nameEn;
    if (preferred.isNotEmpty) return preferred;
    return ar ? nameEn : nameAr;
  }
}
