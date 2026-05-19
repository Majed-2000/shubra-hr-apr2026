// ============================================================================
// File: documents/documents_vault.dart
// Purpose: Read-only browser for HR-uploaded documents (feature 9).
//          Categorized list; tap → open in viewer.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../shared/utils/logger.dart';
import '../theme.dart';
import '../widgets.dart';
import 'document_models.dart';
import 'document_service.dart';

class DocumentsVault extends StatefulWidget {
  const DocumentsVault({super.key});

  @override
  State<DocumentsVault> createState() => _DocumentsVaultState();
}

class _DocumentsVaultState extends State<DocumentsVault> {
  List<EmployeeDocument> _docs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await DocumentService.list();
      if (!mounted) return;
      setState(() {
        _docs = list;
        _loading = false;
      });
    } catch (e) {
      logD('DocumentsVault load error: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  IconData _categoryIcon(String c) {
    switch (c) {
      case 'contract':
        return Icons.description_outlined;
      case 'identity':
        return Icons.badge_outlined;
      case 'certificate':
        return Icons.workspace_premium_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  String _categoryLabel(String c) {
    switch (c) {
      case 'contract':
        return bi(context, ar: 'العقود', en: 'Contracts');
      case 'identity':
        return bi(context, ar: 'الهويات', en: 'Identity');
      case 'certificate':
        return bi(context, ar: 'الشهادات', en: 'Certificates');
    }
    return bi(context, ar: 'أخرى', en: 'Other');
  }

  String _fmtSize(int bytes) {
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '$bytes B';
  }

  @override
  Widget build(BuildContext context) {
    return ModernScaffold(
      title: bi(context, ar: 'مستنداتي', en: 'My Documents'),
      subtitle: bi(context, ar: 'الوثائق المرفوعة', en: 'HR-uploaded files'),
      leadingIcon: Icons.folder_outlined,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _loading
            ? const SkeletonList()
            : _error != null
                ? ListView(children: [
                    const SizedBox(height: 60),
                    EmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: bi(context,
                          ar: 'تعذّر تحميل المستندات',
                          en: 'Could not load documents'),
                      subtitle: _error,
                    ),
                  ])
                : _docs.isEmpty
                    ? ListView(children: [
                        const SizedBox(height: 60),
                        EmptyState(
                          icon: Icons.folder_off_outlined,
                          title: bi(context,
                              ar: 'لا توجد مستندات',
                              en: 'No documents yet'),
                          subtitle: bi(context,
                              ar: 'تواصل مع الموارد البشرية لرفع وثائقك',
                              en: 'Contact HR to upload your files'),
                        ),
                      ])
                    : _buildGrouped(),
      ),
    );
  }

  Widget _buildGrouped() {
    final groups = <String, List<EmployeeDocument>>{};
    for (final d in _docs) {
      groups.putIfAbsent(d.category, () => []).add(d);
    }
    final keys = groups.keys.toList()..sort();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        for (final k in keys) ...[
          ListSectionTitle(title: _categoryLabel(k)),
          const SizedBox(height: 8),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (int i = 0; i < groups[k]!.length; i++) ...[
                  _docRow(groups[k]![i]),
                  if (i < groups[k]!.length - 1)
                    Divider(height: 1, color: AppColors.border),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _docRow(EmployeeDocument d) {
    final fmt = DateFormat('yyyy/MM/dd');
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/documentViewer', arguments: d),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              alignment: Alignment.center,
              child: Icon(_categoryIcon(d.category),
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                        fontSize: 14,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    '${fmt.format(d.uploadedAt)} • ${_fmtSize(d.sizeBytes)}',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
