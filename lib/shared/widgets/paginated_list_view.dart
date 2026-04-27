import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets.dart';

/// Generic list scaffolding for paginated screens.
///
/// Collapses the repeated `Loader → EmptyState → ListView.builder` pattern
/// into one widget. The host owns its own data + scroll controller; this
/// only handles the rendering branches and pull-to-refresh wiring.
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
    if (onRefresh == null) return body;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh!,
      child: body,
    );
  }

  Widget _buildBody() {
    if (isLoading && items.isEmpty) {
      return const SkeletonList();
    }
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [const SizedBox(height: 60), emptyState],
      );
    }
    return ListView.builder(
      controller: controller,
      padding: padding,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length && isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SkeletonListTile(),
          );
        }
        return itemBuilder(context, items[index], index);
      },
    );
  }
}
