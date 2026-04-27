import 'package:flutter/material.dart';
import 'dio_client.dart';
import 'cust.dart';
import 'l10n/app_localizations.dart';
import 'theme.dart';
import 'widgets.dart';

/// Manager view for inspecting an employee's custody items by employee code.
class CustodyMgr extends StatefulWidget {
  @override
  _CustodyMgrState createState() => _CustodyMgrState();
}

class _CustodyMgrState extends State<CustodyMgr> {
  final ScrollController _scrollController = ScrollController();
  List<cust> Lrequests = [];
  bool _isLoading = false;
  bool stop = false;
  int _page = 1;
  bool _searched = false;

  final dioClient = DioClient().client;
  final TextEditingController _employeeIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (!stop && !_isLoading) {
        _fetchData(_employeeIdController.text);
      }
    }
  }

  Future<void> _fetchData(String code) async {
    if (code.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final response =
          await dioClient.get('/mgr/custody?empcode=$code&page=$_page');
      final data = response.data;
      final newCust = List<cust>.from(data['cust'].map((item) {
        final c = cust();
        c.name = item['cnnma'];
        c.date = item['usrdat'];
        return c;
      }));

      if (newCust.isEmpty) {
        stop = true;
      } else {
        setState(() {
          _page++;
          Lrequests.addAll(newCust);
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ModernScaffold(
      title: t.custody,
      subtitle: bi(context,
          ar: "البحث عن عهد الموظفين", en: "Search employee custody"),
      leadingIcon: Icons.dashboard_customize_rounded,
      body: Column(
        children: [
          // Search card
          Padding(
            padding: const EdgeInsets.all(16),
            child: GlassCard(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    LabeledField(
                      label: t.empcode,
                      controller: _employeeIdController,
                      icon: Icons.badge_outlined,
                      hint: t.empcode,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? t.enterempcode : null,
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label:
                          bi(context, ar: "بحث", en: "Search"),
                      icon: Icons.search_rounded,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            Lrequests.clear();
                            stop = false;
                            _page = 1;
                            _searched = true;
                          });
                          _fetchData(_employeeIdController.text);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: (!_searched)
                ? EmptyState(
                    icon: Icons.search_rounded,
                    title: bi(context,
                        ar: "ابحث برقم الموظف",
                        en: "Search by employee ID"),
                    subtitle: bi(context,
                        ar: "أدخل الرقم واضغط بحث لعرض العهد.",
                        en: "Enter an ID and tap search to view custody."),
                    accent: AppColors.secondary,
                  )
                : Lrequests.isEmpty && !_isLoading
                    ? EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: t.nodata,
                        subtitle: bi(context,
                            ar: "لا توجد عهد لهذا الموظف.",
                            en: "No custody items found."),
                        accent: AppColors.warning,
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount:
                            Lrequests.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == Lrequests.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: SkeletonListTile(),
                            );
                          }
                          final item = Lrequests[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppColors.warning
                                          .withOpacity(0.12),
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2_outlined,
                                      color: AppColors.warning,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name ?? '-',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                                Icons.calendar_today_rounded,
                                                size: 13,
                                                color: AppColors.muted),
                                            const SizedBox(width: 5),
                                            Text(
                                              item.date ?? '',
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                color: AppColors.muted,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
