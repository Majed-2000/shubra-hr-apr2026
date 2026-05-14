// ============================================================================
// ملف: digital_card.dart
// الغرض: بطاقة الموظف الرقمية (Digital ID) مع QR code.
// المحتوى:
//   - بطاقة بحجم كرت ائتمان مع تدرج لوني.
//   - اسم الموظف + الوظيفة + الإدارة + كود.
//   - QR code يحوي بيانات الموظف.
//   - أزرار: مشاركة (Share)، حفظ صورة، تحديث.
// ⚠️ تنبيه iOS: share_plus يحتاج sharePositionOrigin
//   (RenderBox للزر) وإلا يفشل على iPad — مذكور في memory.
// ============================================================================

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'config/app_config.dart';
import 'dio_client.dart';
import 'l10n/app_localizations.dart';
import 'shared/utils/dio_errors.dart';
import 'shared/utils/logger.dart';
import 'shared/utils/snackbar.dart';
import 'theme.dart';
import 'widgets.dart';

/// Digital employee badge — a credit-card-sized ID with the employee's
/// name, job title, employee code and a QR code. Self-fetches the data
/// via /myinfoview so the screen is openable from anywhere.
///
/// بطاقة موظف رقمية بحجم كرت ائتمان مع QR. تجلب البيانات من /myinfoview
/// بنفسها لكي تكون قابلة للفتح من أي مكان.
class DigitalCard extends StatefulWidget {
  const DigitalCard({super.key});

  @override
  State<DigitalCard> createState() => _DigitalCardState();
}

