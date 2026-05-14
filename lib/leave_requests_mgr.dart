// ============================================================================
// ملف: leave_requests_mgr.dart
// الغرض: قائمة طلبات الإجازات المعلّقة للمدير — للموافقة/الرفض.
// الميزات:
//   - بحث في طلبات الموظفين.
//   - paginated مع scroll-to-load-more.
//   - الموافقة / الرفض / إضافة ملاحظة / تعديل عدد الأيام.
// API:
//   GET  /mgr/getLeaveRequests?page=N
//   POST /mgr/approveLeave / /mgr/refuseLeave
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'dio_client.dart';
import 'leave.dart';
import 'l10n/app_localizations.dart';
import 'shared/utils/dio_errors.dart';
import 'shared/utils/logger.dart';
import 'shared/utils/snackbar.dart';
import 'theme.dart';
import 'widgets.dart';

/// Manager queue for approving or refusing employee leave requests.
///
/// قائمة الموافقة للمدير — يستعرض طلبات الإجازات ويوافق/يرفض.
class LeaverequestsMgr extends StatefulWidget {
  @override
  _LeaverequestsMgrState createState() => _LeaverequestsMgrState();
}

class _LeaverequestsMgrState extends State<LeaverequestsMgr> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _nodays = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool stop = false;
  int _page = 0;
  String days = "";
  String _query = "";
  final dioClient = DioClient().client;
  List<Leave> Lrequests = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
    setState(() => _page++);
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim());
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        if (!stop) {
          _fetchData();
          setState(() => _page++);
        }
      }
    });
  }

  /// جلب صفحة جديدة من الطلبات.
  /// إذا الـ backend أرجع قائمة فارغة → stop = true (لا مزيد من الصفحات).
  Future<void> _fetchData() async {
    try {
      final response = await dioClient
          .get('/mgr/getLeaveRequests?page=' + _page.toString());
      var data = response.data;
      if (data['leaverequests'].length > 0 && Lrequests.isEmpty) {
        for (var x = 0; x < data['leaverequests'].length; x++) {
          Leave l = Leave();
          if (data['leaverequests'][x]['status'] == "y") {
            l.status = AppLocalizations.of(context)!.accepted;
          } else if (data['leaverequests'][x]['status'] == "n") {
            l.status = AppLocalizations.of(context)!.refused;
          } else {
            l.status = AppLocalizations.of(context)!.pending;
          }
          if (data['leaverequests'][x]['nodays'] != null) {
            l.nodays = int.parse(data['leaverequests'][x]['nodays']);
          }
          if (data['leaverequests'][x]['addeddays'] != null) {
            l.addeddays = int.parse(data['leaverequests'][x]['addeddays']);
          } else {
            l.addeddays = 0;
          }
          l.notice = data['leaverequests'][x]['notice'] ?? "";
          l.leavedate = data['leaverequests'][x]['leave_date'];
          l.leavedateto = data['leaverequests'][x]['leave_date_to'];
          l.type = data['leaverequests'][x]['type'];
          l.status_date = data['leaverequests'][x]['status_date'];
          l.id = data['leaverequests'][x]['id'];
          l.empname = data['leaverequests'][x]['employee_name'];
          l.emcd = data['leaverequests'][x]['empcode'];
          if (data['leaverequests'][x]['attachment'] != null)
            l.url = data['leaverequests'][x]['attachment'];
          setState(() => Lrequests.add(l));
        }
      } else {
        setState(() => stop = true);
      }
    } catch (e) {
      if (e is DioException) {
        logD('Upload failed: ${e.response?.data}');
      } else {
        logD('Unexpected error: $e');
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nodays.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _snack(String m) => SnackbarHelpers.show(context, m);

  Future<void> _reload() async {
    setState(() {
      Lrequests.clear();
      _page = 0;
      stop = false;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    await _fetchData();
  }

  Future<void> _accept(Leave req) async {
    try {
      final t = AppLocalizations.of(context)!;
      final isOut = _isExternalType(req.type);
      final response = await dioClient.post('/mgr/leaveStatus', data: {
        "id": req.id,
        if (isOut) "nodays": days,
        "status": "y",
      });
      if (response.data['success'] == true) {
        _snack(t.sent);
      } else {
        final msg = response.data['message'];
        if (msg == "morahalavac") _snack(t.morahalavac);
        else if (msg == "iqamaend") _snack(t.iqamaend);
        else if (msg == "notoday") _snack(t.noaccepttoday);
        else _snack(msg?.toString() ?? t.notsent);
      }
      await _reload();
    } on DioException catch (e) {
      _snack(parseDioError(e, isArabic: isArabic(context)));
    } catch (e) {
      logD('Leave action unexpected error: $e');
      _snack(
        isArabic(context)
            ? 'حدث خطأ غير متوقع. يُرجى المحاولة مرة أخرى.'
            : 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> _refuse(Leave req) async {
    try {
      final response = await dioClient.post('/mgr/leaveStatus',
          data: {"id": req.id, "status": "n"});
      _snack(response.data['message']?.toString() ??
          AppLocalizations.of(context)!.sent);
      await _reload();
    } on DioException catch (e) {
      _snack(parseDioError(e, isArabic: isArabic(context)));
    } catch (e) {
      logD('Leave action unexpected error: $e');
      _snack(
        isArabic(context)
            ? 'حدث خطأ غير متوقع. يُرجى المحاولة مرة أخرى.'
            : 'Something went wrong. Please try again.',
      );
    }
  }

  StatusBadge _badgeFor(BuildContext context, String status) {
    final t = AppLocalizations.of(context)!;
    if (status == t.accepted) return StatusBadge.accepted(status);
    if (status == t.refused) return StatusBadge.refused(status);
    return StatusBadge.pending(status);
  }

  bool _isExternalType(String? type) =>
      (type ?? '').contains('خارجية');

  bool _isInternalType(String? type) =>
      (type ?? '').contains('داخلية');

  bool _isRegularType(String? type) =>
      _isExternalType(type) || _isInternalType(type);

  bool _isSpecialType(String? type) {
    final t = (type ?? '').trim();
    return t.isNotEmpty && !_isRegularType(type);
  }

  List<Leave> get _filteredRequests {
    if (_query.isEmpty) return Lrequests;
    final q = _query.toLowerCase();
    return Lrequests.where((l) {
      return (l.empname ?? '').toLowerCase().contains(q) ||
          (l.emcd ?? '').toLowerCase().contains(q) ||
          (l.type ?? '').toLowerCase().contains(q) ||
          (l.status ?? '').toLowerCase().contains(q) ||
          (l.leavedate ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final list = _filteredRequests;
    return ModernScaffold(
      title: t.leaverequests,
      subtitle:
          bi(context, ar: "مراجعة طلبات الإجازة", en: "Review leave requests"),
      leadingIcon: Icons.rule_folder_rounded,
      body: Column(
        children: [
          _buildSearchBar(context),
          Expanded(
            child: Lrequests.isEmpty
                ? ListView(children: [
                    const SizedBox(height: 60),
                    EmptyState(
                      icon: Icons.inbox_rounded,
                      title: t.nodata,
                      subtitle: bi(context,
                          ar: "لا توجد طلبات للمراجعة.",
                          en: "No requests to review."),
                    ),
                  ])
                : list.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off_rounded,
                        title: bi(context,
                            ar: "لا توجد نتائج مطابقة",
                            en: "No matching results"),
                        subtitle: bi(context,
                            ar: "جرّب كلمة بحث أخرى.",
                            en: "Try a different search term."),
                        accent: AppColors.secondary,
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding:
                            const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildCard(context, list[index]),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.soft,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: bi(context,
                      ar:
                          "ابحث بالاسم أو الرقم أو نوع الإجازة...",
                      en:
                          "Search by name, ID, or leave type..."),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: AppColors.muted),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: AppColors.muted),
                          onPressed: () {
                            _searchController.clear();
                            FocusScope.of(context).unfocus();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 14),
                ),
              ),
            ),
          ),
          if (_query.isNotEmpty) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                "${_filteredRequests.length}",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, Leave item) {
    final t = AppLocalizations.of(context)!;
    final isPending = item.status == t.pending;
    final isOut = _isExternalType(item.type);
    final isSpecial = _isSpecialType(item.type);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isSpecial ? AppColors.danger : AppColors.border,
          width: isSpecial ? 2 : 1,
        ),
        boxShadow: isSpecial
            ? [
                BoxShadow(
                  color: AppColors.danger.withOpacity(0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ]
            : AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Highly prominent banner for non-regular vacations
          if (isSpecial)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFFDC2626),
                    Color(0xFFEF4444),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.lg),
                  topRight: Radius.circular(AppRadius.lg),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.priority_high_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bi(context,
                              ar: "تنبيه: إجازة غير اعتيادية",
                              en: "Attention: Non-standard leave"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          bi(context,
                              ar:
                                  "يُرجى المراجعة الدقيقة قبل الاعتماد — ${item.type ?? ''}",
                              en:
                                  "Please review carefully before approval — ${item.type ?? ''}"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isSpecial
                            ? const Color(0xFFDC2626)
                            : AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(AppRadius.sm),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (item.empname ?? '?').isNotEmpty
                            ? item.empname![0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.empname ?? '-',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${t.empcode}: ${item.emcd ?? ''}",
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.status != null)
                      _badgeFor(context, item.status!),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 8),
                DetailRow(
                  icon: Icons.merge_type_rounded,
                  label: bi(context, ar: "النوع", en: "Type"),
                  value: item.type ?? '-',
                  color: isSpecial
                      ? AppColors.danger
                      : AppColors.secondary,
                ),
                DetailRow(
                  icon: Icons.flight_takeoff_rounded,
                  label: bi(context, ar: "من", en: "From"),
                  value: item.leavedate ?? '-',
                ),
                DetailRow(
                  icon: Icons.flight_land_rounded,
                  label: bi(context, ar: "إلى", en: "To"),
                  value: item.leavedateto ?? '-',
                ),
                DetailRow(
                  icon: Icons.timelapse_rounded,
                  label: t.nodays,
                  value: '${item.nodays ?? 0}',
                  color: AppColors.warning,
                ),
                DetailRow(
                  icon: Icons.add_circle_outline_rounded,
                  label: t.addedays,
                  value: '${item.addeddays ?? 0}',
                  color: AppColors.accent,
                ),
                if (item.notice != null && item.notice!.isNotEmpty)
                  DetailRow(
                    icon: Icons.notes_rounded,
                    label: t.notes,
                    value: item.notice!,
                  ),
                if (item.status_date != null)
                  DetailRow(
                    icon: Icons.event_available_rounded,
                    label: t.statusdate,
                    value: item.status_date!,
                    color: AppColors.primary,
                  ),
                if (item.url != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Image.network(
                      'https://cloud.shubra.net/uploads/' +
                          item.url.toString(),
                      errorBuilder: (_, __, ___) => Container(
                        padding: const EdgeInsets.all(20),
                        color: AppColors.surfaceAlt,
                        child: Icon(Icons.broken_image,
                            color: AppColors.muted),
                      ),
                    ),
                  ),
                ],
                if (isPending) ...[
                  if (isOut) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nodays,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: t.nodays,
                        prefixIcon: const Icon(
                            Icons.timelapse_rounded,
                            color: AppColors.primary,
                            size: 20),
                      ),
                      onChanged: (v) => days = v,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _accept(item),
                          icon: const Icon(Icons.check_rounded,
                              size: 18),
                          label: Text(t.accept),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _refuse(item),
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: AppColors.danger),
                          label: Text(t.refuse,
                              style: const TextStyle(
                                  color: AppColors.danger)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: AppColors.danger, width: 1.4),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
