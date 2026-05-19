// ============================================================================
// File: tickets/ticket_list.dart
// Purpose: List screen for the HR tickets module (feature 10). Tap → thread.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../shared/utils/logger.dart';
import '../theme.dart';
import '../widgets.dart';
import 'ticket_models.dart';
import 'ticket_service.dart';

class TicketList extends StatefulWidget {
  const TicketList({super.key});

  @override
  State<TicketList> createState() => _TicketListState();
}

class _TicketListState extends State<TicketList> {
  List<TicketSummary> _items = [];
  bool _loading = true;

  static bool _arRegistered = false;

  @override
  void initState() {
    super.initState();
    if (!_arRegistered) {
      timeago.setLocaleMessages('ar', timeago.ArMessages());
      _arRegistered = true;
    }
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await TicketService.list();
    } catch (e) {
      logD('TicketList load failed: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Color _statusColor(TicketStatus s) {
    switch (s) {
      case TicketStatus.open:
        return AppColors.primary;
      case TicketStatus.inProgress:
        return AppColors.warning;
      case TicketStatus.awaitingUser:
        return AppColors.secondary;
      case TicketStatus.closed:
        return AppColors.muted;
    }
  }

  String _statusLabel(TicketStatus s) {
    switch (s) {
      case TicketStatus.open:
        return bi(context, ar: 'مفتوحة', en: 'Open');
      case TicketStatus.inProgress:
        return bi(context, ar: 'قيد المعالجة', en: 'In progress');
      case TicketStatus.awaitingUser:
        return bi(context, ar: 'بانتظار ردك', en: 'Awaiting you');
      case TicketStatus.closed:
        return bi(context, ar: 'مغلقة', en: 'Closed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return ModernScaffold(
      title: bi(context, ar: 'الدعم والشكاوى', en: 'Support & Tickets'),
      subtitle: bi(context, ar: 'تواصلك مع الموارد البشرية', en: 'Your HR threads'),
      leadingIcon: Icons.support_agent_rounded,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_rounded),
          onPressed: () async {
            await Navigator.pushNamed(context, '/newTicket');
            _load();
          },
        ),
      ],
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _loading
            ? const SkeletonList()
            : _items.isEmpty
                ? ListView(children: [
                    const SizedBox(height: 60),
                    EmptyState(
                      icon: Icons.inbox_outlined,
                      title: bi(context,
                          ar: 'لا توجد تذاكر',
                          en: 'No tickets yet'),
                      subtitle: bi(context,
                          ar: 'افتح تذكرة جديدة بالضغط على ➕',
                          en: 'Tap ➕ to open a new ticket'),
                    ),
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (ctx, i) {
                      final t = _items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          onTap: () async {
                            await Navigator.pushNamed(context, '/ticketDetail',
                                arguments: t.id);
                            _load();
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (t.unreadCount > 0)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 6, right: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.subject,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.onSurface,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      t.lastMessagePreview,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _statusColor(t.status)
                                                .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _statusLabel(t.status),
                                            style: TextStyle(
                                              color: _statusColor(t.status),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          timeago.format(t.lastActivity,
                                              locale: isAr ? 'ar' : 'en'),
                                          style: TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 11.5,
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
