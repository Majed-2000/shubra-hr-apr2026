import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shubraepp/loan.dart';

import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'theme.dart';
import 'widgets.dart';

/// Alternative loan history view (currently not wired into the routing
/// table, kept for future reuse).
class MyLoans extends StatefulWidget {
  @override
  _MyLoansState createState() => _MyLoansState();
}

class _MyLoansState extends State<MyLoans> {
  final ScrollController _scrollController = ScrollController();
  bool stop = false;
  int _page = 0;
  final dioClient = DioClient().client;
  List<Loan> Lrequests = [];

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
          await dioClient.get('/myPrevloans?page=' + _page.toString());
      var data = response.data;
      if (data['lr'].length > 0) {
        for (var x = 0; x < data['lr'].length; x++) {
          Loan l = Loan();
          final t = AppLocalizations.of(context)!;
          if (data['lr'][x]['status'] == "y") {
            l.status = t.accepted;
          } else if (data['lr'][x]['status'] == "n") {
            l.status = t.refused;
          } else {
            l.status = t.pending;
          }
          if (data['lr'][x]['amount'] != null)
            l.loanamount = int.parse(data['lr'][x]['amount']);
          l.notice = data['lr'][x]['notice'];
          l.loandate = data['lr'][x]['loan_date'];
          if (data['lr'][x]['status_date'] != null)
            l.status_date = data['lr'][x]['status_date'];
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

  StatusBadge _badgeFor(BuildContext context, String status) {
    final t = AppLocalizations.of(context)!;
    if (status == t.accepted) return StatusBadge.accepted(status);
    if (status == t.refused) return StatusBadge.refused(status);
    return StatusBadge.pending(status);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ModernScaffold(
      title: t.loanrequests,
      subtitle: bi(context, ar: "سجل السلف", en: "Loan history"),
      leadingIcon: Icons.account_balance_wallet_outlined,
      body: Lrequests.isEmpty
          ? EmptyState(
              icon: Icons.savings_outlined,
              title: t.nodata,
              subtitle: bi(context,
                  ar: "لا توجد سلف لعرضها.", en: "No loans to display."),
              accent: AppColors.success,
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: Lrequests.length,
              itemBuilder: (context, index) {
                final r = Lrequests[index];
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
                              width: 44,
                              height: 44,
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
                                    "${r.loanamount ?? 0}",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    r.loandate ?? '',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (r.status != null)
                              _badgeFor(context, r.status!),
                          ],
                        ),
                        if (r.status_date != null) ...[
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 6),
                          DetailRow(
                            icon: Icons.event_available_rounded,
                            label: t.statusdate,
                            value: r.status_date!,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
