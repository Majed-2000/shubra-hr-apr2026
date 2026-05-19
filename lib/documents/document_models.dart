// ============================================================================
// File: documents/document_models.dart
// Purpose: Data models for the document vault (feature 9).
// ============================================================================

class EmployeeDocument {
  final int id;
  final String title;
  final String category; // contract, identity, certificate, other
  final DateTime uploadedAt;
  final String mimeType;
  final int sizeBytes;

  const EmployeeDocument({
    required this.id,
    required this.title,
    required this.category,
    required this.uploadedAt,
    required this.mimeType,
    required this.sizeBytes,
  });

  bool get isPdf => mimeType == 'application/pdf';
  bool get isImage => mimeType.startsWith('image/');

  factory EmployeeDocument.fromJson(Map<String, dynamic> j) =>
      EmployeeDocument(
        id: (j['id'] as num).toInt(),
        title: j['title']?.toString() ?? '',
        category: j['category']?.toString() ?? 'other',
        uploadedAt:
            DateTime.tryParse(j['uploaded_at']?.toString() ?? '') ?? DateTime.now(),
        mimeType: j['mime_type']?.toString() ?? 'application/octet-stream',
        sizeBytes: (j['size_bytes'] as num?)?.toInt() ?? 0,
      );
}
