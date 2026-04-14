import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shubraepp/tloan.dart';

import 'DioClient.dart';
import 'l10n/app_localizations.dart';
import 'theme.dart';
import 'widgets.dart';

class tokenloans extends StatefulWidget {
  @override
  _tokenloans createState() => _tokenloans();
}

class _tokenloans extends State<tokenloans> {
  final ScrollController _scrollController = ScrollController();
  bool stop = false;
  int _page = 0;
  final dioClient = DioClient().client;
  List<tLoan> Lrequests = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
    setState(() => _page++);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        if (!stop) {
          _fetchData();
          setState(() => _page++);
        }
      }
    });
  }

  Future<void> _fetchData() async {
    try {
      final response =
          await dioClient.get('/myloans?page=' + _page.toString());
      var data = response.data;
      if (data['myloans'].length > 0) {
        for (var x = 0; x < data['myloans'].length; x++) {
          tLoan l = tLoan();
          l.code = data['myloans'][x]['seqno'];
          l.amount = data['myloans'][x]['amnt'];
          l.date = data['myloans'][x]['lndt'];
          l.paid = data['myloans'][x]['paid'];
          setState(() => Lrequests.add(l));
        }
      } else {
        setState(() => stop = true);
      }
    } catch (_) {}
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
      title: t.deliveredloan,
      subtitle:
          bi(context, ar: "سلفك المسلّمة", en: "Your delivered loans"),
      leadingIcon: Icons.payments_rounded,
      body: Lrequests.isEmpty
          ? ListView(children: [
              const SizedBox(height: 60),
              EmptyState(
                icon: Icons.savings_outlined,
                title: t.nodata,
                subtitle: bi(context,
                    ar: "لا توجد سلف مسلّمة.",
                    en: "No delivered loans."),
                accent: AppColors.success,
              ),
            ])
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.success.withOpacity(0.12),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              child: const Icon(
                                Icons.payments_rounded,
                                color: AppColors.success,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.amount ?? 0}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${t.date}: ${item.date ?? ''}",
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (item.paid != null && item.paid!.isNotEmpty)
                              StatusBadge(
                                label: item.paid!,
                                color: AppColors.success,
                                icon: Icons.check_circle_rounded,
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 6),
                        DetailRow(
                          icon: Icons.tag_rounded,
                          label: t.code,
                          value: '${item.code ?? ''}',
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
