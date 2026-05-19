// ============================================================================
// File: tickets/ticket_models.dart
// Purpose: Data classes for the HR tickets module (feature 10).
// ============================================================================

enum TicketStatus { open, inProgress, awaitingUser, closed }

TicketStatus parseTicketStatus(String s) {
  switch (s) {
    case 'open':
      return TicketStatus.open;
    case 'in_progress':
      return TicketStatus.inProgress;
    case 'awaiting_user':
      return TicketStatus.awaitingUser;
    case 'closed':
      return TicketStatus.closed;
  }
  return TicketStatus.open;
}

class TicketSummary {
  final int id;
  final String subject;
  final String category;
  final TicketStatus status;
  final String lastMessagePreview;
  final DateTime lastActivity;
  final int unreadCount;

  const TicketSummary({
    required this.id,
    required this.subject,
    required this.category,
    required this.status,
    required this.lastMessagePreview,
    required this.lastActivity,
    required this.unreadCount,
  });

  factory TicketSummary.fromJson(Map<String, dynamic> j) => TicketSummary(
        id: (j['id'] as num).toInt(),
        subject: j['subject']?.toString() ?? '',
        category: j['category']?.toString() ?? 'other',
        status: parseTicketStatus(j['status']?.toString() ?? 'open'),
        lastMessagePreview: j['last_message_preview']?.toString() ?? '',
        lastActivity:
            DateTime.tryParse(j['last_activity_at']?.toString() ?? '') ??
                DateTime.now(),
        unreadCount: (j['unread_count'] as num?)?.toInt() ?? 0,
      );
}

class TicketMessage {
  final int id;
  final String authorType; // user, hr, system
  final String authorName;
  final String body;
  final DateTime createdAt;

  const TicketMessage({
    required this.id,
    required this.authorType,
    required this.authorName,
    required this.body,
    required this.createdAt,
  });

  bool get isUser => authorType == 'user';
  bool get isHr => authorType == 'hr';
  bool get isSystem => authorType == 'system';

  factory TicketMessage.fromJson(Map<String, dynamic> j) => TicketMessage(
        id: (j['id'] as num).toInt(),
        authorType: j['author_type']?.toString() ?? 'user',
        authorName: j['author_name']?.toString() ?? '',
        body: j['body']?.toString() ?? '',
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class TicketThread {
  final int id;
  final String subject;
  final String category;
  final TicketStatus status;
  final List<TicketMessage> messages;

  const TicketThread({
    required this.id,
    required this.subject,
    required this.category,
    required this.status,
    required this.messages,
  });

  factory TicketThread.fromJson(Map<String, dynamic> j) => TicketThread(
        id: (j['id'] as num).toInt(),
        subject: j['subject']?.toString() ?? '',
        category: j['category']?.toString() ?? 'other',
        status: parseTicketStatus(j['status']?.toString() ?? 'open'),
        messages: ((j['messages'] as List?) ?? [])
            .map((m) => TicketMessage.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      );
}
