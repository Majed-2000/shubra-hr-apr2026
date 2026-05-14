// ============================================================================
// ملف: request_loan.dart
// الغرض: نموذج طلب قرض/سلفة من الشركة.
// الحقول: المبلغ + سبب الطلب + مرفق اختياري (صورة).
// API: POST /submitLoan (FormData لرفع المرفق).
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'shared/utils/snackbar.dart';
import 'theme.dart';
import 'widgets.dart';

/// Loan-request form: amount, justification text, and optional attachment.
///
/// نموذج طلب قرض: مبلغ + سبب + مرفق اختياري.
class RequestLoan extends StatefulWidget {
  @override
  _RequestLoanState createState() => _RequestLoanState();
}

class _RequestLoanState extends State<RequestLoan> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _notice = TextEditingController();
  final dioClient = DioClient().client;
  XFile? attach;
  bool _sending = false;

  @override
  void dispose() {
    _amount.dispose();
    _notice.dispose();
    super.dispose();
  }

  void _snack(String m) => SnackbarHelpers.show(context, m);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      FormData formData = FormData.fromMap({
        'amount': _amount.text,
        'notice': _notice.text,
      });
      final response =
          await dioClient.post('/submitLoan', data: formData);
      if (response.statusCode == 201) {
        _amount.clear();
        _notice.clear();
        _snack(AppLocalizations.of(context)!.sent);
      }
    } catch (e) {
      _snack(AppLocalizations.of(context)!.notsent);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ModernScaffold(
      title: t.requestloan,
      subtitle: bi(context, ar: "تقديم طلب سلفة جديدة", en: "Apply for a new loan"),
      leadingIcon: Icons.request_quote_outlined,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Highlight amount input
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.success.withOpacity(0.10),
                        AppColors.success.withOpacity(0.03),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color: AppColors.success.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.18),
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(Icons.payments_rounded,
                            color: AppColors.success, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.amount,
                              style: TextStyle(
                                  color: AppColors.muted, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _amount,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSurface,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                                hintText: "0.00",
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? t.enteramount : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                LabeledField(
                  label: t.notes,
                  controller: _notice,
                  icon: Icons.notes_rounded,
                  hint: t.notes,
                  maxLines: 5,
                  validator: (v) =>
                      v == null || v.isEmpty ? t.enternote : null,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: t.send,
                  icon: Icons.send_rounded,
                  loading: _sending,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
