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

/// Employee attendance log — daily fingerprint records with month/year
/// filter and a per-day "View All" dialog showing every punch.
class Attendance extends StatefulWidget {
  const Attendance({super.key});

  @override
  State<Attendance> createState() => _AttendanceState();
}

class _AttendanceState extends State<Attendance> {
  static const Color _checkInColor = Color(0xFF4CAF50);
  static const Color _checkOutColor = Color(0xFFE53935);
  static const Color _missingColor = Color(0xFFFF9800);

  final dioClient = DioClient().client;

  late int _month;
  late int _year;
  bool _isLoading = true;
  List<AttendanceDay> _days = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final response = await dioClient.get(
        '/attendance',
        queryParameters: {'month': _month, 'year': _year},
      );
      final rows = (response.data['attendance'] as List? ?? [])
          .map((j) => AttendanceDay.fromJson(j as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() => _days = rows);
    } on DioException catch (e) {
      logD('Attendance fetch failed: $e');
      if (!mounted) return;
      SnackbarHelpers.showError(
        context,
        parseDioError(e, isArabic: isArabic(context)),
      );
    } catch (e) {
      logD('Attendance unexpected error: $e');
      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ModernScaffold(
      title: t.attendanceLog,
      subtitle: t.attendanceSubtitle,
      leadingIcon: Icons.fingerprint_rounded,
      body: Column(
        children: [
          _buildFilterBar(context, t),
          Expanded(
            child: _isLoading
                ? const SkeletonList()
                : _days.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 60),
                          EmptyState(
                            icon: Icons.event_busy_rounded,
                            title: t.nodata,
                            subtitle: t.noAttendance,
                            accent: _missingColor,
                          ),
                        ],
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _fetch,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: _days.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _DayCard(
                              day: _days[i],
                              onViewAll: () => _showAllRecords(_days[i]),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, AppLocalizations t) {
    final months = List.generate(12, (i) => i + 1);
    final now = DateTime.now();
    final years = List.generate(5, (i) => now.year - i);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _DropdownTile(
              label: t.month,
              value: _month,
              items: months
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(_monthLabel(context, m)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null || v == _month) return;
                setState(() => _month = v);
                _fetch();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _DropdownTile(
              label: t.filterYear,
              value: _year,
              items: years
                  .map((y) => DropdownMenuItem(
                        value: y,
                        child: Text(y.toString()),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null || v == _year) return;
                setState(() => _year = v);
                _fetch();
              },
            ),
          ),
        ],
      ),
    );
  }

  String _monthLabel(BuildContext context, int m) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.MMMM(locale).format(DateTime(2000, m));
  }

  void _showAllRecords(AttendanceDay day) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.list_alt_rounded,
                      color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${t.allRecords} — ${_formatDateLabel(day.date)}",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final r in day.allRecords)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _RecordRow(record: r),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t.cancel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDateLabel(String yyyymmdd) {
    if (yyyymmdd.length != 8) return yyyymmdd;
    try {
      final y = int.parse(yyyymmdd.substring(0, 4));
      final m = int.parse(yyyymmdd.substring(4, 6));
      final d = int.parse(yyyymmdd.substring(6, 8));
      return DateFormat('dd MMM yyyy').format(DateTime(y, m, d));
    } catch (_) {
      return yyyymmdd;
    }
  }
}

class _DayCard extends StatelessWidget {
  final AttendanceDay day;
  final VoidCallback onViewAll;

  const _DayCard({required this.day, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                _AttendanceState._formatDateLabel(day.date),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TimeChip(
                  icon: Icons.login_rounded,
                  label: t.checkIn,
                  value: day.entryTime,
                  fallback: t.noCheckIn,
                  okColor: _AttendanceState._checkInColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TimeChip(
                  icon: Icons.logout_rounded,
                  label: t.checkOut,
                  value: day.exitTime,
                  fallback: t.noCheckOut,
                  okColor: _AttendanceState._checkOutColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: onViewAll,
              icon: const Icon(Icons.expand_more_rounded, size: 18),
              label: Text(t.viewAll),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String fallback;
  final Color okColor;

  const _TimeChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.fallback,
    required this.okColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    final color = hasValue ? okColor : _AttendanceState._missingColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  hasValue ? value! : fallback,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final AttendanceRecord record;
  const _RecordRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final meta = _typeMeta(context, record.type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(meta.icon, color: meta.color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              meta.label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ),
          Text(
            record.time,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: meta.color,
            ),
          ),
        ],
      ),
    );
  }

  _TypeMeta _typeMeta(BuildContext context, String type) {
    final t = AppLocalizations.of(context)!;
    switch (type) {
      case '0':
        return _TypeMeta(
          icon: Icons.login_rounded,
          label: t.checkIn,
          color: _AttendanceState._checkInColor,
        );
      case '1':
        return _TypeMeta(
          icon: Icons.logout_rounded,
          label: t.checkOut,
          color: _AttendanceState._checkOutColor,
        );
      default:
        return _TypeMeta(
          icon: Icons.fingerprint_rounded,
          label: bi(context, ar: 'سجل', en: 'Record'),
          color: AppColors.muted,
        );
    }
  }
}

class _TypeMeta {
  final IconData icon;
  final String label;
  final Color color;
  _TypeMeta({required this.icon, required this.label, required this.color});
}

class _DropdownTile<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownTile({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isDense: true,
              isExpanded: true,
              items: items,
              onChanged: onChanged,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AttendanceDay {
  final String date;
  final String? entryTime;
  final String? exitTime;
  final List<AttendanceRecord> allRecords;

  AttendanceDay({
    required this.date,
    this.entryTime,
    this.exitTime,
    required this.allRecords,
  });

  factory AttendanceDay.fromJson(Map<String, dynamic> json) {
    final raw = (json['all_records'] as List?) ?? const [];
    return AttendanceDay(
      date: json['date']?.toString() ?? '',
      entryTime: json['entry_time']?.toString(),
      exitTime: json['exit_time']?.toString(),
      allRecords: raw
          .map((r) => AttendanceRecord.fromJson(
              Map<String, dynamic>.from(r as Map)))
          .toList(),
    );
  }
}

class AttendanceRecord {
  final String date;
  final String time;
  final String type;

  AttendanceRecord({
    required this.date,
    required this.time,
    required this.type,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      date: json['trns_date']?.toString() ?? '',
      time: json['trns_time']?.toString() ?? '',
      type: json['trns_type']?.toString() ?? '',
    );
  }
}
