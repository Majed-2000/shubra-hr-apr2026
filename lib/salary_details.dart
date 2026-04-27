import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'shared/utils/dio_errors.dart';
import 'shared/utils/logger.dart';
import 'shared/utils/snackbar.dart';
import 'theme.dart';
import 'widgets.dart';

/// Employee salary details — basic, allowances, deductions, and net.
class SalaryDetails extends StatefulWidget {
  const SalaryDetails({super.key});

  @override
  State<SalaryDetails> createState() => _SalaryDetailsState();
}

class _SalaryDetailsState extends State<SalaryDetails> {
  static const Color _netBg = Color(0xFF2E7D32);
  static const Color _allowanceColor = Color(0xFF1565C0);
  static const Color _deductionColor = Color(0xFFC62828);
  static const Color _sectionLabel = Color(0xFF757575);

  final dioClient = DioClient().client;
  final NumberFormat _money = NumberFormat('#,##0.00', 'en');

  bool _isLoading = true;
  double _basic = 0;
  double _totalAllowances = 0;
  double _totalDeductions = 0;
  double _net = 0;
  List<_SalaryRow> _allowances = const [];
  List<_SalaryRow> _deductions = const [];
  bool _hasData = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final response = await dioClient.get('/salarydetails');
      final data = response.data as Map<String, dynamic>;
      _basic = _toDouble(data['basic_salary']);
      _totalAllowances = _toDouble(data['total_allowances']);
      _totalDeductions = _toDouble(data['total_deductions']);
      _net = _toDouble(data['net_salary']);
      _allowances = ((data['allowances'] as List?) ?? const [])
          .map((e) => _SalaryRow.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _deductions = ((data['deductions'] as List?) ?? const [])
          .map((e) => _SalaryRow.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _hasData = true;
    } on DioException catch (e) {
      logD('Salary fetch failed: $e');
      if (!mounted) return;
      _hasData = false;
      SnackbarHelpers.showError(
        context,
        parseDioError(e, isArabic: isArabic(context)),
      );
    } catch (e) {
      logD('Salary unexpected error: $e');
      if (!mounted) return;
      _hasData = false;
      SnackbarHelpers.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static double _toDouble(Object? v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  String _fmt(double v) =>
      'SAR ${_money.format(v)}';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ModernScaffold(
      title: t.salaryDetails,
      subtitle: t.salarySubtitle,
      leadingIcon: Icons.payments_rounded,
      body: _isLoading
          ? const Loader()
          : !_hasData
              ? ListView(
                  children: [
                    const SizedBox(height: 60),
                    EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: t.nodata,
                      subtitle: t.noSalaryData,
                    ),
                  ],
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _fetch,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _buildNetCard(t),
                      const SizedBox(height: 14),
                      _buildBasicCard(t),
                      const SizedBox(height: 14),
                      _buildLineItemsCard(
                        title: t.allowances,
                        rows: _allowances,
                        valueColor: _allowanceColor,
                        totalLabel: t.totalAllowances,
                        totalValue: _totalAllowances,
                      ),
                      const SizedBox(height: 14),
                      _buildLineItemsCard(
                        title: t.deductions,
                        rows: _deductions,
                        valueColor: _deductionColor,
                        totalLabel: t.totalDeductions,
                        totalValue: _totalDeductions,
                      ),
                      const SizedBox(height: 14),
                      _buildSummaryRow(t),
                    ],
                  ),
                ),
    );
  }

  Widget _buildNetCard(AppLocalizations t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: _netBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                t.netSalary,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _fmt(_net),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicCard(AppLocalizations t) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.work_outline_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.basicsal,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ),
          Text(
            _fmt(_basic),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItemsCard({
    required String title,
    required List<_SalaryRow> rows,
    required Color valueColor,
    required String totalLabel,
    required double totalValue,
  }) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _sectionLabel,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                '—',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                ),
              ),
            )
          else
            for (int i = 0; i < rows.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        rows[i].name,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _fmt(rows[i].value),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: valueColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          if (rows.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      totalLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    _fmt(totalValue),
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: valueColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _netBg.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: _netBg.withOpacity(0.30), width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              t.total,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
          ),
          Text(
            _fmt(_net),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: _netBg,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalaryRow {
  final String name;
  final double value;

  _SalaryRow({required this.name, required this.value});

  factory _SalaryRow.fromJson(Map<String, dynamic> json) {
    final raw = json['value'];
    final v = raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 0;
    return _SalaryRow(
      name: (json['name']?.toString() ?? '').trim(),
      value: v,
    );
  }
}
