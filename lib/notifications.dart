// ============================================================================
// ملف: notifications.dart
// الغرض: صندوق إشعارات الموظف — قائمة بكل الإعلانات التي وصلته.
// المحتوى: قائمة paginated، يستعمل InfiniteScrollMixin + PaginatedListView.
// API: GET /getMyNotifications?page=N.
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'noti.dart';
import 'shared/mixins/infinite_scroll_mixin.dart';
import 'shared/services/sync_tracker.dart';
import 'shared/utils/logger.dart';
import 'shared/widgets/highlighted_text.dart';
import 'shared/widgets/last_sync_badge.dart';
import 'shared/widgets/paginated_list_view.dart';
import 'theme.dart';
import 'widgets.dart';

/// Employee notifications inbox — paginated list of announcements pushed
/// to the current user.
///
/// صندوق إشعارات الموظف — قائمة الإعلانات الموجّهة له (paginated).
class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications>
    with InfiniteScrollMixin<Notifications> {
  final dioClient = DioClient().client;
  final _searchController = TextEditingController();

  final List<noti> _notifications = [];
  bool _isLoading = false;
  bool _stop = false;
  int _page = 0;
  String _query = '';
  Timer? _debounce;

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
      await SyncTracker.markSynced('notifications');
    } catch (e) {
      logD('Error fetching notifications: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  List<noti> get _filtered {
    if (_query.isEmpty) return _notifications;
    final q = _query.toLowerCase();
    return _notifications.where((n) {
      final inTitle = (n.name ?? '').toLowerCase().contains(q);
      final inBody = (n.msg ?? '').toLowerCase().contains(q);
      return inTitle || inBody;
    }).toList();
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
    final filtered = _filtered;
    final isSearchEmpty = _query.isNotEmpty && filtered.isEmpty && !_isLoading;
    return ModernScaffold(
      title: t.notifications,
      subtitle: bi(context, ar: "آخر التحديثات", en: "Your latest updates"),
      leadingIcon: Icons.notifications_active_rounded,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: bi(context,
                          ar: "ابحث في الإشعارات...",
                          en: "Search notifications..."),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                LastSyncBadge(screenKey: 'notifications', onRefresh: _refresh),
              ],
            ),
          ),
          Expanded(
            child: PaginatedListView<noti>(
              items: filtered,
              isLoading: _isLoading,
              controller: scrollController,
              onRefresh: _refresh,
              emptyState: EmptyState(
                icon: isSearchEmpty
                    ? Icons.search_off_rounded
                    : Icons.notifications_off_rounded,
                title: isSearchEmpty
                    ? bi(context,
                        ar: "لا نتائج للبحث", en: "No matching results")
                    : t.nodata,
                subtitle: isSearchEmpty
                    ? bi(context,
                        ar: "جرّب كلمة مختلفة",
                        en: "Try a different keyword")
                    : bi(context,
                        ar: "لا توجد إشعارات جديدة",
                        en: "You're all caught up!"),
                accent: AppColors.secondary,
              ),
              itemBuilder: (context, item, _) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _NotificationCard(
                  item: item,
                  formattedDate: _formatDate(item.date),
                  query: _query,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final noti item;
  final String formattedDate;
  final String query;
  const _NotificationCard({
    required this.item,
    required this.formattedDate,
    this.query = '',
  });

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
                HighlightedText(
                  text: item.name ?? '',
                  query: query,
                  baseStyle: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 2,
                ),
                if (item.msg != null && item.msg!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  HighlightedText(
                    text: item.msg!,
                    query: query,
                    baseStyle: TextStyle(
                      color: AppColors.muted,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                    maxLines: 4,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 13, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
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
