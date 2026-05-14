// ============================================================================
// ملف: shared/widgets/paginated_list_view.dart
// الغرض: قائمة قابلة للترقيم (Pagination) بنمط موحّد لكل الشاشات.
// لماذا نحتاجها: كل شاشة بها قائمة (إجازات، قروض، إشعارات، ...) تكرّر نفس
//              الفروع: تحميل أولي → قائمة فارغة → بناء العناصر → سحب للتحديث.
//              هذا الـ widget يلخّصها في مكان واحد.
// كيف يُستخدم: تمرير items, isLoading, itemBuilder, emptyState, onRefresh.
// ============================================================================

import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets.dart';

/// Generic list scaffolding for paginated screens.
///
/// Collapses the repeated `Loader → EmptyState → ListView.builder` pattern
/// into one widget. The host owns its own data + scroll controller; this
/// only handles the rendering branches and pull-to-refresh wiring.
///
/// شرح المعاملات:
/// - [items]:        قائمة العناصر الحالية (يديرها الـ host).
/// - [isLoading]:    هل يوجد طلب جلب جارٍ؟ (يحدّد عرض skeleton).
/// - [controller]:   ScrollController (عادةً من InfiniteScrollMixin).
/// - [itemBuilder]:  دالة بناء كل عنصر (مثل ListView.builder).
/// - [emptyState]:   widget يُعرض عندما تكون القائمة فارغة بعد التحميل.
/// - [padding]:      الهوامش الداخلية للقائمة.
/// - [onRefresh]:    دالة السحب للتحديث (اختياري).
class PaginatedListView<T> extends StatelessWidget {
  final List<T> items;
  final bool isLoading;
  final ScrollController? controller;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final EmptyState emptyState;
  final EdgeInsetsGeometry padding;
  final Future<void> Function()? onRefresh;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.isLoading,
    required this.itemBuilder,
    required this.emptyState,
    this.controller,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 24),
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    // إذا لم يُمَرَّر onRefresh — نعرض القائمة فقط بدون سحب للتحديث.
    if (onRefresh == null) return body;
    // وإلا — نلفّها بـ RefreshIndicator بلون التطبيق الأساسي.
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh!,
      child: body,
    );
  }

  /// يحدد ما الذي نعرضه: skeleton أو empty state أو القائمة الفعلية.
  Widget _buildBody() {
    // الحالة 1: تحميل أولي (لا يوجد عناصر بعد) → نعرض هياكل وهمية (skeleton).
    if (isLoading && items.isEmpty) {
      return const SkeletonList();
    }
    // الحالة 2: انتهى التحميل والقائمة فارغة → نعرض widget الـ empty.
    if (items.isEmpty) {
      // نستعمل ListView لتفعيل سحب التحديث حتى عند الفراغ.
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [const SizedBox(height: 60), emptyState],
      );
    }
    // الحالة 3: لدينا عناصر → نبني القائمة الفعلية.
    return ListView.builder(
      controller: controller,
      padding: padding,
      // AlwaysScrollableScrollPhysics مهمة لكي يعمل RefreshIndicator حتى لو
      // كانت القائمة قصيرة (لا تملأ الشاشة).
      physics: const AlwaysScrollableScrollPhysics(),
      // +1 لإضافة skeleton أسفل القائمة عند تحميل صفحة إضافية.
      itemCount: items.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        // العنصر الأخير عند التحميل = مؤشر "جاري جلب المزيد".
        if (index == items.length && isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SkeletonListTile(),
          );
        }
        // عنصر عادي — نُحَوّله للـ host عبر itemBuilder.
        return itemBuilder(context, items[index], index);
      },
    );
  }
}
