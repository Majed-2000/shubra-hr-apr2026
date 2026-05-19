// ============================================================================
// File: documents/document_viewer.dart
// Purpose: Open a single document — PDF via syncfusion_flutter_pdfviewer,
//          image via Image.network. Mock fixtures return placeholder content.
// ============================================================================

import 'package:flutter/material.dart';

import '../shared/services/feature_flags.dart';
import '../theme.dart';
import '../widgets.dart';
import 'document_models.dart';

class DocumentViewer extends StatelessWidget {
  const DocumentViewer({super.key});

  @override
  Widget build(BuildContext context) {
    final doc = ModalRoute.of(context)?.settings.arguments as EmployeeDocument?;
    if (doc == null) {
      return Scaffold(
        body: Center(
          child: Text(bi(context, ar: 'مستند غير صالح', en: 'Invalid document')),
        ),
      );
    }

    return ModernScaffold(
      title: doc.title,
      subtitle: doc.mimeType,
      leadingIcon: doc.isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
      body: _buildContent(context, doc),
    );
  }

  Widget _buildContent(BuildContext context, EmployeeDocument doc) {
    final usingMock =
        !FeatureFlags.documentVaultEnabled || FeatureFlags.useMockData;

    if (usingMock) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(doc.isPdf ? Icons.picture_as_pdf : Icons.image,
                  size: 96, color: AppColors.primary.withOpacity(0.6)),
              const SizedBox(height: 16),
              Text(
                doc.title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                bi(context,
                    ar: 'عرض تجريبي — تكامل خادم المستندات قيد التطوير',
                    en: 'Preview only — document backend in progress'),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // Real viewer wired once backend ships /documents/{id}/download.
    // PDF: SfPdfViewer.network(downloadUrl, headers: bearerHeaders)
    // Image: Image.network(downloadUrl, headers: bearerHeaders)
    return Center(
      child: Text(bi(context,
          ar: 'سيتم تفعيل العرض عند جاهزية الـ backend',
          en: 'Viewer will activate when backend is live')),
    );
  }
}
