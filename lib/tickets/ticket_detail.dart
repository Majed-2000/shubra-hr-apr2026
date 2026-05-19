// ============================================================================
// File: tickets/ticket_detail.dart
// Purpose: Conversation view for a single HR ticket (feature 10). Chat
//          bubbles + composer.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme.dart';
import '../widgets.dart';
import 'ticket_models.dart';
import 'ticket_service.dart';

class TicketDetail extends StatefulWidget {
  const TicketDetail({super.key});

  @override
  State<TicketDetail> createState() => _TicketDetailState();
}

class _TicketDetailState extends State<TicketDetail> {
  TicketThread? _thread;
  bool _loading = true;
  bool _sending = false;
  final _composerCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  int? _id;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_id == null) {
      final arg = ModalRoute.of(context)?.settings.arguments;
      _id = arg is int ? arg : null;
      if (_id != null) _load();
    }
  }

  Future<void> _load() async {
    if (_id == null) return;
    setState(() => _loading = true);
    try {
      _thread = await TicketService.thread(_id!);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _composerCtrl.text.trim();
    if (text.isEmpty || _id == null) return;
    setState(() => _sending = true);
    try {
      await TicketService.reply(_id!, text);
      _composerCtrl.clear();
      await _load();
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  @override
  void dispose() {
    _composerCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModernScaffold(
      title: _thread?.subject ??
          bi(context, ar: 'محادثة الدعم', en: 'Support thread'),
      subtitle: _thread == null ? '' : _thread!.category,
      leadingIcon: Icons.forum_outlined,
      body: _loading
          ? const Loader()
          : _thread == null
              ? Center(
                  child: Text(bi(context,
                      ar: 'تذكرة غير موجودة',
                      en: 'Ticket not found')),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        children: [
                          for (final m in _thread!.messages) _bubble(m),
                        ],
                      ),
                    ),
                    _composer(),
                  ],
                ),
    );
  }

  Widget _bubble(TicketMessage m) {
    if (m.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(m.body,
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ),
      );
    }
    final isMe = m.isUser;
    final fmt = DateFormat('HH:mm');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMe ? 14 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 14),
                ),
                border: isMe
                    ? null
                    : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    Text(m.authorName,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        )),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    m.body,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppColors.onSurface,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fmt.format(m.createdAt.toLocal()),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _composer() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _composerCtrl,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: bi(context,
                      ar: 'اكتب ردك...',
                      en: 'Write a reply...'),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.4))
                  : Icon(Icons.send_rounded, color: AppColors.primary),
              onPressed: _sending ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}
