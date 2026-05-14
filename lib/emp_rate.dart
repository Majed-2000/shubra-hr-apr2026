// ============================================================================
// ملف: emp_rate.dart
// الغرض: شاشة عرض تقييمات أداء الموظف عبر الأرباع (Q1, Q2, ...).
// المحتوى:
//   - شريط Chips لاختيار الرُبع (بديل أنيق للـ Dropdown).
//   - دائرة كبيرة بالنتيجة الإجمالية مع ring progress.
//   - شارة تفسير (ممتاز/جيد/متوسط/يحتاج تحسين) بلون مناسب.
//   - تفصيل المكوّنات (GM + DM + HR) مع شريط تقدّم لكل واحد.
//   - حالات loading / empty / error مع animations.
// API: POST /getquarter + POST /getemprate.
// ============================================================================

import 'package:flutter/material.dart';

import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'shared/utils/dio_errors.dart';
import 'shared/utils/logger.dart';
import 'shared/widgets/rating_widgets.dart';
import 'theme.dart';
import 'widgets.dart';

/// Employee-facing performance rating screen — view scores by quarter.
///
/// شاشة عرض تقييمات الأداء — يختار الموظف رُبعاً ويرى تقييماته.
class EmpRate extends StatefulWidget {
  @override
  _EmpRateState createState() => _EmpRateState();
}

