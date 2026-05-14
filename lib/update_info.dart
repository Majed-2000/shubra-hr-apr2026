// ============================================================================
// ملف: update_info.dart
// الغرض: شاشة تعديل البريد الإلكتروني ورقم الجوال للموظف (مع تحقق OTP مزدوج).
// التدفق:
//   1) عرض البيانات الحالية (view mode).
//   2) المستخدم يضغط "تعديل" → الحقول تصبح قابلة للتعديل.
//   3) عند الحفظ:
//      - إذا غيّر الإيميل: نُرسل OTP للإيميل الجديد ونتحقق منه.
//      - إذا غيّر الموبايل: نُرسل OTP عبر SMS ونتحقق منه.
//      - بعد التحقق المزدوج، نكتب في Oracle مباشرة.
//   4) إذا الإيميل والموبايل فارغان من البداية → نبدأ في edit mode تلقائياً.
// تذكير: الإيميل المرسِل هو digital.t@shubra.net، عنوان الرسالة:
//        "تأكيد تحديث البريد الإلكتروني".
// ============================================================================

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
/// Two modes:
///   - **View mode** (default when data is on file): fields show current
///     values disabled, user can tap "Data is correct" to confirm or
///     "Edit" to switch to edit mode.
///   - **Edit mode**: fields editable. If the user changed any value,
///     "Save" runs the dual-OTP flow (email OTP + mobile OTP, both
///     validated server-side, written to Oracle directly). If nothing
///     changed, the user can cancel back to view mode.
///
/// If the employee has no email/mobile on file, the screen starts in
/// edit mode automatically — there's nothing to confirm.
///
/// The old `/updateInfo` route is intentionally not called here. Older
/// App Store builds still use that route; backend keeps it alive for them.
class UpdateInfo extends StatefulWidget {
  @override
  _UpdateInfoState createState() => _UpdateInfoState();
}

class _UpdateInfoState extends State<UpdateInfo> {
  final _formKey = GlobalKey<FormState>();
  // متحكّمات الحقول.
  final TextEditingController _email = TextEditingController();
  final TextEditingController _mobile = TextEditingController();
  final dioClient = DioClient().client;

  bool _loading = true;       // هل جلب البيانات الحالية جارٍ؟
  bool _loadFailed = false;    // هل فشل الجلب الأولي؟
  bool _editing = false;       // هل في وضع التعديل (true) أم العرض (false)؟
  bool _sending = false;       // هل عملية الحفظ/OTP جارية؟

  // Backend-provided baseline. Used to detect changes and to revert on Cancel.
  // القيم الأصلية من الـ backend — نستعملها لكشف التغيير وللعودة عند Cancel.
  String _initialEmail = '';
  String _initialMobile = '';

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  @override
  void dispose() {
    _email.dispose();
    _mobile.dispose();
    super.dispose();
  }

  void _snack(String msg) => SnackbarHelpers.show(context, msg);

