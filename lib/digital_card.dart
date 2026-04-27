import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

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
  final GlobalKey _cardKey = GlobalKey();

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  bool _isLoading = true;
  bool _hasData = false;
  bool _sharing = false;

  String _empCode = '';
  String _nameAr = '';
  String _nameEn = '';
  String _jobTitle = '';

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
      _nameEn = [
        info['emnme1'],
        info['emnme2'],
        info['emnme3'],
      ].whereType<Object>().map((e) => e.toString()).join(' ').trim();
      _jobTitle = info['emjbtl']?.toString() ?? '';
      _hasData = _empCode.isNotEmpty;

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
      SnackbarHelpers.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _shareCard() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final Uint8List bytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/employee_card_$_empCode.png');
      await file.writeAsBytes(bytes);

      final t = AppLocalizations.of(context)!;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: t.digitalCard,
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
          ? const Loader()
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
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_nameEn.isNotEmpty)
                        Text(
                          _nameEn,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      if (_nameAr.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _nameAr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.92),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
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
