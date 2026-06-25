import 'package:flutter/material.dart';

class PaginatedList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Future<void> Function() onLoadMore;
  final bool hasMore;
  final bool isLoading;
  final Widget? emptyState;
  final Future<void> Function()? onRefresh;
  final EdgeInsetsGeometry? padding;

  const PaginatedList({
    Key? key,
    required this.items,
    required this.itemBuilder,
    required this.onLoadMore,
    required this.hasMore,
    this.isLoading = false,
    this.emptyState,
    this.onRefresh,
    this.padding,
  }) : super(key: key);

  @override
  State<PaginatedList<T>> createState() => _PaginatedListState<T>();
}

class _PaginatedListState<T> extends State<PaginatedList<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (widget.hasMore && !widget.isLoading) {
        widget.onLoadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      if (widget.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return widget.emptyState ?? const Center(child: Text('No items found.'));
    }

    final listView = ListView.builder(
      controller: _scrollController,
      padding: widget.padding ?? const EdgeInsets.all(16),
      itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return widget.itemBuilder(context, widget.items[index]);
      },
    );

    if (widget.onRefresh != null) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: listView,
      );
    }

    return listView;
  }
}