  /// Unmissable failure surface for the OTP flow. The plain snack is too
  /// easy to miss when the user is waiting for the OTP modal to appear,
  /// so OTP-flow failures pop a dialog with the friendly message AND the
  /// HTTP code (so a tester can tell us *why* the request failed).
  Future<void> _showFailureDialog(String body, {int? httpCode}) async {
    if (!mounted) return;
    final ar = isArabic(context);
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.error_outline_rounded,
            color: AppColors.danger, size: 36),
        title: Text(ar ? "تعذّر إتمام العملية" : "Couldn't complete"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(body),
            if (httpCode != null && httpCode != 0) ...[
              const SizedBox(height: 12),
              Text(
                '${ar ? "كود الخطأ" : "Error code"}: $httpCode',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ar ? "حسنًا" : "OK"),
          ),
        ],
      ),
    );
  }

  /// القيمة المُنظَّفة للإيميل (تُستعمل في كل المقارنات والإرسال).
  String get _emailValue => _email.text.trim();

  /// القيمة المُنظَّفة للجوال — تُزال المسافات والشُرَط (021-23 → 02123).
  String get _mobileValue =>
      _mobile.text.replaceAll(RegExp(r'[\s\-()]'), '').trim();

  /// هل تغيّر الإيميل عن قيمته الأصلية في الـ backend؟
  bool get _emailChanged => _emailValue != _initialEmail;

  /// هل تغيّر الجوال عن قيمته الأصلية في الـ backend؟
  bool get _mobileChanged => _mobileValue != _initialMobile;

  /// هل غيّر المستخدم أحد الحقول مقارنة بالقيمة الأصلية؟
  bool get _hasChanges => _emailChanged || _mobileChanged;

  /// هل توجد بيانات أصلية في الـ backend (أم أن الحساب بلا إيميل/جوال)؟
  bool get _hasInitialData =>
      _initialEmail.isNotEmpty || _initialMobile.isNotEmpty;

  /// Pulls the current email + mobile from `/myinfoview` so the user can see
  /// what's already on file. If both are missing, edit mode starts active.
  ///
  /// Tries a few common Oracle field names for the email key — backend should
  /// expose `info.email` ideally, but we tolerate `empml`/`ememl` too.
  Future<void> _loadCurrent() async {
    try {
      final response = await dioClient.get('/myinfoview');
      final data = response.data;
      if (data is Map) {
        final info = data['info'] is Map ? data['info'] as Map : const {};
        final email = (info['email'] ?? info['empml'] ?? info['ememl'] ?? '')
            .toString()
            .trim();
        final mobile =
            (info['empmob'] ?? info['mobile'] ?? '').toString().trim();
        if (!mounted) return;
        setState(() {
          _initialEmail = email;
          _initialMobile = mobile;
          _email.text = email;
          _mobile.text = mobile;
          _loading = false;
          _loadFailed = false;
          // No data on file → drop straight into edit mode; nothing to confirm.
          _editing = email.isEmpty && mobile.isEmpty;
        });
        return;
      }
      logD('updateInfo /myinfoview unexpected payload: $data');
      if (mounted) setState(() { _loading = false; _loadFailed = true; });
    } catch (e) {
      logD('updateInfo /myinfoview failed: $e');
      if (mounted) setState(() { _loading = false; _loadFailed = true; });
    }
  }

  /// الدخول إلى وضع التعديل (الحقول تصبح قابلة للكتابة).
  void _onEdit() => setState(() => _editing = true);

  /// إلغاء التعديل: استعادة القيم الأصلية والعودة إلى وضع العرض.
  void _onCancelEdit() {
    setState(() {
      _email.text = _initialEmail;
      _mobile.text = _initialMobile;
      _editing = false;
    });
    _formKey.currentState?.reset();
  }

  /// تأكيد أن البيانات الحالية صحيحة (المستخدم ضغط "البيانات صحيحة").
  void _onConfirmCorrect() {
    _snack(bi(context,
        ar: "شكرًا، بياناتك مؤكدة", en: "Thanks — your data is confirmed"));
    Navigator.pop(context);
  }

  // ─── OTP flow ────────────────────────────────────────────────────────

  /// Step 1: ask backend to send OTPs only for the field(s) the user changed.
  /// Passing `null` for an unchanged field signals the backend not to send an
  /// OTP for it (and not to overwrite the stored value).
  /// Returns the `request_id` on success, null on failure (dialog already shown).
  Future<String?> _requestOtps({String? email, String? mobile}) async {
    try {
      // نُرسل فقط الحقول المتغيّرة. إرسال الحقول كلها يُسبّب إرسال OTP
      // غير ضروري للحقل الذي لم يتغيّر (مشكلة شائعة عندما يحاول المستخدم
      // تعديل الإيميل فقط لكنه يستقبل SMS على جوال قديم/خاطئ).
      final payload = <String, dynamic>{};
      if (email != null) payload['email'] = email;
      if (mobile != null) payload['mobile'] = mobile;
      final response = await dioClient.post(
        '/updateInfo/request',
        data: payload,
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      final data = response.data;
      final code = response.statusCode ?? 0;
      if (code == 200 && data is Map && data['status'] == 'success') {
        final id = data['request_id']?.toString();
        if (id != null && id.isNotEmpty) return id;
      }
      logD('updateInfo /request failed: $code body=$data');
      await _showFailureDialog(
        _friendlyError(code, data, isOtpStep: false),
        httpCode: code,
      );
    } on DioException catch (e) {
      logD('updateInfo /request dio: ${e.message} body=${e.response?.data}');
      if (!mounted) return null;
      await _showFailureDialog(
        parseDioError(e, isArabic: isArabic(context)),
        httpCode: e.response?.statusCode,
      );
    } catch (e) {
      logD('updateInfo /request unexpected: $e');
      if (!mounted) return null;
      await _showFailureDialog(AppLocalizations.of(context)!.nodata);
    }
    return null;
  }

  /// Re-send a single OTP (email or mobile) under the same request_id.
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
        if (mounted) {
          _snack(_friendlyError(code, response.data, isOtpStep: false));
        }
      }
    } on DioException catch (e) {
      logD('updateInfo /resend ($type) dio: ${e.message}');
      if (mounted) _snack(parseDioError(e, isArabic: isArabic(context)));
    } catch (e) {
      logD('updateInfo /resend ($type) unexpected: $e');
    }
  }

  /// Step 3: submit the OTPs for the changed fields. Backend validates and
  /// writes to Oracle if all provided OTPs pass. Returns true on success.
  ///
  /// نُمرّر فقط الـ OTPs للحقول التي تغيّرت. الباك-إند يتجاهل الحقل غير الموجود
  /// في الـ payload ولا يُعدّله في Oracle.
  Future<bool> _verifyOtps({
    required String requestId,
    String? emailOtp,
    String? phoneOtp,
  }) async {
    try {
      final payload = <String, dynamic>{'request_id': requestId};
      if (emailOtp != null) payload['email_otp'] = emailOtp;
      if (phoneOtp != null) payload['phone_otp'] = phoneOtp;
      final response = await dioClient.post(
        '/updateInfo/verify',
        data: payload,
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      final data = response.data;
      final code = response.statusCode ?? 0;
      if (code == 200 && data is Map && data['status'] == 'success') {
        return true;
      }
      logD('updateInfo /verify failed: $code body=$data');
      await _showFailureDialog(
        _friendlyError(code, data, isOtpStep: true),
        httpCode: code,
      );
    } on DioException catch (e) {
      logD('updateInfo /verify dio: ${e.message} body=${e.response?.data}');
      if (!mounted) return false;
      await _showFailureDialog(
        parseDioError(e, isArabic: isArabic(context)),
        httpCode: e.response?.statusCode,
      );
    } catch (e) {
      logD('updateInfo /verify unexpected: $e');
      if (!mounted) return false;
      await _showFailureDialog(AppLocalizations.of(context)!.nodata);
    }
    return false;
  }

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

  /// تنفيذ الحفظ — يطلب OTP فقط للحقل/الحقول التي تغيّرت.
  /// 1) /updateInfo/request → نرسل فقط الحقول المتغيّرة.
  /// 2) إذا الإيميل تغيّر → dialog OTP للإيميل.
  /// 3) إذا الجوال تغيّر → dialog OTP للجوال.
  /// 4) /updateInfo/verify → نرسل OTPs الحقول المتغيّرة فقط.
  /// 5) عند النجاح: نحدّث القيم الأصلية ونخرج من وضع التعديل.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges) return;

    // قيم مُنظَّفة وتمييز ما تغيّر.
    final newEmail = _emailValue;
    final newMobile = _mobileValue;
    final emailChanged = _emailChanged;
    final mobileChanged = _mobileChanged;

    setState(() => _sending = true);
    try {
      // نُرسل فقط الحقول المتغيّرة كي لا يصل OTP غير ضروري لحقل لم يتغيّر.
      final requestId = await _requestOtps(
        email: emailChanged ? newEmail : null,
        mobile: mobileChanged ? newMobile : null,
      );
      if (requestId == null || !mounted) return;

      String? emailOtp;
      if (emailChanged) {
        emailOtp = await _showOtpModal(
          title: bi(context, ar: "رمز البريد الإلكتروني", en: "Email code"),
          subtitle: bi(context,
              ar: "أُرسل إلى $newEmail", en: "Sent to $newEmail"),
          onResend: () => _resendOtp(requestId, "email"),
        );
        // إن أغلق المستخدم الـ dialog يدوياً → نخرج بدون verify.
        if (emailOtp == null || !mounted) return;
      }

      String? phoneOtp;
      if (mobileChanged) {
        phoneOtp = await _showOtpModal(
          title: bi(context, ar: "رمز الجوال", en: "Mobile code"),
          subtitle: bi(context,
              ar: "أُرسل إلى $newMobile", en: "Sent to $newMobile"),
          onResend: () => _resendOtp(requestId, "mobile"),
        );
        if (phoneOtp == null || !mounted) return;
      }

      final ok = await _verifyOtps(
        requestId: requestId,
        emailOtp: emailOtp,
        phoneOtp: phoneOtp,
      );
      if (ok && mounted) {
        setState(() {
          // نحدّث الـ baseline والـ controllers بالقيم المُنظَّفة فقط
          // (مثلاً إزالة المسافات من الجوال) كي تتطابق UI مع الـ backend.
          _initialEmail = newEmail;
          _initialMobile = newMobile;
          _email.text = newEmail;
          _mobile.text = newMobile;
          _editing = false;
        });
        _snack(bi(context,
            ar: "تم تحديث بياناتك بنجاح",
            en: "Your information has been updated"));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Modal asking for a 6-digit OTP. Resolves with the entered code on
  /// Verify, or null if the user dismisses via the explicit close button.
  ///
  /// barrierDismissible: false — لمس خارج الـ dialog لا يُغلقه، كي لا يفقد
  /// المستخدم الـ request_id بالخطأ ويضطر لإعادة طلب OTP جديد.
  Future<String?> _showOtpModal({
    required String title,
    required String subtitle,
    required Future<void> Function() onResend,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OtpDialog(
        title: title,
        subtitle: subtitle,
        onResend: onResend,
      ),
    );
  }

  // ─── UI ──────────────────────────────────────────────────────────────

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
          child: _loading
              ? _buildLoading()
              : _loadFailed
                  ? _buildFailed()
                  : _buildForm(t),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildFailed() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded,
              color: AppColors.muted, size: 40),
          const SizedBox(height: 12),
          Text(
            bi(context,
                ar: "تعذّر تحميل بياناتك",
                en: "Couldn't load your information"),
            style: TextStyle(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: bi(context, ar: "إعادة المحاولة", en: "Try again"),
            icon: Icons.refresh_rounded,
            onPressed: () {
              setState(() {
                _loading = true;
                _loadFailed = false;
              });
              _loadCurrent();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AppLocalizations t) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          LabeledField(
            label: t.email,
            controller: _email,
            icon: Icons.email_outlined,
            hint: t.email,
            keyboardType: TextInputType.emailAddress,
            enabled: _editing && !_sending,
            validator: (value) {
              if (!_editing) return null;
              final v = value?.trim() ?? '';
              if (v.isEmpty) return t.enteremail;
              // النمط مُثبَّت بـ ^ و $ كي لا يقبل أحرفاً زائدة بعد الإيميل.
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
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
            enabled: _editing && !_sending,
            validator: (value) {
              if (!_editing) return null;
              // نُنظّف المسافات والشُرَط قبل التحقق لأن المستخدم قد يكتب
              // "+966 50 123 4567" — نقبلها لكن نُرسل النسخة المُنظَّفة.
              final v = (value ?? '').replaceAll(RegExp(r'[\s\-()]'), '');
              if (v.isEmpty) return t.entermobile;
              if (!RegExp(r'^\+?\d{9,15}$').hasMatch(v)) {
                return t.entermobile;
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ..._buildButtons(),
        ],
      ),
    );
  }

  List<Widget> _buildButtons() {
    if (_editing) {
      return [
        PrimaryButton(
          label: bi(context, ar: "حفظ التعديلات", en: "Save changes"),
          icon: Icons.save_rounded,
          loading: _sending,
          onPressed: _hasChanges ? _submit : null,
        ),
        if (_hasInitialData) ...[
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: _sending ? null : _onCancelEdit,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: Text(bi(context, ar: "إلغاء", en: "Cancel")),
          ),
        ],
      ];
    }
    return [
      PrimaryButton(
        label: bi(context, ar: "البيانات صحيحة", en: "Data is correct"),
        icon: Icons.check_circle_outline_rounded,
        onPressed: _onConfirmCorrect,
      ),
      const SizedBox(height: 6),
      TextButton.icon(
        onPressed: _onEdit,
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: Text(bi(context, ar: "تحرير المعلومات", en: "Edit information")),
      ),
    ];
  }
}

/// 6-digit OTP entry dialog with a 120-second resend countdown.
///
/// Owns its own timer in [State] so the lifecycle is tied to mount/unmount —
/// no risk of duplicate timers from rebuilds, and Resend cleanly restarts
/// the countdown.
class _OtpDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final Future<void> Function() onResend;

  const _OtpDialog({
    required this.title,
    required this.subtitle,
    required this.onResend,
  });

  @override
  State<_OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<_OtpDialog> {
  static const int _resendSeconds = 120;

  final TextEditingController _controller = TextEditingController();
  bool _isFilled = false;
  bool _canResend = false;
  int _seconds = _resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _seconds = _resendSeconds;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          _canResend = true;
          _timer?.cancel();
        }
      });
    });
  }

  Future<void> _handleResend() async {
    await widget.onResend();
    if (!mounted) return;
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
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
              widget.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
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
                setState(() => _isFilled = value.length == 6);
              },
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: _canResend ? _handleResend : null,
              icon: Icon(
                Icons.refresh_rounded,
                size: 18,
                color: _canResend ? AppColors.primary : AppColors.muted,
              ),
              label: Text(
                _canResend
                    ? bi(context, ar: "إعادة إرسال الرمز", en: "Resend code")
                    : bi(context,
                        ar: "إعادة الإرسال خلال $_seconds ثانية",
                        en: "Resend in ${_seconds}s"),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _canResend ? AppColors.primary : AppColors.muted,
                ),
              ),
            ),
            const SizedBox(height: 6),
            PrimaryButton(
              label: AppLocalizations.of(context)!.veriy,
              icon: Icons.verified_user_outlined,
              onPressed: _isFilled
                  ? () => Navigator.pop(context, _controller.text)
                  : null,
            ),
            const SizedBox(height: 4),
            // زر إغلاق صريح — لأن barrierDismissible: false في الـ caller.
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(
                bi(context, ar: "إلغاء", en: "Cancel"),
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
