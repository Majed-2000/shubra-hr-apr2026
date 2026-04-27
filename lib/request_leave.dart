import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'dio_client.dart';
import 'constants/leave_types.dart';
import 'l10n/app_localizations.dart';
import 'shared/utils/dio_errors.dart';
import 'shared/utils/snackbar.dart';
import 'shared/widgets/date_picker_tile.dart';
import 'shared/widgets/vacation_type_card.dart';
import 'theme.dart';
import 'widgets.dart';

/// Leave-request form. Pulls available [LeaveType]s from the backend,
/// defaults to internal vacation, and enforces an attachment for special
/// leaves (death, marriage, childbirth, hajj).
class RequestLeave extends StatefulWidget {
  @override
  _RequestLeaveState createState() => _RequestLeaveState();
}

class _RequestLeaveState extends State<RequestLeave> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reason = TextEditingController();
  final dioClient = DioClient().client;

  DateTime? _startDate;
  DateTime? _returnDate;
  String? _selectedCode;
  XFile? _attach;

  List<dynamic> _types = [];
  String _vacBal = "";
  bool _loading = true;
  bool _submitting = false;
  int _letterCount = 0;

  @override
  void initState() {
    super.initState();
    _reason.addListener(_updateWordCount);
    _fetchTypes();
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _updateWordCount() {
    final count = _reason.text.replaceAll(RegExp(r'\s'), '').length;
    if (count != _letterCount) {
      setState(() => _letterCount = count);
    }
  }

  Future<void> _fetchTypes() async {
    try {
      final response = await dioClient.post('/getleavetype');
      final data = response.data;
      setState(() {
        _types = data["vac"] ?? [];
        _vacBal = (data["vacBal"] ?? "").toString();
        if (_types.isNotEmpty) {
          final internal = _types.firstWhere(
            (t) => t['vccd']?.toString() == '02',
            orElse: () => _types.first,
          );
          _selectedCode = internal['vccd']?.toString();
        }
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() => _loading = false);
      _snack(parseDioError(e, isArabic: isArabic(context)));
    } catch (e) {
      setState(() => _loading = false);
      _snack(e.toString());
    }
  }

  gettoken() async {
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: "access_token");
    if (token != null) {
      Navigator.pushNamed(context, "/home");
    }
  }

  int get _nodays {
    if (_startDate == null || _returnDate == null) return 0;
    return _returnDate!.difference(_startDate!).inDays;
  }

  Map<String, dynamic> get _selectedType {
    for (final t in _types) {
      if (t['vccd'].toString() == _selectedCode) {
        return Map<String, dynamic>.from(t);
      }
    }
    return {};
  }

  LeaveType? get _selectedLeaveType => LeaveType.fromCode(_selectedCode);

  bool get _isRegularType => _selectedLeaveType?.isRegular ?? false;

  bool get _isSpecialType => _selectedLeaveType?.isSpecial ?? false;

  bool get _attachmentRequired =>
      _selectedLeaveType?.requiresAttachment ?? false;

  void _snack(String m) => SnackbarHelpers.show(context, m);

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startDate ?? now)
        : (_returnDate ??
            (_startDate?.add(const Duration(days: 1)) ??
                now.add(const Duration(days: 1))));
    final firstDate = isStart
        ? now.subtract(const Duration(days: 30))
        : (_startDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.onSurface,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_returnDate != null && !_returnDate!.isAfter(picked)) {
            _returnDate = null;
          }
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  (IconData, Color) _metaForCode(String code) =>
      LeaveType.fromCode(code)?.presentation ??
      (Icons.event_note_rounded, AppColors.secondary);

  String _localizedTypeName(
      BuildContext context, String code, String fallback) {
    final t = AppLocalizations.of(context)!;
    return LeaveType.fromCode(code)?.localizedName(t) ?? fallback;
  }

  Future<void> _pickAttachment() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _attach = image);
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;

    if (_startDate == null || _returnDate == null) {
      _snack(bi(context,
          ar: "اختر تاريخ بداية الإجازة وتاريخ المباشرة",
          en: "Select both vacation start and return dates"));
      return;
    }
    if (_nodays <= 0) {
      _snack(bi(context,
          ar: "يجب أن يكون تاريخ المباشرة بعد تاريخ البداية",
          en: "Return date must be after start date"));
      return;
    }
    if (_selectedCode == null) {
      _snack(bi(context,
          ar: "اختر نوع الإجازة", en: "Select a vacation type"));
      return;
    }
    if (_letterCount < 5) {
      _snack(bi(context,
          ar: "اكتب سبب الإجازة (٥ أحرف على الأقل)",
          en: "Write the reason (at least 5 letters)"));
      return;
    }
    if (_attachmentRequired && _attach == null) {
      final typeName =
          _localizedTypeName(context, _selectedCode ?? '', '');
      _snack(bi(context,
          ar: "إرفاق ملف إلزامي لإجازة «$typeName»",
          en: "Attachment is required for \"$typeName\" leave"));
      return;
    }

    final confirmed = await _showConfirmation();
    if (!confirmed) return;

    setState(() => _submitting = true);
    try {
      final startStr = DateFormat('yyyy-MM-dd').format(_startDate!);
      final returnStr = DateFormat('yyyy-MM-dd').format(_returnDate!);

      final baseMap = <String, dynamic>{
        'date': startStr,
        'date2': returnStr,
        'notice': _reason.text.trim(),
        'type': _selectedCode,
      };
      if (_attach != null) {
        final fileName = _attach!.path.split('/').last;
        baseMap['img'] = await MultipartFile.fromFile(_attach!.path,
            filename: fileName);
      }

      final formData = FormData.fromMap(baseMap);
      final response =
          await dioClient.post('/submitleaverequest', data: formData);
      final data = response.data;
      final code = data is Map ? data['success']?.toString() : null;
      final serverMsg = data is Map ? data['message']?.toString() : null;

      String display;
      switch (code) {
        case 'success':
          display = t.sent;
          break;
        case 'notoday':
          display = t.notoday;
          break;
        case 'invalidfile':
          display = t.invalidfile;
          break;
        case 'nobalance':
          display = t.nobalance;
          break;
        case 'notovac':
          display = t.notovac;
          break;
        case 'minimumis5':
          display = t.minimum5;
          break;
        default:
          display = serverMsg ??
              bi(context,
                  ar: "تعذر إرسال الطلب، حاول مرة أخرى",
                  en: "Could not submit the request");
      }
      _snack(display);

      if (code == 'success') {
        setState(() {
          _reason.clear();
          _attach = null;
          _startDate = null;
          _returnDate = null;
        });
      }
    } on DioException catch (e) {
      _snack(parseDioError(e, isArabic: isArabic(context)));
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ModernScaffold(
      title: t.requestleave,
      subtitle:
          bi(context, ar: "تقديم طلب إجازة جديد", en: "Submit a new leave"),
      leadingIcon: Icons.time_to_leave_outlined,
      body: _loading
          ? const Loader()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildBalanceCard(t),
                  const SizedBox(height: 14),
                  _buildDatesCard(context),
                  const SizedBox(height: 14),
                  _buildTypeCards(context),
                  if (_isSpecialType) ...[
                    const SizedBox(height: 12),
                    _buildSpecialTypeNotice(context),
                  ],
                  const SizedBox(height: 14),
                  _buildReasonCard(context),
                  const SizedBox(height: 14),
                  _buildAttachmentCard(context, t),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: t.send,
                    icon: Icons.send_rounded,
                    loading: _submitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceCard(AppLocalizations t) {
    final selectedTotDays = _selectedType['totdays']?.toString();
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.beach_access_rounded,
                color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.vacbal,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12.5)),
                const SizedBox(height: 4),
                Text(
                  _vacBal.isEmpty ? '—' : _vacBal,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
          if (selectedTotDays != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.accent.withOpacity(0.35), width: 1),
              ),
              child: Text(
                "${t.totdays} $selectedTotDays",
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDatesCard(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bi(context, ar: "الفترة", en: "Period"),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              if (_nodays > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${_nodays} ${AppLocalizations.of(context)!.nodays}",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DatePickerTile(
                  label: bi(context,
                      ar: "تاريخ بداية الإجازة", en: "Vacation start"),
                  icon: Icons.flight_takeoff_rounded,
                  value: _startDate,
                  color: AppColors.primary,
                  placeholder: bi(context, ar: "اختر التاريخ", en: "Select date"),
                  onTap: () => _pickDate(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DatePickerTile(
                  label: bi(context,
                      ar: "تاريخ المباشرة", en: "Return to work"),
                  icon: Icons.flight_land_rounded,
                  value: _returnDate,
                  color: AppColors.secondary,
                  placeholder: bi(context, ar: "اختر التاريخ", en: "Select date"),
                  onTap: () => _pickDate(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              const Icon(Icons.category_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                bi(context, ar: "نوع الإجازة", en: "Vacation type"),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_types.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                bi(context,
                    ar: "لا توجد أنواع إجازات متاحة",
                    en: "No vacation types available"),
                style:
                    const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _types.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.65,
            ),
            itemBuilder: (_, i) {
              final item = _types[i];
              final code = item['vccd'].toString();
              final label = _localizedTypeName(
                  context, code, item['vcnma']?.toString() ?? '-');
              final meta = _metaForCode(code);
              final icon = meta.$1;
              final color = meta.$2;
              final selected = _selectedCode == code;
              return VacationTypeCard(
                icon: icon,
                color: color,
                label: label,
                selected: selected,
                onTap: () => setState(() => _selectedCode = code),
              );
            },
          ),
      ],
    );
  }

  Widget _buildReasonCard(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final enough = _letterCount >= 5;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bi(context, ar: "سبب الإجازة", en: "Reason"),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (enough ? AppColors.success : AppColors.warning)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      enough
                          ? Icons.check_circle_rounded
                          : Icons.info_rounded,
                      size: 13,
                      color: enough
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      bi(context,
                          ar: "$_letterCount / ٥ أحرف",
                          en: "$_letterCount / 5 letters"),
                      style: TextStyle(
                        color: enough
                            ? AppColors.success
                            : AppColors.warning,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _reason,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: bi(context,
                  ar: "اكتب سبب طلب الإجازة بوضوح (٥ أحرف على الأقل)...",
                  en:
                      "Write the reason for your request (at least 5 letters)..."),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialTypeNotice(BuildContext context) {
    final typeName = _localizedTypeName(context, _selectedCode ?? '', '');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.warning.withOpacity(0.12),
            AppColors.warning.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: AppColors.warning.withOpacity(0.45), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.20),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: const Icon(Icons.priority_high_rounded,
                color: AppColors.warning, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bi(context,
                      ar: "تنبيه: نوع إجازة خاص",
                      en: "Warning: Special vacation type"),
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bi(context,
                      ar:
                          "اخترت «$typeName» وهي ليست إجازة خارجية أو داخلية. لها شروط خاصة وقد تتطلب موافقة إضافية من الإدارة. تأكد من اختيارك قبل المتابعة.",
                      en:
                          "You selected \"$typeName\" which is not a regular external or internal vacation. It has special conditions and may require extra approval. Please make sure this is what you want."),
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmation() async {
    final t = AppLocalizations.of(context)!;
    final typeName = _localizedTypeName(
        context, _selectedCode ?? '', _selectedType['vcnma']?.toString() ?? '');
    final startStr = DateFormat('EEE, dd MMM yyyy').format(_startDate!);
    final returnStr = DateFormat('EEE, dd MMM yyyy').format(_returnDate!);
    final days = _nodays;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.xl),
                    topRight: Radius.circular(AppRadius.xl),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.fact_check_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      bi(context,
                          ar: "تأكيد طلب الإجازة",
                          en: "Confirm leave request"),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bi(context,
                          ar: "راجع التفاصيل قبل الإرسال",
                          en: "Review the details before sending"),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _confirmRow(
                        icon: Icons.category_rounded,
                        label: bi(context,
                            ar: "نوع الإجازة", en: "Vacation type"),
                        value: typeName,
                        color: AppColors.primary,
                      ),
                      _confirmRow(
                        icon: Icons.flight_takeoff_rounded,
                        label: bi(context,
                            ar: "تاريخ بداية الإجازة",
                            en: "Vacation start"),
                        value: startStr,
                        color: AppColors.primary,
                      ),
                      _confirmRow(
                        icon: Icons.flight_land_rounded,
                        label: bi(context,
                            ar: "تاريخ المباشرة",
                            en: "Return to work"),
                        value: returnStr,
                        color: AppColors.secondary,
                      ),

                      const SizedBox(height: 8),
                      // Deduction highlight
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _isRegularType
                                ? [
                                    AppColors.primary.withOpacity(0.10),
                                    AppColors.primary.withOpacity(0.03),
                                  ]
                                : [
                                    AppColors.success.withOpacity(0.12),
                                    AppColors.success.withOpacity(0.03),
                                  ],
                          ),
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: _isRegularType
                                ? AppColors.primary.withOpacity(0.35)
                                : AppColors.success.withOpacity(0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _isRegularType
                                    ? AppColors.primary.withOpacity(0.16)
                                    : AppColors.success.withOpacity(0.16),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.xs),
                              ),
                              child: Icon(
                                _isRegularType
                                    ? Icons.remove_circle_outline_rounded
                                    : Icons
                                        .check_circle_outline_rounded,
                                color: _isRegularType
                                    ? AppColors.primary
                                    : AppColors.success,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isRegularType
                                        ? bi(context,
                                            ar: "سينخصم من رصيدك",
                                            en: "Will be deducted")
                                        : bi(context,
                                            ar: "لا ينخصم من رصيدك",
                                            en: "Not deducted"),
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isRegularType
                                        ? bi(context,
                                            ar: "$days يوم من رصيد الإجازات",
                                            en: "$days days from balance")
                                        : bi(context,
                                            ar:
                                                "$days يوم — إجازة خاصة لا تخصم من الرصيد",
                                            en:
                                                "$days days — special leave, no balance impact"),
                                    style: const TextStyle(
                                      color: AppColors.onSurface,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                      Text(
                        bi(context, ar: "سبب الإجازة", en: "Reason"),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          _reason.text.trim(),
                          style: const TextStyle(
                            color: AppColors.onSurface,
                            fontSize: 13.5,
                            height: 1.5,
                          ),
                        ),
                      ),

                      if (_attach != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.attach_file_rounded,
                                size: 16, color: AppColors.success),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _attach!.path.split('/').last,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (_isSpecialType) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.10),
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: AppColors.warning.withOpacity(0.35),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: AppColors.warning, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  bi(context,
                                      ar:
                                          "أنت تطلب إجازة خاصة ($typeName). تأكد من اختيارك جيداً.",
                                      en:
                                          "You are requesting a special leave ($typeName). Double-check your choice."),
                                  style: const TextStyle(
                                    color: AppColors.onSurface,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                              color: AppColors.border, width: 1.2),
                          foregroundColor: AppColors.onSurface,
                        ),
                        child: Text(
                          bi(context, ar: "إلغاء", en: "Cancel"),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: PrimaryButton(
                        label: bi(context,
                            ar: "تأكيد الإرسال",
                            en: "Confirm & send"),
                        icon: Icons.check_rounded,
                        onPressed: () =>
                            Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return result ?? false;
  }

  Widget _confirmRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentCard(BuildContext context, AppLocalizations t) {
    final hasFile = _attach != null;
    final required = _attachmentRequired;
    final missing = required && !hasFile;
    final iconColor = hasFile
        ? AppColors.success
        : (missing ? AppColors.warning : AppColors.secondary);
    return GlassCard(
      onTap: _pickAttachment,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              hasFile
                  ? Icons.check_circle_rounded
                  : Icons.attach_file_rounded,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        hasFile
                            ? bi(context, ar: "تم الإرفاق", en: "Attached")
                            : t.attach,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    if (required) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.warning.withOpacity(0.40),
                              width: 1),
                        ),
                        child: Text(
                          bi(context, ar: "إلزامي", en: "Required"),
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  hasFile
                      ? _attach!.path.split('/').last
                      : (required
                          ? bi(context,
                              ar: "إرفاق ملف مطلوب لهذا النوع من الإجازات",
                              en: "An attachment is required for this leave type")
                          : bi(context,
                              ar: "اختياري — اضغط لإرفاق ملف",
                              en: "Optional — tap to attach a file")),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: missing ? AppColors.warning : AppColors.muted,
                    fontSize: 12,
                    fontWeight:
                        missing ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (hasFile)
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  size: 20, color: AppColors.muted),
              onPressed: () => setState(() => _attach = null),
            )
          else
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.muted),
        ],
      ),
    );
  }
}

