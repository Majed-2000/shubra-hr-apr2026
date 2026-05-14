// ============================================================================
// ملف: emp_rate_mgr.dart
// الغرض: شاشة عرض تقييم أي موظف من جانب المدير.
// التدفق:
//   1) المدير يُدخل رقم الموظف ويضغط بحث.
//   2) تظهر فترات التقييم المتاحة (chips).
//   3) عند اختيار فترة → تظهر النتيجة الإجمالية + التفصيل.
// API:
//   POST /mgr/getemprate (يستلم empcode) → قائمة الفترات.
//   POST /mgr/getempratevalues (يستلم seqno + emcd) → قيم التقييم.
// ============================================================================

import 'package:flutter/material.dart';

import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'shared/utils/dio_errors.dart';
import 'shared/utils/logger.dart';
import 'shared/utils/snackbar.dart';
import 'shared/widgets/rating_widgets.dart';
import 'theme.dart';
import 'widgets.dart';

/// Manager-facing performance rating screen — view any employee's score
/// by quarter after entering their employee code.
///
/// شاشة المدير لعرض تقييم أي موظف عبر رقمه + اختيار الفترة.
class EmpRateMgr extends StatefulWidget {
  @override
  _EmpRateMgrState createState() => _EmpRateMgrState();
}

class _EmpRateMgrState extends State<EmpRateMgr>
    with SingleTickerProviderStateMixin {
  final dioClient = DioClient().client;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _employeeIdController = TextEditingController();

  List<dynamic> _quarters = [];
  List<String> _quarterLabels = [];

  String? _selectedSeqno;
  String _grddm = "";
  num _grdhr = 0;
  String _grdgm = "";

  bool _searching = false;
  bool _loadingScore = false;
  bool _searched = false; // هل تم تنفيذ بحث مرة واحدة على الأقل؟

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
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  /// بحث عن فترات التقييم لموظف معيّن.
  Future<void> _searchEmployee() async {
    if (!_formKey.currentState!.validate()) return;
    // إخفاء لوحة المفاتيح وإعادة تعيين الحالة قبل البحث.
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _searched = true;
      _quarters = [];
      _selectedSeqno = null;
      _grdgm = "";
      _grddm = "";
      _grdhr = 0;
    });
    try {
      final response = await dioClient.post('/mgr/getemprate',
          data: {"empcode": _employeeIdController.text.trim()});
      final data = response.data;
      if (!mounted) return;
      setState(() {
        _quarters = (data["grd"] as List?) ?? [];
        _searching = false;
      });
      // إن لم تكن هناك فترات → إعلام المستخدم.
      if (_quarters.isEmpty && mounted) {
        SnackbarHelpers.showInfo(
          context,
          bi(context,
              ar: "لا توجد فترات تقييم لهذا الموظف",
              en: "No rating periods for this employee"),
        );
      }
    } catch (e) {
      logD('emp_rate_mgr /getemprate failed: $e');
      if (!mounted) return;
      setState(() => _searching = false);
      SnackbarHelpers.showError(
        context,
        parseDioError(e, isArabic: isArabic(context)),
      );
    }
  }

  /// جلب قيم التقييم لفترة معيّنة لهذا الموظف.
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
      final response = await dioClient.post('/mgr/getempratevalues', data: {
        'seqno': seqno,
        "emcd": _employeeIdController.text.trim(),
      });
      final data = response.data;
      if (!mounted) return;
      // HR في الـ backend = خصومات → نطرحها من 50 لتصبح مساهمة إيجابية.
      final hrRaw = data['hr'];
      final hrNum =
          hrRaw is num ? hrRaw : (num.tryParse(hrRaw?.toString() ?? '0') ?? 0);
      setState(() {
        _grdgm = data['gm']?.toString() ?? '0';
        _grddm = data['dm']?.toString() ?? '0';
        _grdhr = hrNum > 50 ? 0 : 50 - hrNum;
        _loadingScore = false;
      });
      _fadeCtrl.forward();
    } catch (e) {
      logD('emp_rate_mgr /getempratevalues failed: $e');
      if (!mounted) return;
      setState(() => _loadingScore = false);
      SnackbarHelpers.showError(
        context,
        parseDioError(e, isArabic: isArabic(context)),
      );
    }
  }

  num get _totalScore =>
      (num.tryParse(_grdgm) ?? 0) + _grdhr + (num.tryParse(_grddm) ?? 0);

  bool get _hasScore => _grdgm.isNotEmpty && !_loadingScore;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (_quarterLabels.isEmpty) {
      _quarterLabels = [t.first, t.second, t.third, t.fourth];
    }

    return ModernScaffold(
      title: t.rate,
      subtitle: bi(context,
          ar: "تقييم أداء الموظفين", en: "Employee performance"),
      leadingIcon: Icons.star_rate_rounded,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchCard(t),
            const SizedBox(height: 14),
            if (_searched && _quarters.isNotEmpty) ...[
              _buildQuarterSelector(),
              const SizedBox(height: 14),
            ],
            if (_searched) _buildScoreSection(t),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Search card ──────────────────────────────────────────────────────
  Widget _buildSearchCard(AppLocalizations t) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: const Icon(Icons.person_search_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bi(context,
                            ar: "بحث عن موظف", en: "Find an employee"),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bi(context,
                            ar: "أدخل رقم الموظف لعرض تقييماته",
                            en: "Enter employee code to view their ratings"),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: t.empcode,
              controller: _employeeIdController,
              icon: Icons.badge_outlined,
              hint: t.empcode,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? t.enterempcode : null,
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: bi(context, ar: "بحث", en: "Search"),
              icon: Icons.search_rounded,
              loading: _searching,
              onPressed: _searchEmployee,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Quarter chip selector ────────────────────────────────────────────
  Widget _buildQuarterSelector() {
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
      if (_searching) return const SizedBox.shrink();
      if (_quarters.isEmpty) {
        // بحث انتهى لكن لا توجد فترات لهذا الموظف.
        return GlassCard(
          padding: const EdgeInsets.all(24),
          child: EmptyState(
            icon: Icons.event_busy_rounded,
            title: bi(context,
                ar: "لا توجد فترات تقييم",
                en: "No rating periods"),
            subtitle: bi(context,
                ar: "تأكّد من رقم الموظف أو راجع قسم الموارد البشرية.",
                en: "Verify the employee code or contact HR."),
          ),
        );
      }
      if (_selectedSeqno == null) {
        return GlassCard(
          padding: const EdgeInsets.all(24),
          child: EmptyState(
            icon: Icons.touch_app_rounded,
            title: bi(context,
                ar: "اختر فترة لعرض التقييم",
                en: "Pick a period to see the rating"),
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
          _buildTotalCard(total, tier),
          const SizedBox(height: 14),
          _buildBreakdownCard(t),
        ],
      ),
    );
  }

  Widget _buildTotalCard(num total, ScoreTier tier) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      child: Column(
        children: [
          SizedBox(
            width: 144,
            height: 144,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 144,
                  height: 144,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 10,
                    valueColor: AlwaysStoppedAnimation(AppColors.surfaceAlt),
                  ),
                ),
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

  Widget _buildBreakdownCard(AppLocalizations t) {
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
                bi(context, ar: "تفاصيل التقييم", en: "Score breakdown"),
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
