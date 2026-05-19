// ============================================================================
// File: eos/eos_calculator.dart
// Purpose: End-of-service calculator screen (feature 8). Pulls hire date +
//          basic salary from /myinfoview when available, else lets user
//          enter them manually. Math is delegated to EosEngine (pure Dart).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../dio_client.dart';
import '../shared/utils/logger.dart';
import '../theme.dart';
import '../widgets.dart';
import 'eos_engine.dart';
import 'eos_models.dart';

class EosCalculator extends StatefulWidget {
  const EosCalculator({super.key});

  @override
  State<EosCalculator> createState() => _EosCalculatorState();
}

class _EosCalculatorState extends State<EosCalculator> {
  final _dio = DioClient().client;
  final _basicCtrl = TextEditingController();
  final _housingCtrl = TextEditingController();
  final _transportCtrl = TextEditingController();

  DateTime? _hireDate;
  DateTime _endDate = DateTime.now();
  EndReason _reason = EndReason.termination;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await _dio.get('/myinfoview');
      if (res.statusCode == 201 && res.data is Map) {
        final info = (res.data['info'] ?? {}) as Map;
        final basic = double.tryParse('${info['slbse'] ?? 0}') ?? 0;
        final housing = double.tryParse('${info['monhvl'] ?? 0}') ?? 0;
        final transport = double.tryParse('${info['trns'] ?? 0}') ?? 0;
        _basicCtrl.text = basic.toStringAsFixed(0);
        _housingCtrl.text = housing.toStringAsFixed(0);
        _transportCtrl.text = transport.toStringAsFixed(0);
        // hire_date field name will be added by backend; tolerate missing
        final raw = info['hire_date'] ?? info['joindate'] ?? info['hirdate'];
        if (raw != null) _hireDate = DateTime.tryParse(raw.toString());
      }
    } catch (e) {
      logD('EOS profile load failed: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _basicCtrl.dispose();
    _housingCtrl.dispose();
    _transportCtrl.dispose();
    super.dispose();
  }

  EosResult? get _result {
    if (_hireDate == null) return null;
    final basic = double.tryParse(_basicCtrl.text) ?? 0;
    if (basic <= 0) return null;
    return EosEngine.calculate(EosInputs(
      hireDate: _hireDate!,
      endDate: _endDate,
      reason: _reason,
      basicSalary: basic,
      housingAllowance: double.tryParse(_housingCtrl.text) ?? 0,
      transportAllowance: double.tryParse(_transportCtrl.text) ?? 0,
    ));
  }

  Future<void> _pickHireDate() async {
    final picked = await _pickDate(_hireDate ?? DateTime(DateTime.now().year - 3));
    if (picked != null) setState(() => _hireDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await _pickDate(_endDate);
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<DateTime?> _pickDate(DateTime initial) async {
    DateTime selected = initial;
    return await showDialog<DateTime>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SfDateRangePicker(
                initialSelectedDate: initial,
                selectionMode: DateRangePickerSelectionMode.single,
                showActionButtons: false,
                maxDate: DateTime.now().add(const Duration(days: 365)),
                onSelectionChanged: (a) {
                  if (a.value is DateTime) selected = a.value as DateTime;
                },
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(bi(context, ar: 'إلغاء', en: 'Cancel')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, selected),
                      child: Text(bi(context, ar: 'موافق', en: 'OK')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _share() {
    final r = _result;
    if (r == null) return;
    final fmt = NumberFormat('#,##0', 'ar_SA');
    final text = '''
حساب مكافأة نهاية الخدمة
سنوات الخدمة: ${r.serviceYears.toStringAsFixed(2)}
الأجر الشهري: ${fmt.format(r.monthlyWage)} ر.س
المجموع التقديري: ${fmt.format(r.totalSar)} ر.س

* هذا تقدير استرشادي وفقاً لنظام العمل السعودي.
* القيمة النهائية تخضع لمراجعة الموارد البشرية.''';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return ModernScaffold(
      title: bi(context,
          ar: 'مكافأة نهاية الخدمة', en: 'End-of-Service Benefit'),
      subtitle: bi(context, ar: 'تقدير استرشادي', en: 'Indicative estimate'),
      leadingIcon: Icons.calculate_rounded,
      body: _loading
          ? const Loader()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _disclaimerCard(),
                const SizedBox(height: 12),
                _inputsCard(),
                const SizedBox(height: 12),
                if (r != null) _resultCard(r),
                if (r != null) ...[
                  const SizedBox(height: 12),
                  _breakdownCard(r),
                ],
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: Text(bi(context,
                        ar: 'المادتان 84 و 85 من نظام العمل',
                        en: 'Labour Law Articles 84 & 85')),
                    onPressed: () => launchUrl(
                      Uri.parse('https://hrsd.gov.sa/'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _disclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              bi(context,
                  ar: 'تقدير استرشادي وفقاً لنظام العمل السعودي. القيمة النهائية تخضع لمراجعة الموارد البشرية.',
                  en: 'Indicative estimate per Saudi Labour Law. Final value subject to HR review.'),
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputsCard() {
    final dfmt = DateFormat('yyyy/MM/dd');
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bi(context, ar: 'البيانات', en: 'Inputs'),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          _dateRow(
            label: bi(context, ar: 'تاريخ التعيين', en: 'Hire date'),
            value: _hireDate == null
                ? bi(context, ar: 'اختر التاريخ', en: 'Pick date')
                : dfmt.format(_hireDate!),
            onTap: _pickHireDate,
          ),
          const SizedBox(height: 12),
          _dateRow(
            label: bi(context, ar: 'تاريخ انتهاء الخدمة', en: 'End date'),
            value: dfmt.format(_endDate),
            onTap: _pickEndDate,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _reasonChip(
                  label: bi(context, ar: 'إنهاء عقد', en: 'Termination'),
                  selected: _reason == EndReason.termination,
                  onTap: () => setState(() => _reason = EndReason.termination),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _reasonChip(
                  label: bi(context, ar: 'استقالة', en: 'Resignation'),
                  selected: _reason == EndReason.resignation,
                  onTap: () => setState(() => _reason = EndReason.resignation),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _numField(_basicCtrl,
              label: bi(context, ar: 'الراتب الأساسي', en: 'Basic salary')),
          const SizedBox(height: 8),
          _numField(_housingCtrl,
              label: bi(context, ar: 'بدل السكن', en: 'Housing allowance')),
          const SizedBox(height: 8),
          _numField(_transportCtrl,
              label: bi(context, ar: 'بدل النقل', en: 'Transport allowance')),
        ],
      ),
    );
  }

  Widget _dateRow({required String label, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.muted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(color: AppColors.muted, fontSize: 13)),
            ),
            Text(value,
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      ),
    );
  }

  Widget _reasonChip({required String label, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xs),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.12)
              : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 1.4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _numField(TextEditingController ctrl, {required String label}) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'ر.س',
        isDense: true,
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _resultCard(EosResult r) {
    final fmt = NumberFormat('#,##0', 'ar_SA');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bi(context, ar: 'المجموع التقديري', en: 'Estimated total'),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmt.format(r.totalSar),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 36,
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text('ر.س',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    )),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                onPressed: _share,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${bi(context, ar: 'سنوات الخدمة', en: 'Service years')}: ${r.serviceYears.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _breakdownCard(EosResult r) {
    final fmt = NumberFormat('#,##0', 'ar_SA');
    String tierLabel() {
      switch (r.resignationTier) {
        case ResignationTier.none:
          return _reason == EndReason.resignation
              ? bi(context, ar: 'لا يستحق (< سنتين)', en: 'No entitlement (<2y)')
              : bi(context, ar: 'إنهاء عقد', en: 'Termination');
        case ResignationTier.oneThird:
          return bi(context, ar: 'ثلث المكافأة (2–5 سنوات)', en: '1/3 tier (2–5y)');
        case ResignationTier.twoThirds:
          return bi(context, ar: 'ثلثا المكافأة (5–10 سنوات)', en: '2/3 tier (5–10y)');
        case ResignationTier.full:
          return bi(context, ar: 'كامل المكافأة (10+ سنوات)', en: 'Full (10y+)');
      }
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bi(context, ar: 'التفاصيل', en: 'Breakdown'),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          InfoTile(
              icon: Icons.calculate_outlined,
              label: bi(context, ar: 'الأجر الشهري المعتمد', en: 'Monthly wage'),
              value: '${fmt.format(r.monthlyWage)} ر.س'),
          Divider(height: 1, color: AppColors.border),
          InfoTile(
              icon: Icons.timeline_rounded,
              label: bi(context,
                  ar: 'السنوات الـ ٥ الأولى', en: 'First 5 years'),
              value: '${fmt.format(r.firstTierAmount)} ر.س'),
          Divider(height: 1, color: AppColors.border),
          InfoTile(
              icon: Icons.trending_up_rounded,
              label: bi(context,
                  ar: 'بعد ٥ سنوات', en: 'Years 6+'),
              value: '${fmt.format(r.secondTierAmount)} ر.س'),
          Divider(height: 1, color: AppColors.border),
          InfoTile(
              icon: Icons.gavel_rounded,
              label: bi(context, ar: 'حالة الانتهاء', en: 'End condition'),
              value: tierLabel()),
        ],
      ),
    );
  }
}
