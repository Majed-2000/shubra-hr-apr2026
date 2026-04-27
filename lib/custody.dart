import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'dio_client.dart';
import 'cust.dart';
import 'l10n/app_localizations.dart';
import 'theme.dart';
import 'widgets.dart';

/// Lists the items currently assigned to the employee with issue dates.
class Custody extends StatefulWidget {
  @override
  _CustodyState createState() => _CustodyState();
}

class _CustodyState extends State<Custody> {
  final ScrollController _scrollController = ScrollController();
  bool stop = false;
  int _page = 0;
  final dioClient = DioClient().client;
  List<cust> Lrequests = [];

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
      final response = await dioClient.get('/custody');
      var data = response.data;
      if (data['cust'].length > 0) {
        for (var x = 0; x < data['cust'].length; x++) {
          cust l = cust();
          l.name = data['cust'][x]['cnnma'];
          l.date = data['cust'][x]['usrdat'];
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
      } else {}
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
      title: t.custody,
      subtitle: bi(context, ar: "العهد المسندة إليك", en: "Assigned custody items"),
      leadingIcon: Icons.dashboard_customize_rounded,
      body: Lrequests.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 60),
                EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: t.nodata,
                  subtitle: bi(context,
                      ar: "لا توجد عهد مسندة إليك.",
                      en: "No custody items assigned to you."),
                  accent: AppColors.warning,
                ),
              ],
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: Lrequests.length,
              itemBuilder: (context, index) {
                final item = Lrequests[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.12),
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.warning,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name ?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded,
                                      size: 13,
                                      color: AppColors.muted),
                                  const SizedBox(width: 5),
                                  Text(
                                    item.date ?? '',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
