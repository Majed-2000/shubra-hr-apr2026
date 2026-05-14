// ============================================================================
// ملف: emp_move.dart
// الغرض: شاشة "حركات المرتب" — الغيابات، الخصومات، البدلات، الاستقطاعات.
// المحتوى: قائمة بالحركات المالية المؤثرة على الراتب مع ألوان تصنيفية:
//   - أحمر: غياب / جزاءات / خصومات.
//   - برتقالي: تأخير / انصراف مبكر.
//   - أخضر: استحقاقات (بدلات إضافية).
// API: GET /getmoves?page=N.
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'moves.dart';
import 'shared/utils/logger.dart';
import 'theme.dart';
import 'widgets.dart';

/// Salary moves screen — absences, deductions, allowances and other
/// adjustments affecting the employee's payroll.
///
/// شاشة حركات المرتب — كل ما يؤثر على راتب الموظف هذا الشهر.
class EmpMove extends StatefulWidget {
  @override
  _EmpMoveState createState() => _EmpMoveState();
}

class _EmpMoveState extends State<EmpMove> {
  final ScrollController _scrollController = ScrollController();
  bool stop = false;
  int _page = 0;
  // قاموس أنواع الحركات: كود الحركة (من الـ backend) → اسمها بالعربية.
  // Oracle PYMOVE.MVCD يستعمل هذه الأكواد.
  final Map<int, String> mov = {
    10: 'غياب',
    19: 'عدم بصمة',
    20: 'تأخير',
    18: 'انصراف مبكر',
    13: 'جزائات',
    12: 'عجز مبيعات',
    14: 'استحقاقات اخري',
    15: 'استقطاعات اخري',
    22: 'جزائات اللائحة',
  };
  final Map<int, Color> movColor = {
    10: AppColors.danger,
    19: AppColors.danger,
    20: AppColors.warning,
    18: AppColors.warning,
    13: AppColors.danger,
    12: AppColors.danger,
    14: AppColors.success,
    15: AppColors.danger,
    22: AppColors.danger,
  };
  final Map<int, IconData> movIcon = {
    10: Icons.person_off_rounded,
    19: Icons.fingerprint_rounded,
    20: Icons.schedule_rounded,
    18: Icons.logout_rounded,
    13: Icons.gavel_rounded,
    12: Icons.trending_down_rounded,
    14: Icons.trending_up_rounded,
    15: Icons.remove_circle_outline_rounded,
    22: Icons.rule_rounded,
  };

  final dioClient = DioClient().client;
  List<Moves> Lrequests = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
    setState(() {
      _page = _page + 1;
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        if (stop != true) {
          _fetchData();
          setState(() {
            _page = _page + 1;
          });
        }
      }
    });
  }

  Future<void> _fetchData() async {
    try {
      final response =
          await dioClient.get('/showempmov?page=' + _page.toString());
      var data = response.data;
      if (data['empmove'].length > 0) {
        for (var x = 0; x < data['empmove'].length; x++) {
          Moves l = Moves();
          l.name = data['empmove'][x]['mvcd'];
          l.amount = data['empmove'][x]['amt'];
          var rawDate = data['empmove'][x]['mvdt'];
          String formattedDate =
              "${rawDate.substring(6, 8)}/${rawDate.substring(4, 6)}/${rawDate.substring(0, 4)}";
          l.date = formattedDate;
          l.code = data['empmove'][x]['seqno'];
          setState(() {
            Lrequests.add(l);
          });
        }
      } else {
        setState(() {
          stop = true;
        });
      }
    } catch (e) {
      if (e is DioException) {
        logD('Upload failed: ${e.response?.data}');
      } else {
        logD('Unexpected error: $e');
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ModernScaffold(
      title: t.moves,
      subtitle: bi(context, ar: "نشاط الحضور", en: "Your attendance activity"),
      leadingIcon: Icons.compare_arrows_rounded,
      body: Lrequests.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 60),
                EmptyState(
                  icon: Icons.insights_rounded,
                  title: t.nodata,
                  subtitle: bi(context,
                      ar: "لا يوجد نشاط مسجّل حتى الآن.",
                      en: "No activity recorded yet."),
                  accent: AppColors.primary,
                ),
              ],
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: Lrequests.length,
              itemBuilder: (context, index) {
                final request = Lrequests[index];
                final key = int.tryParse(request.name ?? '');
                final movType = mov[key] ?? '-';
                final color = movColor[key] ?? AppColors.secondary;
                final icon = movIcon[key] ?? Icons.event_note_rounded;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movType,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded,
                                      size: 12, color: AppColors.muted),
                                  const SizedBox(width: 4),
                                  Text(
                                    request.date ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (request.amount != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: color.withOpacity(0.35), width: 1),
                            ),
                            child: Text(
                              "${request.amount} ${t.riyal}",
                              style: TextStyle(
                                fontSize: 12.5,
                                color: color,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
