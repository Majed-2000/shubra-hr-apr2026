import 'dart:async';
import 'package:dio/dio.dart' show DioException, Options;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'shared/utils/dio_errors.dart';
import 'shared/utils/logger.dart';
import 'shared/utils/snackbar.dart';
import 'theme.dart';
import 'widgets.dart';

/// Form for updating the employee's contact email and mobile number.
///
/// Flow:
///   1. User submits a new email + mobile.
///   2. Backend sends an email OTP to the new address and an SMS OTP to the
///      new number, returning a short-lived `request_id`.
///   3. User enters both codes in two sequential modals.
///   4. Backend validates both atomically and writes to Oracle directly —
///      no admin review.
///
/// The old `/updateInfo` route is intentionally not called here. Older
/// App Store builds still use that route; backend keeps it alive for them.
class UpdateInfo extends StatefulWidget {
  @override
  _UpdateInfoState createState() => _UpdateInfoState();
}

class _UpdateInfoState extends State<UpdateInfo> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _mobile = TextEditingController();
  final dioClient = DioClient().client;
  bool _sending = false;

  void _snack(String msg) => SnackbarHelpers.show(context, msg);

  /// Step 1: ask backend to send OTPs to the new email AND new mobile.
  /// Returns the `request_id` on success, null on failure (snack already shown).
  Future<String?> _requestOtps() async {
    try {
      final response = await dioClient.post(
        '/updateInfo/request',
        data: {'email': _email.text, 'mobile': _mobile.text},
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      final data = response.data;
      final code = response.statusCode ?? 0;
      if (code == 200 && data is Map && data['status'] == 'success') {
        final id = data['request_id']?.toString();
        if (id != null && id.isNotEmpty) return id;
      }
      logD('updateInfo /request failed: $code body=$data');
      _snack(_friendlyError(code, data, isOtpStep: false));
    } on DioException catch (e) {
      logD('updateInfo /request dio: ${e.message} body=${e.response?.data}');
      if (mounted) _snack(parseDioError(e, isArabic: isArabic(context)));
    } catch (e) {
      logD('updateInfo /request unexpected: $e');
      if (mounted) _snack(AppLocalizations.of(context)!.nodata);
    }
    return null;
  }

  /// Re-send a single OTP (email or mobile) under the same request_id.
  /// `type` is "email" or "mobile".
  Future<void> _resendOtp(String requestId, String type) async {
    try {
      final response = await dioClient.post(
        '/updateInfo/resend',
        data: {'request_id': requestId, 'type': type},
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      final code = response.statusCode ?? 0;
      if (code != 200) {
        logD('updateInfo /resend ($type) failed: $code body=${response.data}');
        if (mounted) _snack(_friendlyError(code, response.data, isOtpStep: false));
      }
    } on DioException catch (e) {
      logD('updateInfo /resend ($type) dio: ${e.message}');
      if (mounted) _snack(parseDioError(e, isArabic: isArabic(context)));
    } catch (e) {
      logD('updateInfo /resend ($type) unexpected: $e');
    }
  }

  /// Step 3: submit both OTPs together. Backend validates and writes to
  /// Oracle if both pass. Returns true on success.
  Future<bool> _verifyOtps({
    required String requestId,
    required String emailOtp,
    required String phoneOtp,
  }) async {
    try {
      final response = await dioClient.post(
        '/updateInfo/verify',
        data: {
          'request_id': requestId,
          'email_otp': emailOtp,
          'phone_otp': phoneOtp,
        },
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      final data = response.data;
      final code = response.statusCode ?? 0;
      if (code == 200 && data is Map && data['status'] == 'success') {
        return true;
      }
      logD('updateInfo /verify failed: $code body=$data');
      if (mounted) _snack(_friendlyError(code, data, isOtpStep: true));
    } on DioException catch (e) {
      logD('updateInfo /verify dio: ${e.message} body=${e.response?.data}');
      if (mounted) _snack(parseDioError(e, isArabic: isArabic(context)));
    } catch (e) {
      logD('updateInfo /verify unexpected: $e');
      if (mounted) _snack(AppLocalizations.of(context)!.nodata);
    }
    return false;
  }

  /// Map an OTP/auth failure to a friendly message. Mirrors the helper in
  /// login.dart but kept local so each flow can word things differently.
  String _friendlyError(int code, dynamic data, {required bool isOtpStep}) {
    if (data is Map) {
      final raw = data['message'] ?? data['error'] ?? data['detail'];
      final msg = raw?.toString().trim();
      if (msg != null &&
          msg.isNotEmpty &&
          msg.length <= 160 &&
          !msg.contains('\n')) {
        return msg;
      }
    }
    final ar = isArabic(context);
    switch (code) {
      case 400:
      case 422:
        return ar
            ? "البيانات المُدخلة غير صحيحة. تأكد منها وحاول مرة أخرى."
            : "The information you entered is not correct. Please check it and try again.";
      case 401:
      case 404:
      case 409:
      case 410:
        return isOtpStep
            ? (ar
                ? "رمز التحقق غير صحيح أو منتهي الصلاحية. حاول مرة أخرى."
                : "The verification code is invalid or expired. Please try again.")
            : (ar
                ? "تعذّر إرسال رمز التحقق. حاول مرة أخرى."
                : "We couldn't send the verification code. Please try again.");
      case 429:
        return ar
            ? "حاولت كثيرًا. يُرجى الانتظار قليلًا ثم المحاولة مرة أخرى."
            : "Too many attempts. Please wait a moment and try again.";
      default:
        return ar
            ? "تعذّر إتمام العملية. يُرجى المحاولة مرة أخرى."
            : "We couldn't complete the action. Please try again.";
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      final requestId = await _requestOtps();
      if (requestId == null || !mounted) return;

      final emailOtp = await _showOtpModal(
        title: bi(context, ar: "رمز البريد الإلكتروني", en: "Email code"),
        subtitle: bi(context,
            ar: "أُرسل إلى ${_email.text}",
            en: "Sent to ${_email.text}"),
        onResend: () => _resendOtp(requestId, "email"),
      );
      if (emailOtp == null || !mounted) return;

      final phoneOtp = await _showOtpModal(
        title: bi(context, ar: "رمز الجوال", en: "Mobile code"),
        subtitle: bi(context,
            ar: "أُرسل إلى ${_mobile.text}",
            en: "Sent to ${_mobile.text}"),
        onResend: () => _resendOtp(requestId, "mobile"),
      );
      if (phoneOtp == null || !mounted) return;

      final ok = await _verifyOtps(
        requestId: requestId,
        emailOtp: emailOtp,
        phoneOtp: phoneOtp,
      );
      if (ok && mounted) {
        _email.clear();
        _mobile.clear();
        _snack(bi(context,
            ar: "تم تحديث بياناتك بنجاح",
            en: "Your information has been updated"));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Modal asking for a 6-digit OTP. Resolves with the entered code on
  /// Verify, or null if the user dismisses. The 120-second resend timer
  /// lives inside the modal — same shape as login.dart's modal.
  Future<String?> _showOtpModal({
    required String title,
    required String subtitle,
    required Future<void> Function() onResend,
  }) {
    final controller = TextEditingController();
    bool isFilled = false;
    bool canResend = false;
    int seconds = 120;
    Timer? timer;

    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateModal) {
          timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
            setStateModal(() {
              if (seconds > 0) {
                seconds--;
              } else {
                canResend = true;
                timer?.cancel();
              }
            });
          });

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline_rounded,
                        color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '— — — — — —',
                    ),
                    onChanged: (value) {
                      setStateModal(() {
                        isFilled = value.length == 6;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: canResend
                        ? () async {
                            await onResend();
                            setStateModal(() {
                              seconds = 120;
                              canResend = false;
                            });
                          }
                        : null,
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: canResend ? AppColors.primary : AppColors.muted,
                    ),
                    label: Text(
                      canResend
                          ? bi(context,
                              ar: "إعادة إرسال الرمز", en: "Resend code")
                          : bi(context,
                              ar: "إعادة الإرسال خلال $seconds ثانية",
                              en: "Resend in ${seconds}s"),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: canResend
                            ? AppColors.primary
                            : AppColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  PrimaryButton(
                    label: AppLocalizations.of(context)!.veriy,
                    icon: Icons.verified_user_outlined,
                    onPressed: isFilled
                        ? () {
                            timer?.cancel();
                            Navigator.pop(context, controller.text);
                          }
                        : null,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((value) {
      timer?.cancel();
      controller.dispose();
      return value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ModernScaffold(
      title: t.updateinfo,
      subtitle: bi(context,
          ar: "تحديث بيانات الاتصال", en: "Update your contact details"),
      leadingIcon: Icons.manage_accounts_rounded,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                LabeledField(
                  label: t.email,
                  controller: _email,
                  icon: Icons.email_outlined,
                  hint: t.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return t.enteremail;
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return t.enteremail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                LabeledField(
                  label: t.mobile,
                  controller: _mobile,
                  icon: Icons.phone_iphone_rounded,
                  hint: t.mobile,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) return t.entermobile;
                    if (!RegExp(r'^\+?\d{9,15}$').hasMatch(value)) {
                      return t.entermobile;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: t.send,
                  icon: Icons.save_rounded,
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
