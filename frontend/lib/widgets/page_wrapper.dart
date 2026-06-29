import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/navigation_config.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';

/// Standard page chrome used by every screen inside the shell.
///
/// Provides:
/// - Breadcrumb trail (auto-derived from the current route)
/// - Page title + optional description
/// - Primary action buttons (right-aligned)
/// - Optional search field
/// - Optional filter bar
/// - Body content area
/// - Optional pagination bar
/// - Built-in loading / error / empty states
class ApexPageWrapper extends StatefulWidget {
  const ApexPageWrapper({
    super.key,
    required this.title,
    this.description,
    this.actions = const [],
    this.filterBar,
    required this.body,
    this.showSearch = false,
    this.searchHint = 'Search...',
    this.onSearch,
    this.searchController,
    this.onRefresh,
    this.onExport,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.isEmpty = false,
    this.emptyIcon,
    this.emptyTitle,
    this.emptySubtitle,
    this.emptyAction,
    this.pagination,
    this.padding,
    this.scrollable = false,
  });

  final String title;
  final String? description;

  /// Buttons in the top-right (primary action, secondary action, etc.).
  final List<Widget> actions;

  /// Optional filter row rendered below the title bar.
  final Widget? filterBar;

  /// Main content.  If [scrollable] is false (default), this is placed in an
  /// [Expanded] and must manage its own scroll.  If true, it is wrapped in
  /// [SingleChildScrollView].
  final Widget body;

  // ── Search ────────────────────────────────────────────────────────────────
  final bool showSearch;
  final String? searchHint;
  final ValueChanged<String>? onSearch;
  final TextEditingController? searchController;

  // ── Toolbar actions ───────────────────────────────────────────────────────
  final VoidCallback? onRefresh;
  final VoidCallback? onExport;

  // ── States ────────────────────────────────────────────────────────────────
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;

  final bool isEmpty;
  final IconData? emptyIcon;
  final String? emptyTitle;
  final String? emptySubtitle;
  final Widget? emptyAction;

  // ── Footer ────────────────────────────────────────────────────────────────
  final Widget? pagination;

  // ── Layout ────────────────────────────────────────────────────────────────
  final EdgeInsets? padding;
  final bool scrollable;

  @override
  State<ApexPageWrapper> createState() => _ApexPageWrapperState();
}

class _ApexPageWrapperState extends State<ApexPageWrapper> {
  late final TextEditingController _searchCtrl;
  bool _ownController = false;

  @override
  void initState() {
    super.initState();
    if (widget.searchController != null) {
      _searchCtrl = widget.searchController!;
    } else {
      _searchCtrl = TextEditingController();
      _ownController = true;
    }
  }

  @override
  void dispose() {
    if (_ownController) _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PageHeader(
          title: widget.title,
          description: widget.description,
          actions: widget.actions,
          showSearch: widget.showSearch,
          searchHint: widget.searchHint ?? 'Search...',
          searchCtrl: _searchCtrl,
          onSearch: widget.onSearch,
          onRefresh: widget.onRefresh,
          onExport: widget.onExport,
        ),
        if (widget.filterBar != null) ...[
          widget.filterBar!,
          const Divider(height: 1),
        ],
        Expanded(
          child: _buildBody(),
        ),
        if (widget.pagination != null) widget.pagination!,
      ],
    );
  }

  Widget _buildBody() {
    if (widget.isLoading) return const _LoadingState();
    if (widget.error != null) {
      return _ErrorState(message: widget.error!, onRetry: widget.onRetry);
    }
    if (widget.isEmpty) {
      return _EmptyState(
        icon: widget.emptyIcon,
        title: widget.emptyTitle,
        subtitle: widget.emptySubtitle,
        action: widget.emptyAction,
      );
    }
    final padding = widget.padding ?? const EdgeInsets.all(20);
    if (widget.scrollable) {
      return SingleChildScrollView(padding: padding, child: widget.body);
    }
    return widget.body;
  }
}

// ─── Page Header ─────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.description,
    required this.actions,
    required this.showSearch,
    required this.searchHint,
    required this.searchCtrl,
    required this.onSearch,
    required this.onRefresh,
    required this.onExport,
  });

  final String title;
  final String? description;
  final List<Widget> actions;
  final bool showSearch;
  final String searchHint;
  final TextEditingController searchCtrl;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onRefresh;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    final route = GoRouterState.of(context).matchedLocation;
    final crumbs = NavigationConfig.breadcrumbsFor(route);

    return Container(
      color: ApexColors.neutral0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Breadcrumbs
          _Breadcrumbs(crumbs: crumbs),
          // Title bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 16, 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final titleColumn = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: ApexTypography.dashboardTitle),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(description!, style: ApexTypography.dashboardSubtitle),
                    ],
                  ],
                );
                final toolbar = _ToolbarActions(
                  actions: actions,
                  showSearch: showSearch,
                  searchHint: searchHint,
                  searchCtrl: searchCtrl,
                  onSearch: onSearch,
                  onRefresh: onRefresh,
                  onExport: onExport,
                );

                if (constraints.maxWidth < 760) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleColumn,
                      const SizedBox(height: 12),
                      toolbar,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: titleColumn),
                    toolbar,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

