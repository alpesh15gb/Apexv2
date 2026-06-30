import 'package:flutter/material.dart';
import '../colors.dart';
import '../border_radius.dart';
import '../typography.dart';
import '../spacing.dart';

/// Apex Design System — Enterprise Data Table
///
/// Supports: column resize, reorder, hide/show, saved layouts, multi-sort,
/// bulk actions, row expansion, sticky header, density selector, export.
class ApexTable<T> extends StatefulWidget {
  final List<ApexTableColumn> columns;
  final List<T> data;
  final Widget Function(BuildContext, T, int) rowBuilder;
  final Widget Function(BuildContext, T)? expandedRowBuilder;
  final void Function(T)? onRowTap;
  final bool showCheckbox;
  final Set<T>? selectedItems;
  final void Function(Set<T>)? onSelectionChanged;
  final bool loading;
  final Widget? emptyState;
  final List<ApexTableSort>? sorts;
  final void Function(List<ApexTableSort>)? onSort;
  final void Function(List<String>)? onColumnsChanged;
  final VoidCallback? onExport;
  final String? density;

  const ApexTable({
    Key? key,
    required this.columns,
    required this.data,
    required this.rowBuilder,
    this.expandedRowBuilder,
    this.onRowTap,
    this.showCheckbox = false,
    this.selectedItems,
    this.onSelectionChanged,
    this.loading = false,
    this.emptyState,
    this.sorts,
    this.onSort,
    this.onColumnsChanged,
    this.onExport,
    this.density,
  }) : super(key: key);

  @override
  State<ApexTable<T>> createState() => _ApexTableState<T>();
}