class _DigitalCardState extends State<DigitalCard>
    with SingleTickerProviderStateMixin {
  static const Color _gradStart = Color(0xFF1565C0);
  static const Color _gradEnd = Color(0xFF0D47A1);

  final dioClient = DioClient().client;
  final _storage = const FlutterSecureStorage();
  final GlobalKey _cardKey = GlobalKey();
  final GlobalKey _shareBtnKey = GlobalKey();

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  bool _isLoading = true;
  bool _hasData = false;
  bool _sharing = false;

  String _empCode = '';
  String _nameAr = '';
  String _jobTitle = '';
  String _department = '';
  String? _photoUrl;
  Map<String, String>? _photoHeaders;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fetch();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  /// جلب بيانات الموظف لرسم البطاقة (الاسم، الوظيفة، الإدارة، الكود).
  /// يستدعى عند initState وعند الضغط على زر التحديث.
  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final response = await dioClient.get('/myinfoview');
      final data = Map<String, dynamic>.from(response.data as Map);
      final info = Map<String, dynamic>.from(data['info'] ?? {});

      _empCode = info['emcd']?.toString() ?? '';
      _nameAr = [
        info['emnma1'],
        info['emnma2'],
        info['emnma3'],
      ].whereType<Object>().map((e) => e.toString()).join(' ').trim();

      // Backend resolves these via PYMNG/PYDPT joins. Be permissive about
      // where they land (top-level vs. inside info) and the casing
      // (camelCase vs. snake_case) so a small backend rename doesn't
      // silently empty the card.
      _jobTitle = _firstNonEmpty(data,
              ['jobTitle', 'job_title', 'jobtitle', 'JobTitle']) ??
          _firstNonEmpty(info, [
                'jobTitle',
                'job_title',
                'jobtitle',
                'emjbtl',
                'emjbnm',
              ]) ??
          '';
      _department = _firstNonEmpty(data, [
            'deptName',
            'dept_name',
            'departmentName',
            'department',
          ]) ??
          _firstNonEmpty(info, ['deptName', 'dept_name']) ??
          '';
      if (_department.isEmpty) {
        final mgr2 = data['mgr2'];
        if (mgr2 is Map) {
          _department =
              _firstNonEmpty(mgr2, ['mnnma', 'mnnme', 'name']) ?? '';
        }
      }

      // Debug-only visibility. Read these in the dev console after a
      // hot restart and tell me what shows up.
      logD('digital_card /myinfoview TOP keys: ${data.keys.toList()}');
      logD('digital_card /myinfoview info keys: ${info.keys.toList()}');
      logD('digital_card RESOLVED jobTitle="$_jobTitle" department="$_department"');
      _hasData = _empCode.isNotEmpty;

      // Photo: build URL from configured template and prep auth header.
      // If template isn't set or empcode is empty, _photoUrl stays null
      // and the card renders the fallback avatar.
      _photoUrl = AppConfig.employeePhotoUrl(_empCode);
      if (_photoUrl != null) {
        final token = await _storage.read(key: 'access_token');
        _photoHeaders =
            token != null ? {'Authorization': 'Bearer $token'} : null;
      }

      if (_hasData && mounted) {
        _fadeCtrl.forward(from: 0);
      }
    } on DioException catch (e) {
      logD('Card fetch failed: $e');
      if (!mounted) return;
      _hasData = false;
      SnackbarHelpers.showError(
        context,
        parseDioError(e, isArabic: isArabic(context)),
      );
    } catch (e) {
      logD('Card unexpected error: $e');
      if (!mounted) return;
      _hasData = false;
      SnackbarHelpers.showError(
        context,
        isArabic(context)
            ? 'حدث خطأ غير متوقع. يُرجى المحاولة مرة أخرى.'
            : 'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// مشاركة البطاقة كصورة PNG عبر share sheet.
  /// خطوات:
  ///   1) التقاط صورة من الـ widget باستخدام RepaintBoundary.toImage.
  ///   2) كتابة الصورة في ملف مؤقت.
  ///   3) استدعاء Share.shareXFiles مع anchor للزر (مهم لـ iPad).
  Future<void> _shareCard() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      // 1) التقاط صورة عالية الدقة من البطاقة (3x pixel ratio).
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final Uint8List bytes = byteData.buffer.asUint8List();

      // 2) كتابة في ملف مؤقت لـ share_plus.
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/employee_card_$_empCode.png');
      await file.writeAsBytes(bytes);

      final t = AppLocalizations.of(context)!;

      // iPad requires an anchor rect for the share popover; without it
      // share_plus throws. Anchor on the share button when available.
      //
      // ⚠️ مهم جداً: iPad يحتاج anchor rect للـ popover.
      // بدونها share_plus يرمي exception على iPad ويفشل بدون رسالة واضحة.
      // نحسب الـ rect من زر المشاركة عبر GlobalKey + findRenderObject.
      Rect? origin;
      final btnBox =
          _shareBtnKey.currentContext?.findRenderObject() as RenderBox?;
      if (btnBox != null && btnBox.hasSize) {
        final topLeft = btnBox.localToGlobal(Offset.zero);
        origin = topLeft & btnBox.size;
      }

      // 3) فتح share sheet مع الصورة.
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: t.digitalCard,
        sharePositionOrigin: origin,
      );
    } catch (e) {
      logD('Share card failed: $e');
      if (!mounted) return;
      SnackbarHelpers.showError(
        context,
        AppLocalizations.of(context)!.shareCardFailed,
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ModernScaffold(
      title: t.digitalCard,
      subtitle: t.digitalCardSubtitle,
      leadingIcon: Icons.badge_rounded,
      body: _isLoading
          ? Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Column(
                children: [
                  // Card-shaped placeholder
                  AspectRatio(
                    aspectRatio: 1.586,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: const [
                              Skeleton(width: 90, height: 14),
                              Skeleton.box(size: 36),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Skeleton(width: 180, height: 18),
                              SizedBox(height: 8),
                              Skeleton(width: 110, height: 12),
                            ],
                          ),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: const [
                              Skeleton(width: 70, height: 11),
                              Skeleton(width: 60, height: 11),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Skeleton(width: 200, height: 14),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Skeleton(width: 130, height: 44, radius: 22),
                      SizedBox(width: 12),
                      Skeleton(width: 130, height: 44, radius: 22),
                    ],
                  ),
                ],
              ),
            )
          : !_hasData
              ? ListView(
                  children: [
                    const SizedBox(height: 60),
                    EmptyState(
                      icon: Icons.credit_card_off_rounded,
                      title: t.nodata,
                      subtitle: t.noCardData,
                    ),
                  ],
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                  child: Column(
                    children: [
                      FadeTransition(
                        opacity: _fade,
                        child: AspectRatio(
                          aspectRatio: 1.586,
                          child: RepaintBoundary(
                            key: _cardKey,
                            child: _buildCard(t),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          key: _shareBtnKey,
                          label: t.shareCard,
                          icon: Icons.ios_share_rounded,
                          loading: _sharing,
                          onPressed: _shareCard,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  /// Walks [keys] in order on [m] and returns the first value that, after
  /// trim, is non-empty. Returns null when nothing matches — caller picks
  /// the fallback. Tolerates [m] being null or any non-Map.
  String? _firstNonEmpty(dynamic m, List<String> keys) {
    if (m is! Map) return null;
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  /// Avatar slot on the card. Tries the configured employee-photo URL
  /// first; on any failure (no URL set, 404, network error, decode error)
  /// quietly falls back to a generic person icon. The user explicitly
  /// asked for "show photo if available, skip otherwise" — no error UI.
  Widget _buildAvatar() {
    final url = _photoUrl;
    if (url == null) return _avatarFallback();
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: ClipOval(
        child: Image.network(
          url,
          headers: _photoHeaders,
          fit: BoxFit.cover,
          width: 56,
          height: 56,
          errorBuilder: (_, __, ___) => _avatarFallback(plain: true),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return _avatarFallback(plain: true);
          },
        ),
      ),
    );
  }

  Widget _avatarFallback({bool plain = false}) {
    final icon = const Icon(
      Icons.person_rounded,
      color: Colors.white,
      size: 30,
    );
    if (plain) return Center(child: icon);
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: icon,
    );
  }

  Widget _buildCard(AppLocalizations t) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gradStart, _gradEnd],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        children: [
          // ─── Header band: logo + brand ─────────────────────────
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Image.asset('assets/shubra.png', fit: BoxFit.contain),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'SHUBRA AL-TAIF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Colors.white24, height: 1),
          ),

          // ─── Identity ──────────────────────────────────────────
          Expanded(
            child: Row(
              children: [
                _buildAvatar(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_nameAr.isNotEmpty)
                        Text(
                          _nameAr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      if (_jobTitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _jobTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      if (_department.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _department,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.72),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Footer band: emp ID + QR ──────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.empcode,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _empCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: QrImageView(
                  data: _empCode,
                  version: QrVersions.auto,
                  size: 56,
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
