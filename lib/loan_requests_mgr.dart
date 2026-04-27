import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shubraepp/loan.dart';

import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'shared/utils/logger.dart';
import 'theme.dart';
import 'widgets.dart';

/// Manager queue for approving or refusing employee loan requests.
class LoanrequestsMgr extends StatefulWidget {
  @override
  _LoanrequestsMgrState createState() => _LoanrequestsMgrState();
}

class _LoanrequestsMgrState extends State<LoanrequestsMgr> {
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
          await dioClient.get('/mgr/getLoanRequests?page=' + _page.toString());
      var data = response.data;
      if (data['loanrequests'].length > 0 && Lrequests.isEmpty) {
        for (var x = 0; x < data['loanrequests'].length; x++) {
          Loan l = Loan();
          if (data['loanrequests'][x]['status'] == "y") {
            l.status = AppLocalizations.of(context)!.accepted;
          } else if (data['loanrequests'][x]['status'] == "n") {
            l.status = AppLocalizations.of(context)!.refused;
          } else {
            l.status = AppLocalizations.of(context)!.pending;
          }
          if (data['loanrequests'][x]['amount'] != null)
            l.loanamount = int.parse(data['loanrequests'][x]['amount']);
          l.notice = data['loanrequests'][x]['notice'];
          l.loandate = data['loanrequests'][x]['loan_date'];
          if (data['loanrequests'][x]['status_date'] != null)
            l.status_date = data['loanrequests'][x]['status_date'];
          l.id = data['loanrequests'][x]['id'];
          l.emcd = data['loanrequests'][x]['empcode'];
          l.empname = data['loanrequests'][x]['employee_name'];
          setState(() => Lrequests.add(l));
        }
      } else {
        setState(() => stop = true);
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

  Future<void> _act(Loan r, String status) async {
    try {
      await dioClient
          .post('/mgr/LoanStatus', data: {"id": r.id, "status": status});
      setState(() {
        _page = 0;
        stop = false;
        Lrequests.clear();
      });
      _fetchData();
    } catch (_) {}
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
      subtitle:
          bi(context, ar: "مراجعة طلبات السلف", en: "Review loan requests"),
      leadingIcon: Icons.account_balance_wallet_outlined,
      body: Lrequests.isEmpty
          ? ListView(children: [
              const SizedBox(height: 60),
              EmptyState(
                icon: Icons.savings_outlined,
                title: t.nodata,
                subtitle: bi(context,
                    ar: "لا توجد طلبات سلف للمراجعة.",
                    en: "No loan requests to review."),
                accent: AppColors.success,
              ),
            ])
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: Lrequests.length,
              itemBuilder: (context, index) {
                final r = Lrequests[index];
                final isPending = r.status == t.pending;
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
                                color: AppColors.primary,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                (r.empname ?? '?').isNotEmpty
                                    ? r.empname![0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.empname ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${t.empcode}: ${r.emcd ?? ''}",
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
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
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 8),
                        DetailRow(
                          icon: Icons.payments_rounded,
                          label: t.amount,
                          value: '${r.loanamount ?? 0}',
                          color: AppColors.success,
                        ),
                        DetailRow(
                          icon: Icons.calendar_today_rounded,
                          label: t.date,
                          value: r.loandate ?? '-',
                        ),
                        if (r.notice != null && r.notice!.isNotEmpty)
                          DetailRow(
                            icon: Icons.notes_rounded,
                            label: t.notes,
                            value: r.notice!,
                          ),
                        if (r.status_date != null)
                          DetailRow(
                            icon: Icons.event_available_rounded,
                            label: t.statusdate,
                            value: r.status_date!,
                            color: AppColors.primary,
                          ),
                        if (isPending) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _act(r, "y"),
                                  icon: const Icon(Icons.check_rounded,
                                      size: 18),
                                  label: Text(t.accept),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _act(r, "n"),
                                  icon: const Icon(Icons.close_rounded,
                                      size: 18,
                                      color: AppColors.danger),
                                  label: Text(t.refuse,
                                      style: const TextStyle(
                                          color: AppColors.danger)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: AppColors.danger, width: 1.4),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                            ],
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
