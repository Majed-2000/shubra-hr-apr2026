import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'DioClient.dart';
import 'l10n/app_localizations.dart';
import 'theme.dart';
import 'widgets.dart';

class empRateMgr extends StatefulWidget {
  @override
  _empRateMgr createState() => _empRateMgr();
}

class _empRateMgr extends State<empRateMgr> {
  final ScrollController _scrollController = ScrollController();
  final dioClient = DioClient().client;
  List<dynamic> quarter = [];
  List<dynamic> quarter2 = [];
  String selected = "";
  String grddm = "";
  num grdhr = 0;
  String grdgm = "";
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _employeeIdController = TextEditingController();
  bool _searched = false;

  Future<void> getemprate(String t) async {
    try {
      final response = await dioClient.post('/mgr/getempratevalues',
          data: {'seqno': t, "emcd": _employeeIdController.text});
      var data = response.data;
      setState(() {
        grdgm = data['gm'].toString();
        final hrValue = data['hr'];
        final hrNum = (hrValue != null)
            ? (hrValue is num
                ? hrValue
                : num.tryParse(hrValue.toString()) ?? 0)
            : 0;
        grdhr = 50 - hrNum;
        grddm = data['dm'].toString();
      });
    } catch (e) {
      if (e is DioException) {
        print('Upload failed: ${e.response?.data}');
      } else {
        print('Unexpected error: $e');
      }
    }
  }

  Future<void> _fetchData() async {
    try {
      final response = await dioClient.post('/mgr/getemprate',
          data: {"empcode": _employeeIdController.text});
      var data = response.data;
      setState(() {
        quarter = data["grd"];
        _searched = true;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _employeeIdController.dispose();
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
      subtitle: bi(context,
          ar: "تقييم أداء الموظفين", en: "Employee performance"),
      leadingIcon: Icons.star_rate_rounded,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    LabeledField(
                      label: t.empcode,
                      controller: _employeeIdController,
                      icon: Icons.badge_outlined,
                      hint: t.empcode,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? t.enterempcode : null,
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: bi(context, ar: "بحث", en: "Search"),
                      icon: Icons.search_rounded,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            grdgm = "";
                            grddm = "";
                            grdhr = 0;
                          });
                          _fetchData();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_searched && quarter.isNotEmpty)
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
                          items:
                              quarter.map<DropdownMenuItem<String>>((item) {
                            return DropdownMenuItem<String>(
                              value: item['seqno'].toString(),
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
                          onChanged: (value) =>
                              getemprate(value!.toString()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (grdgm.isNotEmpty) ...[
              const SizedBox(height: 14),
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.pop,
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            totalScore.toString(),
                            style: const TextStyle(
                              color: Colors.white,
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
              GlassCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 6),
                child: Column(
                  children: [
                    InfoTile(
                        icon: Icons.trending_up_rounded,
                        label: t.grdgm,
                        value: grdgm),
                    const Divider(height: 1, color: AppColors.border),
                    InfoTile(
                        icon: Icons.star_outline_rounded,
                        label: t.grdmdm,
                        value: grddm),
                    const Divider(height: 1, color: AppColors.border),
                    InfoTile(
                        icon: Icons.schedule_rounded,
                        label: t.grdhr,
                        value: grdhr.toString()),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
