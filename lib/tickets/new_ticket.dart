// ============================================================================
// File: tickets/new_ticket.dart
// Purpose: Compose a new HR ticket (feature 10) with category picker.
// ============================================================================

import 'package:flutter/material.dart';

import '../shared/services/mock_repo.dart';
import '../shared/utils/snackbar.dart';
import '../theme.dart';
import '../widgets.dart';
import 'ticket_service.dart';

class NewTicket extends StatefulWidget {
  const NewTicket({super.key});

  @override
  State<NewTicket> createState() => _NewTicketState();
}

class _NewTicketState extends State<NewTicket> {
  String _category = 'other';
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_subjectCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      SnackbarHelpers.showError(context,
          bi(context, ar: 'يرجى تعبئة كل الحقول', en: 'Please fill all fields'));
      return;
    }
    setState(() => _sending = true);
    try {
      await TicketService.create(
        subject: _subjectCtrl.text.trim(),
        category: _category,
        body: _bodyCtrl.text.trim(),
      );
      if (!mounted) return;
      SnackbarHelpers.showSuccess(context,
          bi(context, ar: 'تم إرسال التذكرة', en: 'Ticket created'));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      SnackbarHelpers.showError(context, e.toString());
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final cats = MockRepo.ticketCategories;
    return ModernScaffold(
      title: bi(context, ar: 'تذكرة جديدة', en: 'New ticket'),
      leadingIcon: Icons.edit_note_rounded,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(bi(context, ar: 'التصنيف', en: 'Category'),
              style: TextStyle(
                  color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in cats)
                ChoiceChip(
                  label: Text(
                      bi(context, ar: c['name_ar'], en: c['name_en'])),
                  selected: _category == c['key'],
                  onSelected: (_) => setState(() => _category = c['key']),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _subjectCtrl,
            decoration: InputDecoration(
              labelText: bi(context, ar: 'الموضوع', en: 'Subject'),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtrl,
            minLines: 5,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: bi(context, ar: 'وصف المشكلة', en: 'Description'),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: bi(context, ar: 'إرسال', en: 'Send'),
            icon: Icons.send_rounded,
            loading: _sending,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
