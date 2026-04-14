import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'DioClient.dart';
import 'Leave.dart';
import 'l10n/app_localizations.dart';
import 'theme.dart';
import 'widgets.dart';

class Leaverequests extends StatefulWidget {
  @override
  _Leaverequests createState() => _Leaverequests();
}

class _Leaverequests extends State<Leaverequests> {
  final ScrollController _scrollController = ScrollController();
  bool stop = false;
  int _page = 0;
  final dioClient = DioClient().client;
  List<Leave> Lrequests = [];

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
          await dioClient.get('/getLeaveRequests?page=' + _page.toString());
      var data = response.data;
      if (data['leaverequests'].length > 0) {
        for (var x = 0; x < data['leaverequests'].length; x++) {
          Leave l = Leave();
          if (data['leaverequests'][x]['status'] == "y" &&
              data['leaverequests'][x]['status'] != null) {
            l.status = AppLocalizations.of(context)!.accepted;
          } else if (data['leaverequests'][x]['status'] == "n") {
            l.status = AppLocalizations.of(context)!.refused;
          } else {
            l.status = AppLocalizations.of(context)!.pending;
          }
          if (data['leaverequests'][x]['addeddays'] != null) {
            l.addeddays = int.parse(data['leaverequests'][x]['addeddays']);
          } else {
            l.addeddays = 0;
          }
          if (data['leaverequests'][x]['nodays'] != null)
            l.nodays = int.parse(data['leaverequests'][x]['nodays']);
          l.notice = data['leaverequests'][x]['notice'];
          l.leavedateto = data['leaverequests'][x]['leave_date_to'];
          l.type = data['leaverequests'][x]['type'];
          l.leavedate = data['leaverequests'][x]['leave_date'];
          l.status_date = data['leaverequests'][x]['status_date'];
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
        print('Upload failed: ${e.response?.data}');
      } else {
        print('Unexpected error: $e');
      }
    }
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
      title: t.leaverequests,
      subtitle: bi(context, ar: "سجل الإجازات", en: "Your leave history"),
      leadingIcon: Icons.event_note_rounded,
      body: Lrequests.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 60),
                EmptyState(
                  icon: Icons.inbox_rounded,
                  title: t.nodata,
                  subtitle: bi(context,
                      ar: "لا توجد طلبات إجازة لعرضها.",
                      en: "No leave requests to display."),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.type ?? '-',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                            if (item.status != null)
                              _badgeFor(context, item.status!),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 8),
                        DetailRow(
                          icon: Icons.flight_takeoff_rounded,
                          label: bi(context, ar: "من", en: "From"),
                          value: item.leavedate ?? '-',
                          color: AppColors.secondary,
                        ),
                        DetailRow(
                          icon: Icons.flight_land_rounded,
                          label: bi(context, ar: "إلى", en: "To"),
                          value: item.leavedateto ?? '-',
                          color: AppColors.secondary,
                        ),
                        DetailRow(
                          icon: Icons.timelapse_rounded,
                          label: t.nodays,
                          value: '${item.nodays ?? 0}',
                          color: AppColors.warning,
                        ),
                        DetailRow(
                          icon: Icons.add_circle_outline_rounded,
                          label: t.addedays,
                          value: '${item.addeddays ?? 0}',
                          color: AppColors.accent,
                        ),
                        if (item.status_date != null) ...[
                          const SizedBox(height: 6),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 8),
                          DetailRow(
                            icon: Icons.event_available_rounded,
                            label: t.statusdate,
                            value: item.status_date!,
                            color: const Color(0xFF8B5CF6),
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