class _EmpRateState extends State<EmpRate>
    with SingleTickerProviderStateMixin {
  final dioClient = DioClient().client;

  List<dynamic> _quarters = [];
  List<String> _quarterLabels = [];

  String? _selectedSeqno;
  String _grddm = "";
  num _grdhr = 0;
  String _grdgm = "";

  bool _loadingQuarters = true;
  bool _loadingScore = false;
  String? _error;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fetchQuarters();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  /// جلب قائمة الأرباع المتاحة من الـ backend.
  Future<void> _fetchQuarters() async {
    setState(() {
      _loadingQuarters = true;
      _error = null;
    });
    try {
      final response = await dioClient.post('/getquarter');
      final data = response.data;
      if (!mounted) return;
      setState(() {
        _quarters = (data["grddm"] as List?) ?? [];
        _loadingQuarters = false;
      });
    } catch (e) {
      logD('emp_rate /getquarter failed: $e');
      if (!mounted) return;
      setState(() {
        _loadingQuarters = false;
        _error = parseDioError(e, isArabic: isArabic(context));
      });
    }
  }

  /// جلب تقييمات رُبع معيّن وعرضها بـ fade animation.
  Future<void> _fetchScore(String seqno) async {
    setState(() {
      _selectedSeqno = seqno;
      _loadingScore = true;
      _grdgm = "";
      _grddm = "";
      _grdhr = 0;
    });
    _fadeCtrl.reset();
    try {
      final response =
          await dioClient.post('/getemprate', data: {'seqno': seqno});
      final data = response.data;
      if (!mounted) return;
      // HR في الـ backend = خصومات الموارد البشرية؛ نحوّلها لتقييم إيجابي
      // بطرحها من 50 (الحد الأقصى لمساهمة HR).
      final hrVal = num.tryParse(data['hr']?.toString() ?? '0') ?? 0;
      setState(() {
        _grdgm = data['gm']?.toString() ?? '0';
        _grddm = data['dm']?.toString() ?? '0';
        _grdhr = hrVal > 50 ? 0 : 50 - hrVal;
        _loadingScore = false;
      });
      _fadeCtrl.forward();
    } catch (e) {
      logD('emp_rate /getemprate failed: $e');
      if (!mounted) return;
      setState(() {
        _loadingScore = false;
        _error = parseDioError(e, isArabic: isArabic(context));
      });
    }
  }

  /// النتيجة الإجمالية = GM + DM + HR (الحد الأقصى 100).
  num get _totalScore =>
      (num.tryParse(_grdgm) ?? 0) +
      _grdhr +
      (num.tryParse(_grddm) ?? 0);

  bool get _hasScore => _grdgm.isNotEmpty && !_loadingScore;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    // ترجمات أسماء الأرباع — تُحسَب مرة واحدة.
    if (_quarterLabels.isEmpty) {
      _quarterLabels = [t.first, t.second, t.third, t.fourth];
    }

    return ModernScaffold(
      title: t.rate,
      subtitle: bi(context, ar: "تقييم الأداء", en: "Performance rating"),
      leadingIcon: Icons.star_rate_rounded,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetchQuarters,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildQuarterSelector(t),
              const SizedBox(height: 16),
              _buildScoreSection(t),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Quarter selector (chip row) ──────────────────────────────────────
  Widget _buildQuarterSelector(AppLocalizations t) {
    if (_loadingQuarters) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton(width: 120, height: 14),
            const SizedBox(height: 14),
            SizedBox(
              height: 64,
              child: Row(
                children: const [
                  Skeleton(width: 160, height: 56, radius: 12),
                  SizedBox(width: 10),
                  Skeleton(width: 160, height: 56, radius: 12),
                  SizedBox(width: 10),
                  Skeleton(width: 160, height: 56, radius: 12),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null && _quarters.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.cloud_off_rounded,
                color: AppColors.muted, size: 36),
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: bi(context, ar: "إعادة المحاولة", en: "Try again"),
              icon: Icons.refresh_rounded,
              onPressed: _fetchQuarters,
              expand: false,
            ),
          ],
        ),
      );
    }

    if (_quarters.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: EmptyState(
          icon: Icons.event_busy_rounded,
          title: bi(context,
              ar: "لا توجد فترات تقييم متاحة",
              en: "No rating periods available"),
          subtitle: bi(context,
              ar: "ستظهر الفترات هنا بمجرد إصدارها من قسم الموارد البشرية.",
              en: "Periods will appear here once HR publishes them."),
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                bi(context, ar: "اختر فترة التقييم", en: "Pick a period"),
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // قائمة Chips أفقية للأرباع.
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quarters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final item = _quarters[i];
                final seqno = item['seqno'].toString();
                final selected = seqno == _selectedSeqno;
                final typeIdx =
                    (int.tryParse(item['elvtyp']?.toString() ?? '1') ?? 1) - 1;
                final label = (typeIdx >= 0 && typeIdx < _quarterLabels.length)
                    ? _quarterLabels[typeIdx]
                    : 'Q${typeIdx + 1}';
                return QuarterChip(
                  label: label,
                  fromDate: item['frmdat']?.toString() ?? '',
                  toDate: item['todat']?.toString() ?? '',
                  selected: selected,
                  onTap: () => _fetchScore(seqno),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Score section ────────────────────────────────────────────────────
  Widget _buildScoreSection(AppLocalizations t) {
    if (_loadingScore) {
      return GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Skeleton.box(size: 120, radius: 60),
            const SizedBox(height: 14),
            const Skeleton(width: 140, height: 14),
            const SizedBox(height: 20),
            const Skeleton(width: double.infinity, height: 40, radius: 8),
            const SizedBox(height: 10),
            const Skeleton(width: double.infinity, height: 40, radius: 8),
            const SizedBox(height: 10),
            const Skeleton(width: double.infinity, height: 40, radius: 8),
          ],
        ),
      );
    }

    if (!_hasScore) {
      if (_selectedSeqno == null) {
        return GlassCard(
          padding: const EdgeInsets.all(24),
          child: EmptyState(
            icon: Icons.touch_app_rounded,
            title: bi(context,
                ar: "اختر فترة لعرض التقييم",
                en: "Pick a period to see your rating"),
            subtitle: bi(context,
                ar: "اضغط على أي بطاقة فترة في الأعلى.",
                en: "Tap any period card above."),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    final total = _totalScore;
    final tier = ScoreTier.forTotal(total, isArabic(context));

    return FadeTransition(
      opacity: _fade,
      child: Column(
        children: [
          _buildTotalCard(t, total, tier),
          const SizedBox(height: 14),
          _buildBreakdownCard(t, tier),
        ],
      ),
    );
  }

  Widget _buildTotalCard(AppLocalizations t, num total, ScoreTier tier) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      child: Column(
        children: [
          // دائرة كبيرة مع ring progress تعرض النتيجة من 100.
          SizedBox(
            width: 144,
            height: 144,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // حلقة خلفية رمادية.
                SizedBox(
                  width: 144,
                  height: 144,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 10,
                    valueColor: AlwaysStoppedAnimation(
                        AppColors.surfaceAlt),
                  ),
                ),
                // حلقة التقدّم بلون الفئة.
                SizedBox(
                  width: 144,
                  height: 144,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: total / 100),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, value, __) => CircularProgressIndicator(
                      value: value.clamp(0, 1),
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      valueColor: AlwaysStoppedAnimation(tier.color),
                    ),
                  ),
                ),
                // النتيجة نصاً في المنتصف.
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: total.toDouble()),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (_, value, __) => Text(
                        value.round().toString(),
                        style: TextStyle(
                          color: tier.color,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "/ 100",
                      style: TextStyle(
                        color: tier.color.withOpacity(0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            bi(context, ar: "إجمالي التقييم", en: "Total score"),
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          // شارة الفئة (ممتاز / جيد / متوسط / يحتاج تحسين).
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: tier.color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tier.color.withOpacity(0.30)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tier.icon, color: tier.color, size: 16),
                const SizedBox(width: 6),
                Text(
                  tier.label,
                  style: TextStyle(
                    color: tier.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(AppLocalizations t, ScoreTier tier) {
    final gm = num.tryParse(_grdgm) ?? 0;
    final dm = num.tryParse(_grddm) ?? 0;
    final hr = _grdhr;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                bi(context,
                    ar: "تفاصيل التقييم", en: "Score breakdown"),
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ScoreBar(
            icon: Icons.trending_up_rounded,
            label: t.grdgm,
            value: gm,
            maxValue: 30,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          ScoreBar(
            icon: Icons.star_outline_rounded,
            label: t.grdmdm,
            value: dm,
            maxValue: 20,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 12),
          ScoreBar(
            icon: Icons.schedule_rounded,
            label: t.grdhr,
            value: hr,
            maxValue: 50,
            color: AppColors.success,
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// المكوّنات المشتركة (QuarterChip, ScoreBar, ScoreTier) مُعرَّفة في
// shared/widgets/rating_widgets.dart ومستوردة في الأعلى.
