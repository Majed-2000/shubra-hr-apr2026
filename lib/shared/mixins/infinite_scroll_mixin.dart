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
  final ScrollController scrollController = ScrollController();

  bool get hasMore;
  bool get isLoading;
  Future<void> onLoadMore();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!hasMore || isLoading) return;
    final position = scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 100) {
      onLoadMore();
    }
  }
}
