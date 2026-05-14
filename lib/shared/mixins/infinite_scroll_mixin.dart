// ============================================================================
// ملف: shared/mixins/infinite_scroll_mixin.dart
// الغرض: Mixin يُضاف لأي StatefulWidget يحتاج تحميل صفحات إضافية عند الـ scroll.
// متى يُستخدم: في قوائم طويلة من الـ backend (الإجازات، القروض، الإشعارات، الزملاء).
// كيف يُستخدم:
//   1) أضف `with InfiniteScrollMixin<MyWidget>` لـ State.
//   2) عرّف `bool get hasMore` و `bool get isLoading`.
//   3) عرّف `Future<void> onLoadMore()` — استدعاء الـ backend للصفحة التالية.
//   4) أضف `controller: scrollController` للقائمة (ListView / ScrollView).
// الميزات: يمنع التحميل المكرر تلقائياً (يتحقق من isLoading قبل النداء).
// ============================================================================

import 'package:flutter/material.dart';

/// Wires a [ScrollController] that fires [onLoadMore] when the user nears
/// the end of the list (within 100px), as long as the host's [hasMore] flag
/// is true and a load isn't already in flight.
///
/// Hosts must:
///   - mix this in on a `State<T>`
///   - expose `bool get hasMore` and `bool get isLoading`
///   - implement `Future<void> onLoadMore()`
///   - assign `controller: scrollController` on their list widget
mixin InfiniteScrollMixin<T extends StatefulWidget> on State<T> {
  /// المتحكم في الـ scroll — يُمَرَّر للقائمة (ListView, GridView, ...).
  final ScrollController scrollController = ScrollController();

  /// هل توجد صفحات متبقية لجلبها؟ يحدّدها الـ host (يعود true حتى آخر صفحة).
  bool get hasMore;

  /// هل يوجد طلب جلب مفتوح حالياً؟ (نمنع الازدواج).
  bool get isLoading;

  /// نداء الـ backend لجلب الصفحة التالية. يُنفّذه الـ host.
  Future<void> onLoadMore();

  @override
  void initState() {
    super.initState();
    // تسجيل listener عند بدء الـ State — يتم استدعاؤه عند كل scroll event.
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    // عند تدمير الـ widget: نزع listener ثم تحرير الـ controller (لتفادي memory leaks).
    scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// يُستدعى مع كل scroll. لا يفعل شيئاً ما لم يكن:
  ///   - يوجد صفحات إضافية (hasMore).
  ///   - لا يوجد تحميل جاري (!isLoading).
  ///   - المستخدم قرب نهاية القائمة (آخر 100 بكسل).
  void _onScroll() {
    if (!hasMore || isLoading) return;
    final position = scrollController.position;
    // pixels = موقع الـ scroll الحالي، maxScrollExtent = أقصى موقع ممكن.
    // إذا اقترب الفارق من 100 بكسل → نحمل الصفحة التالية.
    if (position.pixels >= position.maxScrollExtent - 100) {
      onLoadMore();
    }
  }
}
