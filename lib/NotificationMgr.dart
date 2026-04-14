import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'DioClient.dart';
import 'noti.dart';
import 'l10n/app_localizations.dart';
import 'theme.dart';
import 'widgets.dart';

class NotificationsMgr extends StatefulWidget {
  @override
  _NotificationsState createState() => _NotificationsState();
}

class _NotificationsState extends State<NotificationsMgr> {
  final ScrollController _scrollController = ScrollController();
  final dioClient = DioClient().client;

  List<noti> notifications = [];
  bool isLoading = false;
  bool stop = false;
  int page = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
    page++;
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !stop &&
          !isLoading) {
        page++;
        _fetchData();
      }
    });
  }

  Future<void> _fetchData() async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      final response = await dioClient
          .get('/mgr/getnotifications?page=' + page.toString());
      final data = response.data;
      if (data['data'].isNotEmpty) {
        setState(() {
          for (var x in data['data']) {
            noti n = noti();
            n.name = x['title'];
            n.date = x['ndate'] ?? '';
            n.msg = x['msg'];
            notifications.add(n);
          }
          page++;
        });
      } else {
        setState(() => stop = true);
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ModernScaffold(
      title: t.notifications,
      subtitle: bi(context, ar: "الإشعارات المرسلة", en: "Sent announcements"),
      leadingIcon: Icons.campaign_rounded,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          notifications.clear();
          stop = false;
          page = 0;
          await _fetchData();
        },
        child: isLoading && notifications.isEmpty
            ? const Loader()
            : notifications.isEmpty
                ? ListView(children: [
                    const SizedBox(height: 60),
                    EmptyState(
                      icon: Icons.notifications_off_rounded,
                      title: t.nodata,
                      subtitle: bi(context,
                          ar: "لا توجد إشعارات حالياً.",
                          en: "No notifications yet."),
                      accent: AppColors.secondary,
                    ),
                  ])
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: notifications.length + (isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == notifications.length && isLoading) {
                        return const Loader();
                      }
                      final item = notifications[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  gradient: AppColors.heroGradient,
                                  borderRadius: BorderRadius.circular(
                                      AppRadius.sm),
                                ),
                                child: const Icon(
                                  Icons.campaign_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                    if (item.msg != null &&
                                        item.msg!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        item.msg!,
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 13.5,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(Icons.schedule_rounded,
                                            size: 13,
                                            color: AppColors.muted),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(item.date),
                                          style: const TextStyle(
                                            fontSize: 11.5,
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
      ),
    );
  }
}
