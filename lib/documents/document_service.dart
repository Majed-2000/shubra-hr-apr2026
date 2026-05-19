// ============================================================================
// File: documents/document_service.dart
// Purpose: Backend bridge for the document vault. Returns mocks when the
//          feature flag is off (default) so the UI ships before backend.
// ============================================================================

import 'package:dio/dio.dart';

import '../dio_client.dart';
import '../shared/services/feature_flags.dart';
import '../shared/services/mock_repo.dart';
import '../shared/utils/logger.dart';
import 'document_models.dart';

class DocumentService {
  static final _dio = DioClient().client;

  static Future<List<EmployeeDocument>> list() async {
    if (!FeatureFlags.documentVaultEnabled || FeatureFlags.useMockData) {
      // Simulate small network latency so UI exercises loading state.
      await Future.delayed(const Duration(milliseconds: 250));
      return MockRepo.documents
          .map((m) => EmployeeDocument.fromJson(m))
          .toList();
    }
    try {
      final res = await _dio.get('/documents');
      final docs = (res.data['documents'] as List?) ?? [];
      return docs
          .map((d) => EmployeeDocument.fromJson(Map<String, dynamic>.from(d)))
          .toList();
    } on DioException catch (e) {
      logD('DocumentService.list failed: $e');
      rethrow;
    }
  }

  /// Returns the download URL for a document. Stream to a temp file at the
  /// call site (path_provider) before opening in the PDF viewer.
  static String downloadUrl(int id) => '/documents/$id/download';
}
