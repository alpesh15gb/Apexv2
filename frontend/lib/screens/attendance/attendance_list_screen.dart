import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/employee_provider.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/page_wrapper.dart';

class AttendanceListScreen extends ConsumerStatefulWidget {
  const AttendanceListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends ConsumerState<AttendanceListScreen> {
  String _search = '';
  DateTime _selectedDate = DateTime.now();
  String? _deptFilter;
  String? _shiftFilter;
  String? _statusFilter;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFilters();
    });
  }

  void _updateFilters() {
    final dateStr = _selectedDate.toIso8601String().substring(0, 10);
    ref.read(attendanceListProvider.notifier).setFilters(
      fromDate: dateStr,
      toDate: dateStr,
      departmentId: _deptFilter,
      status: _statusFilter,
      search: _search,
    );
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final listState = ref.watch(attendanceListProvider);
    final deptsAsync = ref.watch(departmentsProvider);
    final dateStr = _selectedDate.toIso8601String().substring(0, 10);
    final summaryAsync = ref.watch(dailySummaryProvider(dateStr));

    return Scaffold(
      backgroundColor: isDark ? ApexColors.darkBackground : ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Attendance Register',
        description: 'Detailed attendance grid, filters, and status override actions.',
        showSearch: true,
        searchHint: 'Search employee...',
        onSearch: (v) => setState(() {
          _search = v;
          _updateFilters();
        }),
        onRefresh: () => ref.read(attendanceListProvider.notifier).fetchRecords(isRefresh: true),
        actions: [
          ApexButton(
            label: 'Summary',
            icon: Icons.summarize_outlined,
            type: ApexButtonType.ghost,
            onPressed: () => context.push('/attendance/summary'),
          ),
          ApexButton(
            label: 'Mark Attendance',
            icon: Icons.edit_calendar_outlined,
            type: ApexButtonType.primary,
            onPressed: () => context.push('/attendance/mark'),
          ),
        ],
        filterBar: _Toolbar(
          search: _search,
          onSearch: (v) => setState(() {
            _search = v;
            _updateFilters();
          }),
          selectedDate: _selectedDate,
          onDateChanged: (v) => setState(() {
            _selectedDate = v;
            _updateFilters();
          }),
          deptFilter: _deptFilter,
          shiftFilter: _shiftFilter,
          statusFilter: _statusFilter,
          onDeptChanged: (v) => setState(() {
            _deptFilter = v;
            _updateFilters();
          }),
          onShiftChanged: (v) => setState(() {
            _shiftFilter = v;
            _updateFilters();
          }),
          onStatusChanged: (v) => setState(() {
            _statusFilter = v;
            _updateFilters();
          }),
          onClear: () => setState(() {
            _deptFilter = null;
            _shiftFilter = null;
            _statusFilter = null;
            _updateFilters();
          }),
          deptsAsync: deptsAsync,
        ),
        body: Column(
          children: [
            summaryAsync.when(
              data: (s) => _SummaryCards(summary: s),
              loading: () => const SizedBox(height: 12),
              error: (_, __) => const SizedBox(),
            ),
            if (_selected.isNotEmpty)
              _BulkBar(count: _selected.length, onClear: () => setState(() => _selected.clear())),
            Expanded(
              child: listState.records.when(
                data: (records) {
                  if (records.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 48, color: isDark ? ApexColors.darkOnSurfaceVariant : ApexColors.neutral400),
                          const SizedBox(height: 16),
                          Text('No Attendance Records', style: ApexTypography.cardTitle),
                          const SizedBox(height: 8),
                          Text('No attendance data for the selected filters.', style: ApexTypography.caption),
                          const SizedBox(height: 16),
                          ApexButton(
                            label: 'Mark Attendance',
                            onPressed: () => context.push('/attendance/mark'),
                            type: ApexButtonType.primary,
                          ),
                        ],
                      ),
                    );
                  }
                  return _AttendanceTable(
                    records: records,
                    selected: _selected,
                    onSelect: (id, v) => setState(() {
                      v ? _selected.add(id) : _selected.remove(id);
                    }),
                    onSelectAll: (v) => setState(() {
                      if (v) _selected.addAll(records.map((e) => e.id));
                      else _selected.clear();
                    }),
                    onTap: (r) => context.push('/attendance/detail?employeeId=${r.employeeId}'),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 40, color: ApexColors.error),
                      const SizedBox(height: 12),
                      Text('Error: ${e.toString()}', style: ApexTypography.bodySmall),
                      const SizedBox(height: 12),
                      ApexButton(
                        label: 'Retry',
                        onPressed: () => ref.read(attendanceListProvider.notifier).fetchRecords(isRefresh: true),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final String search;
  final ValueChanged<String> onSearch;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final String? deptFilter;
  final String? shiftFilter;
  final String? statusFilter;
  final ValueChanged<String?> onDeptChanged;
  final ValueChanged<String?> onShiftChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onClear;
  final AsyncValue deptsAsync;

  const _Toolbar({
    required this.search,
    required this.onSearch,
    required this.selectedDate,
    required this.onDateChanged,
    required this.deptFilter,
    required this.shiftFilter,
    required this.statusFilter,
    required this.onDeptChanged,
    required this.onShiftChanged,
    required this.onStatusChanged,
    required this.onClear,
    required this.deptsAsync,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      color: isDark ? ApexColors.darkSurface : ApexColors.neutral0,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _DatePicker(date: selectedDate, onChanged: onDateChanged),
          deptsAsync.maybeWhen(
            data: (deps) => _Chip(
              label: 'Department',
              value: deptFilter != null ? deps.firstWhere((d) => d.id == deptFilter, orElse: () => deps.first).name : null,
              onTap: () => _showDeptPicker(context, deps),
            ),
            orElse: () => const SizedBox(),
          ),
          _Chip(
            label: 'Status',
            value: statusFilter,
            onTap: () => _showStatusPicker(context),
          ),
          if (deptFilter != null || shiftFilter != null || statusFilter != null)
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear, size: 14),
              label: const Text('Clear'),
            ),
        ],
      ),
    );
  }

  void _showDeptPicker(BuildContext context, List<dynamic> deps) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Department'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: deps.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) return ListTile(title: const Text('All'), onTap: () { onDeptChanged(null); Navigator.pop(context); });
              final d = deps[i - 1];
              return ListTile(title: Text(d.name), onTap: () { onDeptChanged(d.id); Navigator.pop(context); });
            },
          ),
        ),
      ),
    );
  }

  void _showStatusPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('All'), onTap: () { onStatusChanged(null); Navigator.pop(context); }),
            ListTile(title: const Text('Present'), onTap: () { onStatusChanged('present'); Navigator.pop(context); }),
            ListTile(title: const Text('Absent'), onTap: () { onStatusChanged('absent'); Navigator.pop(context); }),
            ListTile(title: const Text('Late'), onTap: () { onStatusChanged('late'); Navigator.pop(context); }),
            ListTile(title: const Text('Half Day'), onTap: () { onStatusChanged('half_day'); Navigator.pop(context); }),
            ListTile(title: const Text('On Leave'), onTap: () { onStatusChanged('on_leave'); Navigator.pop(context); }),
          ],
        ),
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _DatePicker({required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? ApexColors.neutral600 : ApexColors.neutral200),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month, size: 16, color: isDark ? ApexColors.darkOnSurfaceVariant : ApexColors.neutral500),
            const SizedBox(width: 8),
            Text(DateFormat('dd MMM yyyy').format(date), style: ApexTypography.captionMedium.copyWith(color: isDark ? ApexColors.darkOnSurface : ApexColors.neutral700)),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _Chip({required this.label, this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(value ?? label, style: ApexTypography.captionMedium.copyWith(color: value != null ? ApexColors.primary : null)),
      selected: value != null,
      onSelected: (_) => onTap(),
      selectedColor: ApexColors.primary.withOpacity(0.1),
      side: BorderSide(color: value != null ? ApexColors.primary : ApexColors.neutral300),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final dynamic summary;
  const _SummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final present = summary.present;
    final absent = summary.absent;
    final late = summary.late;
    final leave = summary.onLeave;

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: [
            _SummaryCard(label: 'Present', value: '$present', color: ApexColors.success),
            _SummaryCard(label: 'Absent', value: '$absent', color: ApexColors.error),
            _SummaryCard(label: 'Late', value: '$late', color: ApexColors.warning),
            _SummaryCard(label: 'On Leave', value: '$leave', color: ApexColors.primary),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _SummaryCard(label: 'Present', value: '$present', color: ApexColors.success)),
          const SizedBox(width: 12),
          Expanded(child: _SummaryCard(label: 'Absent', value: '$absent', color: ApexColors.error)),
          const SizedBox(width: 12),
          Expanded(child: _SummaryCard(label: 'Late Check-in', value: '$late', color: ApexColors.warning)),
          const SizedBox(width: 12),
          Expanded(child: _SummaryCard(label: 'On Leave', value: '$leave', color: ApexColors.primary)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? ApexColors.darkSurface : ApexColors.neutral0,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? ApexColors.neutral700 : ApexColors.neutral200),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 32,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: ApexTypography.cardTitle.copyWith(fontWeight: FontWeight.w700, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(label, style: ApexTypography.captionSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkBar extends StatelessWidget {
  final int count;
  final VoidCallback onClear;

  const _BulkBar({required this.count, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      color: ApexColors.primary.withOpacity(0.05),
      child: Row(
        children: [
          Text('$count selected', style: ApexTypography.caption.copyWith(fontWeight: FontWeight.w600, color: ApexColors.primary)),
          const Spacer(),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Clear Selection'),
          ),
        ],
      ),
    );
  }
}

class _AttendanceTable extends StatelessWidget {
  final List<dynamic> records;
  final Set<String> selected;
  final Function(String, bool) onSelect;
  final Function(bool) onSelectAll;
  final Function(dynamic) onTap;

  const _AttendanceTable({required this.records, required this.selected, required this.onSelect, required this.onSelectAll, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? ApexColors.neutral700 : ApexColors.neutral200;
    final headerColor = isDark ? ApexColors.darkSurfaceVariant : ApexColors.neutral50;
    final rowEvenColor = isDark ? ApexColors.darkSurface : ApexColors.neutral0;
    final rowOddColor = isDark ? ApexColors.darkSurfaceVariant : ApexColors.neutral50;
    final cellTextColor = isDark ? ApexColors.darkOnSurface : ApexColors.neutral800;

    return Container(
      decoration: BoxDecoration(color: isDark ? ApexColors.darkSurface : ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
      child: Column(
        children: [
          // Sticky header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: headerColor,
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Checkbox(
                    value: selected.length == records.length && records.isNotEmpty,
                    onChanged: (v) => onSelectAll(v ?? false),
                  ),
                ),
                Expanded(flex: 3, child: Text('EMPLOYEE', style: ApexTypography.tableHeader, overflow: TextOverflow.ellipsis)),
                Expanded(flex: 2, child: Text('CHECK IN', style: ApexTypography.tableHeader, overflow: TextOverflow.ellipsis)),
                Expanded(flex: 2, child: Text('CHECK OUT', style: ApexTypography.tableHeader, overflow: TextOverflow.ellipsis)),
                Expanded(flex: 2, child: Text('WORK HOURS', style: ApexTypography.tableHeader, overflow: TextOverflow.ellipsis)),
                SizedBox(width: 100, child: Text('STATUS', style: ApexTypography.tableHeader, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 40),
              ],
            ),
          ),
          // Scrollable body
          Expanded(
            child: ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, idx) {
                final r = records[idx];
                final status = r.status ?? 'absent';
                final employeeName = r.employeeName ?? '—';
                final employeeCode = r.employeeCode ?? '—';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: idx.isEven ? rowEvenColor : rowOddColor,
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Checkbox(
                          value: selected.contains(r.id),
                          onChanged: (v) => onSelect(r.id, v ?? false),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(employeeName, style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(employeeCode, style: ApexTypography.captionSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          r.punchIn != null ? DateFormat('hh:mm a').format(r.punchIn!.toLocal()) : '—',
                          style: ApexTypography.body.copyWith(color: cellTextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          r.punchOut != null ? DateFormat('hh:mm a').format(r.punchOut!.toLocal()) : '—',
                          style: ApexTypography.body.copyWith(color: cellTextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          r.totalHours != null ? '${r.totalHours!.toStringAsFixed(1)} hrs' : '—',
                          style: ApexTypography.body.copyWith(color: cellTextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: _StatusBadge(status: status),
                      ),
                      SizedBox(
                        width: 40,
                        child: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, size: 16, color: isDark ? ApexColors.darkOnSurfaceVariant : ApexColors.neutral500),
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'detail', child: Text('Detail View')),
                            const PopupMenuItem(value: 'override', child: Text('Manual Override')),
                          ],
                          onSelected: (v) {
                            if (v == 'detail') onTap(r);
                            if (v == 'override') context.push('/attendance/mark');
                          },
                        ),
                      ),
                    ],
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

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'present': return ApexBadge.success('PRESENT');
      case 'absent': return ApexBadge.danger('ABSENT');
      case 'late': return ApexBadge.warning('LATE');
      case 'on_leave': return ApexBadge.neutral('ON LEAVE');
      default: return ApexBadge.neutral(status.toUpperCase());
    }
  }
}