// ─── Breadcrumbs ─────────────────────────────────────────────────────────────

class _Breadcrumbs extends StatelessWidget {
  const _Breadcrumbs({required this.crumbs});
  final List<BreadcrumbEntry> crumbs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
      child: Wrap(
        spacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (int i = 0; i < crumbs.length; i++) ...[
            if (i > 0)
              Icon(Icons.chevron_right, size: 14, color: ApexColors.neutral300),
            GestureDetector(
              onTap: i < crumbs.length - 1
                  ? () => GoRouter.of(context).go(crumbs[i].route)
                  : null,
              child: Text(
                crumbs[i].label,
                style: ApexTypography.captionSmall.copyWith(
                  color: i == crumbs.length - 1
                      ? ApexColors.neutral700
                      : ApexColors.neutral400,
                  fontWeight: i == crumbs.length - 1
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Toolbar Actions ─────────────────────────────────────────────────────────

class _ToolbarActions extends StatelessWidget {
  const _ToolbarActions({
    required this.actions,
    required this.showSearch,
    required this.searchHint,
    required this.searchCtrl,
    required this.onSearch,
    required this.onRefresh,
    required this.onExport,
  });

  final List<Widget> actions;
  final bool showSearch;
  final String searchHint;
  final TextEditingController searchCtrl;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onRefresh;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSearch) ...[
          SizedBox(
            width: 220,
            height: 36,
            child: TextField(
              controller: searchCtrl,
              onChanged: onSearch,
              style: ApexTypography.body,
              decoration: InputDecoration(
                hintText: searchHint,
                hintStyle: ApexTypography.body.copyWith(color: ApexColors.neutral400),
                prefixIcon: const Icon(Icons.search, size: 18, color: ApexColors.neutral400),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
                filled: true,
                fillColor: ApexColors.neutral50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: ApexColors.neutral200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: ApexColors.neutral200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: ApexColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (onRefresh != null)
          _IconBtn(icon: Icons.refresh_outlined, tooltip: 'Refresh', onTap: onRefresh!),
        if (onExport != null) ...[
          const SizedBox(width: 4),
          _IconBtn(icon: Icons.download_outlined, tooltip: 'Export', onTap: onExport!),
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(width: 8),
          ...actions,
        ],
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            border: Border.all(color: ApexColors.neutral200),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 18, color: ApexColors.neutral600),
        ),
      ),
    );
  }
}

// ─── Loading State ────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 2),
          SizedBox(height: 16),
          Text('Loading...'),
        ],
      ),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: ApexColors.errorLight,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.error_outline, color: ApexColors.error, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Something went wrong', style: ApexTypography.cardTitle),
            const SizedBox(height: 6),
            Text(
              message,
              style: ApexTypography.caption.copyWith(color: ApexColors.neutral500),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.icon, this.title, this.subtitle, this.action});
  final IconData? icon;
  final String? title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: ApexColors.neutral100,
                borderRadius: BorderRadius.circular(36),
              ),
              child: Icon(
                icon ?? Icons.inbox_outlined,
                size: 36,
                color: ApexColors.neutral400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title ?? 'No records found',
              style: ApexTypography.cardTitle.copyWith(color: ApexColors.neutral700),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: ApexTypography.caption.copyWith(color: ApexColors.neutral500),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Standard Pagination Bar ──────────────────────────────────────────────────

class ApexPaginationBar extends StatelessWidget {
  const ApexPaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.pageSize,
    required this.onPageChanged,
  });

  final int page;
  final int totalPages;
  final int total;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final start = total == 0 ? 0 : (page - 1) * pageSize + 1;
    final end = (page * pageSize).clamp(0, total);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: ApexColors.neutral0,
        border: Border(top: BorderSide(color: ApexColors.neutral200)),
      ),
      child: Row(
        children: [
          Text(
            'Showing $start–$end of $total',
            style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500),
          ),
          const Spacer(),
          _PagBtn(
            icon: Icons.first_page,
            onTap: page > 1 ? () => onPageChanged(1) : null,
          ),
          _PagBtn(
            icon: Icons.chevron_left,
            onTap: page > 1 ? () => onPageChanged(page - 1) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Page $page of $totalPages',
              style: ApexTypography.captionMedium,
            ),
          ),
          _PagBtn(
            icon: Icons.chevron_right,
            onTap: page < totalPages ? () => onPageChanged(page + 1) : null,
          ),
          _PagBtn(
            icon: Icons.last_page,
            onTap: page < totalPages ? () => onPageChanged(totalPages) : null,
          ),
        ],
      ),
    );
  }
}

class _PagBtn extends StatelessWidget {
  const _PagBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: onTap,
      color: onTap != null ? ApexColors.neutral600 : ApexColors.neutral300,
      splashRadius: 18,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}