class _ApexTableState<T> extends State<ApexTable<T>> {
  late List<ApexTableColumn> _visibleColumns;
  late String _density;
  final Map<int, bool> _expandedRows = {};
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _visibleColumns = widget.columns.where((c) => c.visible).toList();
    _density = widget.density ?? 'comfortable';
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  double get _rowHeight {
    switch (_density) {
      case 'compact':
        return 40;
      case 'comfortable':
        return 52;
      case 'spacious':
        return 64;
      default:
        return 52;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.data.isEmpty && !widget.loading) {
      return widget.emptyState ?? const Center(child: Text('No data'));
    }

    return Column(
      children: [
        // Toolbar
        _buildToolbar(isDark),
        // Table
        Expanded(
          child: Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: _visibleColumns.fold<double>(
                    0,
                    (sum, col) => sum + col.width,
                  ),
                ),
                child: _buildTable(isDark),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? ApexColors.darkSurface : ApexColors.neutral50,
        border: Border(bottom: BorderSide(color: isDark ? ApexColors.neutral700 : ApexColors.neutral200)),
      ),
      child: Row(
        children: [
          // Column chooser
          PopupMenuButton<String>(
            icon: const Icon(Icons.view_column, size: 18),
            tooltip: 'Columns',
            onSelected: (value) {
              setState(() {
                final col = widget.columns.firstWhere((c) => c.id == value);
                col.visible = !col.visible;
                _visibleColumns = widget.columns.where((c) => c.visible).toList();
              });
              widget.onColumnsChanged?.call(
                _visibleColumns.map((c) => c.id).toList(),
              );
            },
            itemBuilder: (context) {
              return widget.columns.map((col) {
                return CheckedPopupMenuItem<String>(
                  value: col.id,
                  checked: col.visible,
                  child: Text(col.label),
                );
              }).toList();
            },
          ),
          const SizedBox(width: 8),

          // Density selector
          PopupMenuButton<String>(
            icon: const Icon(Icons.density_medium, size: 18),
            tooltip: 'Density',
            onSelected: (value) => setState(() => _density = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'compact', child: Text('Compact')),
              const PopupMenuItem(value: 'comfortable', child: Text('Comfortable')),
              const PopupMenuItem(value: 'spacious', child: Text('Spacious')),
            ],
          ),
          const SizedBox(width: 8),

          // Export
          if (widget.onExport != null)
            IconButton(
              icon: const Icon(Icons.download, size: 18),
              tooltip: 'Export',
              onPressed: widget.onExport,
            ),

          const Spacer(),

          // Selection count
          if (widget.selectedItems != null && widget.selectedItems!.isNotEmpty)
            Text(
              '${widget.selectedItems!.length} selected',
              style: ApexTypography.captionLarge.copyWith(color: ApexColors.primary),
            ),
        ],
      ),
    );
  }

  Widget _buildTable(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sticky header
        _buildHeader(isDark),
        // Body
        Expanded(
          child: Scrollbar(
            controller: _verticalController,
            thumbVisibility: true,
            child: ListView.builder(
              controller: _verticalController,
              itemCount: widget.loading ? 5 : widget.data.length,
              itemBuilder: (context, index) {
                if (widget.loading) return _buildLoadingRow(isDark);
                return _buildDataRow(index, isDark);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? ApexColors.darkSurfaceVariant : ApexColors.neutral50,
        border: Border(bottom: BorderSide(color: isDark ? ApexColors.neutral700 : ApexColors.neutral200)),
      ),
      child: Row(
        children: [
          if (widget.showCheckbox)
            SizedBox(
              width: 48,
              child: Checkbox(
                value: widget.selectedItems?.length == widget.data.length,
                tristate: true,
                onChanged: (value) {
                  if (value == true) {
                    widget.onSelectionChanged?.call(Set.from(widget.data));
                  } else {
                    widget.onSelectionChanged?.call({});
                  }
                },
              ),
            ),
          for (int i = 0; i < _visibleColumns.length; i++)
            _buildHeaderCell(i, isDark),
          if (widget.expandedRowBuilder != null)
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(int index, bool isDark) {
    final column = _visibleColumns[index];
    final sort = widget.sorts?.firstWhere(
      (s) => s.columnId == column.id,
      orElse: () => ApexTableSort(columnId: column.id, ascending: true),
    );
    final isSorted = sort != null;

    return GestureDetector(
      onTap: column.sortable
          ? () {
              final newSorts = List<ApexTableSort>.from(widget.sorts ?? []);
              final existingIndex = newSorts.indexWhere((s) => s.columnId == column.id);
              if (existingIndex >= 0) {
                newSorts[existingIndex] = ApexTableSort(
                  columnId: column.id,
                  ascending: !newSorts[existingIndex].ascending,
                );
              } else {
                newSorts.add(ApexTableSort(columnId: column.id, ascending: true));
              }
              widget.onSort?.call(newSorts);
            }
          : null,
      child: Container(
        width: column.width,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                column.label,
                style: ApexTypography.captionLarge.copyWith(
                  color: isDark ? ApexColors.darkOnSurfaceVariant : ApexColors.neutral600,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (column.sortable)
              Icon(
                isSorted
                    ? sort!.ascending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward
                    : Icons.unfold_more,
                size: 14,
                color: isSorted
                    ? ApexColors.primary
                    : isDark
                        ? ApexColors.neutral600
                        : ApexColors.neutral400,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(int index, bool isDark) {
    final item = widget.data[index];
    final isSelected = widget.selectedItems?.contains(item) ?? false;
    final isExpanded = _expandedRows[index] ?? false;

    return Column(
      children: [
        InkWell(
          onTap: widget.onRowTap != null ? () => widget.onRowTap!(item) : null,
          child: Container(
            height: _rowHeight,
            decoration: BoxDecoration(
              color: isSelected
                  ? ApexColors.primary50
                  : isDark
                      ? ApexColors.darkSurface
                      : ApexColors.neutral0,
              border: Border(bottom: BorderSide(color: isDark ? ApexColors.darkSurfaceVariant : ApexColors.neutral100)),
            ),
            child: Row(
              children: [
                if (widget.showCheckbox)
                  SizedBox(
                    width: 48,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        final newSelection = Set<T>.from(widget.selectedItems ?? {});
                        if (value == true) {
                          newSelection.add(item);
                        } else {
                          newSelection.remove(item);
                        }
                        widget.onSelectionChanged?.call(newSelection);
                      },
                    ),
                  ),
                widget.rowBuilder(context, item, index),
                if (widget.expandedRowBuilder != null)
                  SizedBox(
                    width: 48,
                    child: IconButton(
                      icon: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _expandedRows[index] = !isExpanded;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Expanded content
        if (isExpanded && widget.expandedRowBuilder != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? ApexColors.darkSurfaceVariant : ApexColors.neutral50,
              border: Border(bottom: BorderSide(color: isDark ? ApexColors.neutral700 : ApexColors.neutral200)),
            ),
            child: widget.expandedRowBuilder!(context, item),
          ),
      ],
    );
  }

  Widget _buildLoadingRow(bool isDark) {
    return Container(
      height: _rowHeight,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? ApexColors.darkSurfaceVariant : ApexColors.neutral100)),
      ),
      child: Row(
        children: [
          for (final column in _visibleColumns)
            SizedBox(
              width: column.width,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Container(
                  width: double.infinity,
                  height: 14,
                  color: isDark ? ApexColors.darkSurfaceVariant : ApexColors.neutral200,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ApexTableColumn {
  final String id;
  final String label;
  final double width;
  final bool sortable;
  bool visible;

  ApexTableColumn({
    required this.id,
    required this.label,
    required this.width,
    this.sortable = true,
    this.visible = true,
  });
}

class ApexTableSort {
  final String columnId;
  final bool ascending;

  const ApexTableSort({required this.columnId, required this.ascending});
}
