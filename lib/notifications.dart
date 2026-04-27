import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'noti.dart';
import 'shared/mixins/infinite_scroll_mixin.dart';
import 'shared/utils/logger.dart';
import 'shared/widgets/paginated_list_view.dart';
import 'theme.dart';
import 'widgets.dart';

/// Employee notifications inbox — paginated list of announcements pushed
/// to the current user.
class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications>
    with InfiniteScrollMixin<Notifications> {
  final dioClient = DioClient().client;

  final List<noti> _notifications = [];
  bool _isLoading = false;
  bool _stop = false;
  int _page = 0;

  @override
  bool get hasMore => !_stop;

  @override
  bool get isLoading => _isLoading;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  Future<void> onLoadMore() => _fetchData();

  Future<void> _fetchData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      _page++;
      final response = await dioClient.get('/getnotifications?page=$_page');
      final data = response.data;
      final List<dynamic> rows = data['data'] ?? [];
      if (rows.isEmpty) {
        if (mounted) setState(() => _stop = true);
        return;
      }
      if (!mounted) return;
      setState(() {
        for (final x in rows) {
          _notifications.add(noti()
            ..name = x['title']
            ..date = x['ndate'] ?? ''
            ..msg = x['msg']);
        }
      });
    } catch (e) {
      logD('Error fetching notifications: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _notifications.clear();
      _stop = false;
      _page = 0;
    });
    await _fetchData();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      return DateFormat('MMM dd, yyyy • hh:mm a')
          .format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ModernScaffold(
      title: t.notifications,
      subtitle: bi(context, ar: "آخر التحديثات", en: "Your latest updates"),
      leadingIcon: Icons.notifications_active_rounded,
      body: PaginatedListView<noti>(
        items: _notifications,
        isLoading: _isLoading,
        controller: scrollController,
        onRefresh: _refresh,
        emptyState: EmptyState(
          icon: Icons.notifications_off_rounded,
          title: t.nodata,
          subtitle: bi(context,
              ar: "لا توجد إشعارات جديدة", en: "You're all caught up!"),
          accent: AppColors.secondary,
        ),
        itemBuilder: (context, item, _) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _NotificationCard(
            item: item,
            formattedDate: _formatDate(item.date),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final noti item;
  final String formattedDate;
  const _NotificationCard({required this.item, required this.formattedDate});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.18),
                  AppColors.secondary.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.onSurface,
                  ),
                ),
                if (item.msg != null && item.msg!.isNotEmpty) ...[
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
                        size: 13, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
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
    );
  }
}
