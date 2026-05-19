// ============================================================================
// File: shared/services/mock_repo.dart
// Purpose: Centralised mock fixtures for features awaiting backend:
//          documents (feature 9), tickets (feature 10), iqama-bearing
//          profile (feature 16), hire-date profile (feature 8).
// Shapes match the expected backend contracts so the swap-over is mechanical.
// ============================================================================

class MockRepo {
  // ──────────────────────────────────────────────────────────────────
  // Documents (feature 9)
  // ──────────────────────────────────────────────────────────────────
  static List<Map<String, dynamic>> get documents => [
        {
          'id': 1,
          'title': 'عقد العمل',
          'category': 'contract',
          'uploaded_at': '2024-01-15T09:00:00Z',
          'mime_type': 'application/pdf',
          'size_bytes': 245000,
        },
        {
          'id': 2,
          'title': 'صورة الهوية',
          'category': 'identity',
          'uploaded_at': '2024-01-15T09:01:00Z',
          'mime_type': 'image/jpeg',
          'size_bytes': 180000,
        },
        {
          'id': 3,
          'title': 'شهادة الراتب',
          'category': 'certificate',
          'uploaded_at': '2025-12-01T12:00:00Z',
          'mime_type': 'application/pdf',
          'size_bytes': 92000,
        },
        {
          'id': 4,
          'title': 'شهادة التأمين الطبي',
          'category': 'certificate',
          'uploaded_at': '2025-09-10T10:30:00Z',
          'mime_type': 'application/pdf',
          'size_bytes': 64000,
        },
      ];

  // ──────────────────────────────────────────────────────────────────
  // Tickets (feature 10)
  // ──────────────────────────────────────────────────────────────────
  static List<Map<String, dynamic>> get tickets => [
        {
          'id': 101,
          'subject': 'استفسار عن البدلات',
          'category': 'salary_query',
          'status': 'awaiting_user',
          'last_message_preview': 'يرجى مراجعة قسيمة الراتب المرسلة...',
          'last_activity_at': DateTime.now().subtract(const Duration(hours: 2)).toUtc().toIso8601String(),
          'unread_count': 1,
          'priority': 'normal',
        },
        {
          'id': 102,
          'subject': 'مشكلة في تسجيل الدخول',
          'category': 'technical_issue',
          'status': 'closed',
          'last_message_preview': 'تم حل المشكلة. شكراً لتواصلكم.',
          'last_activity_at': DateTime.now().subtract(const Duration(days: 3)).toUtc().toIso8601String(),
          'unread_count': 0,
          'priority': 'normal',
        },
      ];

  static Map<String, dynamic> ticketThread(int id) => {
        'id': id,
        'subject': id == 101 ? 'استفسار عن البدلات' : 'مشكلة في تسجيل الدخول',
        'category': id == 101 ? 'salary_query' : 'technical_issue',
        'status': id == 101 ? 'awaiting_user' : 'closed',
        'created_at': DateTime.now().subtract(const Duration(days: 2)).toUtc().toIso8601String(),
        'messages': [
          {
            'id': 1,
            'author_type': 'user',
            'author_name': 'أنت',
            'body': id == 101
                ? 'أريد فهم تفاصيل بدل السكن في قسيمة هذا الشهر.'
                : 'لا أستطيع تسجيل الدخول بكلمة المرور القديمة.',
            'attachments': [],
            'created_at': DateTime.now().subtract(const Duration(days: 2)).toUtc().toIso8601String(),
          },
          {
            'id': 2,
            'author_type': 'hr',
            'author_name': 'الموارد البشرية',
            'body': id == 101
                ? 'مرحباً، سنراجع القسيمة ونرد عليكم خلال يوم عمل.'
                : 'تم إعادة تعيين كلمة المرور. حاول الآن.',
            'attachments': [],
            'created_at': DateTime.now().subtract(const Duration(days: 1)).toUtc().toIso8601String(),
          },
        ],
      };

  static List<Map<String, dynamic>> get ticketCategories => [
        {'key': 'complaint', 'name_ar': 'شكوى', 'name_en': 'Complaint', 'icon': 'report_problem'},
        {'key': 'salary_query', 'name_ar': 'استفسار راتب', 'name_en': 'Salary Query', 'icon': 'payments'},
        {'key': 'leave_query', 'name_ar': 'استفسار إجازة', 'name_en': 'Leave Query', 'icon': 'event_note'},
        {'key': 'document_request', 'name_ar': 'طلب مستند', 'name_en': 'Document Request', 'icon': 'description'},
        {'key': 'technical_issue', 'name_ar': 'مشكلة تقنية', 'name_en': 'Technical Issue', 'icon': 'bug_report'},
        {'key': 'other', 'name_ar': 'أخرى', 'name_en': 'Other', 'icon': 'help_outline'},
      ];

  // ──────────────────────────────────────────────────────────────────
  // Iqama-bearing profile (feature 16) — supplements /myinfoview when
  // backend hasn't added the iqama fields yet. 14-day mock expiry for QA.
  // ──────────────────────────────────────────────────────────────────
  static Map<String, dynamic> iqamaInfo({int daysFromNow = 14, String nationality = 'IN'}) => {
        'iqama_number': '2123456789',
        'iqama_expiry': DateTime.now().add(Duration(days: daysFromNow)).toUtc().toIso8601String().split('T').first,
        'nationality': nationality, // 'SA' to test Saudi skip path
      };

  // ──────────────────────────────────────────────────────────────────
  // Hire date for EOS calculator (feature 8) — used when /myinfoview lacks it.
  // ──────────────────────────────────────────────────────────────────
  static String get mockHireDate => '2020-03-15';
}
