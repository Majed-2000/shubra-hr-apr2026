// ============================================================================
// File: tickets/ticket_service.dart
// Purpose: Bridge for the HR tickets API. Falls back to MockRepo when the
//          feature flag is off — UI ships before backend.
// ============================================================================

import '../dio_client.dart';
import '../shared/services/feature_flags.dart';
import '../shared/services/mock_repo.dart';
import '../shared/utils/logger.dart';
import 'ticket_models.dart';

class TicketService {
  static final _dio = DioClient().client;

  static Future<List<TicketSummary>> list() async {
    if (!FeatureFlags.ticketsEnabled || FeatureFlags.useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      return MockRepo.tickets
          .map((m) => TicketSummary.fromJson(m))
          .toList();
    }
    try {
      final res = await _dio.get('/tickets');
      final list = (res.data['tickets'] as List?) ?? [];
      return list
          .map((m) => TicketSummary.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      logD('TicketService.list failed: $e');
      rethrow;
    }
  }

  static Future<TicketThread> thread(int id) async {
    if (!FeatureFlags.ticketsEnabled || FeatureFlags.useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      return TicketThread.fromJson(MockRepo.ticketThread(id));
    }
    try {
      final res = await _dio.get('/tickets/$id');
      return TicketThread.fromJson(Map<String, dynamic>.from(res.data));
    } catch (e) {
      logD('TicketService.thread failed: $e');
      rethrow;
    }
  }

  static Future<void> reply(int id, String body) async {
    if (!FeatureFlags.ticketsEnabled || FeatureFlags.useMockData) {
      await Future.delayed(const Duration(milliseconds: 150));
      return;
    }
    try {
      await _dio.post('/tickets/$id/messages', data: {'body': body});
    } catch (e) {
      logD('TicketService.reply failed: $e');
      rethrow;
    }
  }

  static Future<int> create({
    required String subject,
    required String category,
    required String body,
  }) async {
    if (!FeatureFlags.ticketsEnabled || FeatureFlags.useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      return DateTime.now().millisecondsSinceEpoch;
    }
    try {
      final res = await _dio.post('/tickets', data: {
        'subject': subject,
        'category': category,
        'body': body,
      });
      return (res.data['ticket_id'] as num).toInt();
    } catch (e) {
      logD('TicketService.create failed: $e');
      rethrow;
    }
  }
}
