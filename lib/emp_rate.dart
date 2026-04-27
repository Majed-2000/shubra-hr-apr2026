import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'shared/utils/logger.dart';
import 'theme.dart';
import 'widgets.dart';

/// Employee-facing performance rating screen — view scores by quarter.
class EmpRate extends StatefulWidget {
  @override
  _EmpRateState createState() => _EmpRateState();
}

class _EmpRateState extends State<EmpRate> {
  final ScrollController _scrollController = ScrollController();
  final dioClient = DioClient().client;
  List<dynamic> quarter = [];
  List<dynamic> quarter2 = [];
  String selected = "";
  String grddm = "";
  num grdhr = 0;
  String grdgm = "";

  @override
  void initState() {
    super.initState();
    getLeavetype();
  }

  Future<void> getLeavetype() async {
    try {
      final response = await dioClient.post('/getquarter');
      var data = response.data;
      setState(() {
        quarter = data["grddm"];
      });
    } catch (_) {}
  }

  Future<void> getemprate(String t) async {
    try {
      final response =
          await dioClient.post('/getemprate', data: {'seqno': t});
      var data = response.data;
      setState(() {
        grdgm = data['gm'].toString();
        final hrVal = num.parse(data['hr']);
        grdhr = hrVal > 50 ? 0 : 50 - hrVal;
        grddm = data['dm'].toString();
      });
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
    if (quarter2.isEmpty) {
      quarter2.add(t.first);
      quarter2.add(t.second);
      quarter2.add(t.third);
      quarter2.add(t.fourth);
    }
    final totalScore =
        ((num.tryParse(grdgm) ?? 0) + grdhr + (num.tryParse(grddm) ?? 0));

    return ModernScaffold(
      title: t.rate,
      subtitle: bi(context, ar: "تقييم الأداء", en: "Performance rating"),
      leadingIcon: Icons.star_rate_rounded,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quarter selector
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bi(context, ar: "اختر الفترة", en: "Select period"),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        hint: Text(t.year),
                        isExpanded: true,
                        icon: const Icon(Icons.expand_more_rounded,
                            color: AppColors.muted),
                        items: quarter.map<DropdownMenuItem<String>>((item) {
                          return DropdownMenuItem<String>(
                            value: item['seqno'],
                            child: Text(
                              quarter2[int.parse(item['elvtyp']) - 1] +
                                  " " +
                                  item['frmdat'] +
                                  " — " +
                                  item['todat'],
                              style: const TextStyle(
                                color: AppColors.onSurface,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          selected = value!;
                          for (var ti in quarter) {
                            if (ti['seqno'] == value) getemprate(selected);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Total score card
            if (grdgm.isNotEmpty)
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            totalScore.toString(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            "/ 100",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      bi(context,
                          ar: "إجمالي التقييم", en: "Total score"),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),

            // Score breakdown
            GlassCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 6),
              child: Column(
                children: [
                  InfoTile(
                      icon: Icons.trending_up_rounded,
                      label: t.grdgm,
                      value: grdgm.isEmpty ? '—' : grdgm),
                  const Divider(height: 1, color: AppColors.border),
                  InfoTile(
                      icon: Icons.star_outline_rounded,
                      label: t.grdmdm,
                      value: grddm.isEmpty ? '—' : grddm),
                  const Divider(height: 1, color: AppColors.border),
                  InfoTile(
                      icon: Icons.schedule_rounded,
                      label: t.grdhr,
                      value: grdhr.toString()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
