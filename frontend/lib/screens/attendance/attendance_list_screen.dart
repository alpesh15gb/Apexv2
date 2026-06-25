import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/responsive.dart';
import '../../design_system/typography.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/employee_provider.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _warning = Color(0xFFF59E0B);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

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
  Widget build(BuildContext context) {
    final listState = ref.watch(attendanceListProvider);
    final deptsAsync = ref.watch(departmentsProvider);
    final dateStr = _selectedDate.toIso8601String().substring(0, 10);
    final summaryAsync = ref.watch(dailySummaryProvider(dateStr));
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // Header
          _Header(isMobile: isMobile),
          // Toolbar: Search | Date | Department | Shift | Status | Export
          _Toolbar(
            search: _search,
            onSearch: (v) => setState(() => _search = v),
            selectedDate: _selectedDate,
            onDateChanged: (v) => setState(() => _selectedDate = v),
            deptFilter: _deptFilter,
            shiftFilter: _shiftFilter,
            statusFilter: _statusFilter,
            onDeptChanged: (v) => setState(() => _deptFilter = v),
            onShiftChanged: (v) => setState(() => _shiftFilter = v),
            onStatusChanged: (v) => setState(() => _statusFilter = v),
            onClear: () => setState(() {
              _deptFilter = null;
              _shiftFilter = null;
              _statusFilter = null;
            }),
            deptsAsync: deptsAsync,
          ),
          // Summary cards
          summaryAsync.when(
            data: (s) => _SummaryCards(summary: s),
            loading: () => const SizedBox(height: 72),
            error: (_, __) => const SizedBox(),
          ),
          // Bulk bar
          if (_selected.isNotEmpty)
            _BulkBar(count: _selected.length, onClear: () => setState(() => _selected.clear())),
          // Attendance table
          Expanded(
            child: listState.records.when(
              data: (records) {
                if (records.isEmpty) {
                  return _EmptyState(
                    icon: Icons.calendar_today_outlined,
                    title: 'No Attendance Records',
                    description: 'No attendance data for the selected filters.',
                    actionLabel: 'Mark Attendance',
                    onAction: () => context.push('/attendance/mark'),
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
                    const Icon(Icons.error_outline, size: 40, color: _danger),
                    const SizedBox(height: 12),
                    Text('Error: ${e.toString()}', style: ApexTypography.bodySmall),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.read(attendanceListProvider.notifier).fetchRecords(isRefresh: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool isMobile;
  const _Header({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 20, 12, isMobile ? 16 : 20, 8),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Text('Attendance', style: ApexTypography.pageTitle.copyWith(color: _text)),
          const Spacer(),
          if (!isMobile) ...[
            IconButton(icon: const Icon(Icons.add_task, size: 18), tooltip: 'Manual Mark', onPressed: () => context.push('/attendance/mark')),
            IconButton(icon: const Icon(Icons.summarize_outlined, size: 18), tooltip: 'Summary', onPressed: () => context.push('/attendance/summary')),
          ],
        ],
      ),
    );
  }
}

// ── Toolbar ─────────────────────────────────────────────────
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Search
          SizedBox(
            width: 200,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search employee...',
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: _border)),
                isDense: true,
              ),
              onChanged: onSearch,
            ),
          ),
          // Date picker
          _DatePicker(date: selectedDate, onChanged: onDateChanged),
          // Department
          deptsAsync.maybeWhen(
            data: (deps) => _Chip(
              label: 'Department',
              value: deptFilter != null ? deps.firstWhere((d) => d.id == deptFilter, orElse: () => deps.first).name : null,
              onTap: () => _showDeptPicker(context, deps),
            ),
            orElse: () => const SizedBox(),
          ),
          // Status
          _Chip(
            label: 'Status',
            value: statusFilter,
            onTap: () => _showStatusPicker(context),
          ),
          // Clear
          if (deptFilter != null || shiftFilter != null || statusFilter != null)
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear, size: 14),
              label: const Text('Clear'),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
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
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 16, color: _muted),
            const SizedBox(width: 6),
            Text(DateFormat('MMM dd, yyyy').format(date), style: ApexTypography.bodySmall),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: value != null ? _primary.withOpacity(0.1) : null,
          border: Border.all(color: value != null ? _primary : _border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value ?? label, style: ApexTypography.captionLarge.copyWith(color: value != null ? _primary : _muted)),
            const SizedBox(width: 4),
            Icon(value != null ? Icons.close : Icons.arrow_drop_down, size: 14, color: value != null ? _primary : _muted),
          ],
        ),
      ),
    );
  }
}

// ── Summary Cards ───────────────────────────────────────────
class _SummaryCards extends StatelessWidget {
  final dynamic summary;
  const _SummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _SummaryItem(label: 'Present', value: '${summary.present}', color: _success),
          _SummaryItem(label: 'Absent', value: '${summary.absent}', color: _danger),
          _SummaryItem(label: 'Late', value: '${summary.late}', color: _warning),
          _SummaryItem(label: 'Half Day', value: '${summary.halfDay}', color: _warning),
          _SummaryItem(label: 'Leave', value: '${summary.onLeave}', color: _primary),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: ApexTypography.headingMedium.copyWith(color: color)),
            Text(label, style: ApexTypography.kpiLabel),
          ],
        ),
      ),
    );
  }
}

// ── Bulk Bar ────────────────────────────────────────────────
class _BulkBar extends StatelessWidget {
  final int count;
  final VoidCallback onClear;

  const _BulkBar({required this.count, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: _primary.withOpacity(0.1),
      child: Row(
        children: [
          Text('$count selected', style: ApexTypography.titleSmall.copyWith(color: _primary)),
          const Spacer(),
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.check, size: 16), label: const Text('Approve')),
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.download, size: 16), label: const Text('Export')),
          TextButton(onPressed: onClear, child: const Text('Clear')),
        ],
      ),
    );
  }
}

// ── Attendance Table ────────────────────────────────────────
class _AttendanceTable extends StatelessWidget {
  final List<dynamic> records;
  final Set<String> selected;
  final void Function(String, bool) onSelect;
  final void Function(bool) onSelectAll;
  final void Function(dynamic) onTap;

  const _AttendanceTable({
    required this.records,
    required this.selected,
    required this.onSelect,
    required this.onSelectAll,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 1200),
        child: Column(
          children: [
            // Header
            Container(
              height: 36,
              color: _bg,
              child: Row(
                children: [
                  _hdr(40, '', isCheckbox: true),
                  _hdr(160, 'EMPLOYEE'),
                  _hdr(100, 'SHIFT'),
                  _hdr(80, 'CLOCK IN'),
                  _hdr(80, 'CLOCK OUT'),
                  _hdr(70, 'HOURS'),
                  _hdr(60, 'OT'),
                  _hdr(70, 'LATE BY'),
                  _hdr(70, 'EARLY OUT'),
                  _hdr(80, 'DEVICE'),
                  _hdr(80, 'STATUS'),
                  _hdr(60, ''),
                ],
              ),
            ),
            // Rows
            Expanded(
              child: ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, i) => _AttendanceRow(
                  record: records[i],
                  index: i,
                  isSelected: selected.contains(records[i].id),
                  onSelect: (v) => onSelect(records[i].id, v),
                  onTap: () => onTap(records[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hdr(double width, String label, {bool isCheckbox = false}) {
    return SizedBox(
      width: width,
      child: isCheckbox
          ? Checkbox(value: false, onChanged: (v) => onSelectAll(v ?? false), visualDensity: VisualDensity.compact)
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(alignment: Alignment.centerLeft, child: Text(label, style: ApexTypography.tableHeader)),
            ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final dynamic record;
  final int index;
  final bool isSelected;
  final ValueChanged<bool> onSelect;
  final VoidCallback onTap;

  const _AttendanceRow({
    required this.record,
    required this.index,
    required this.isSelected,
    required this.onSelect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = record;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 40,
        color: isSelected ? _primary.withOpacity(0.05) : (index.isEven ? _surface : _bg),
        child: Row(
          children: [
            // Checkbox
            SizedBox(width: 40, child: Checkbox(value: isSelected, onChanged: (v) => onSelect(v ?? false), visualDensity: VisualDensity.compact)),
            // Employee
            SizedBox(
              width: 160,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(r.employeeName ?? 'Unknown', style: ApexTypography.tableCell.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              ),
            ),
            // Shift
            SizedBox(width: 100, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(r.shiftId ?? '—', style: ApexTypography.tableCell, overflow: TextOverflow.ellipsis))),
            // Clock In
            SizedBox(width: 80, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(r.punchIn != null ? DateFormat('hh:mm a').format(r.punchIn!) : '—', style: ApexTypography.tableCell))),
            // Clock Out
            SizedBox(width: 80, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(r.punchOut != null ? DateFormat('hh:mm a').format(r.punchOut!) : '—', style: ApexTypography.tableCell))),
            // Hours
            SizedBox(width: 70, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(r.totalHours != null ? '${r.totalHours!.toStringAsFixed(1)}h' : '—', style: ApexTypography.tableCell))),
            // OT
            SizedBox(width: 60, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(r.overtimeHours != null && r.overtimeHours! > 0 ? '${r.overtimeHours!.toStringAsFixed(1)}h' : '—', style: ApexTypography.tableCell.copyWith(color: r.overtimeHours != null && r.overtimeHours! > 0 ? _success : _muted)))),
            // Late By
            SizedBox(width: 70, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(r.isLate ? '${r.lateMinutes}m' : '—', style: ApexTypography.tableCell.copyWith(color: r.isLate ? _warning : _muted)))),
            // Early Out
            SizedBox(width: 70, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(r.isEarlyOut ? '${r.earlyOutMinutes}m' : '—', style: ApexTypography.tableCell.copyWith(color: r.isEarlyOut ? _warning : _muted)))),
            // Device
            SizedBox(width: 80, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(r.deviceId ?? 'Manual', style: ApexTypography.tableCell, overflow: TextOverflow.ellipsis))),
            // Status
            SizedBox(width: 80, child: _StatusBadge(status: r.status)),
            // Actions
            SizedBox(
              width: 60,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 16),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('View')),
                  const PopupMenuItem(value: 'correct', child: Text('Correct')),
                ],
                onSelected: (v) {
                  if (v == 'view') context.push('/attendance/detail?employeeId=${r.employeeId}');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: config.$2.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(config.$1, style: ApexTypography.captionSmall.copyWith(color: config.$2, fontWeight: FontWeight.w600)),
    );
  }

  (String, Color) _statusConfig(String s) {
    switch (s) {
      case 'present': return ('Present', _success);
      case 'absent': return ('Absent', _danger);
      case 'late': return ('Late', _warning);
      case 'half_day': return ('Half Day', _warning);
      case 'on_leave': return ('Leave', _primary);
      default: return (s, _muted);
    }
  }
}

// ── Empty State ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({required this.icon, required this.title, required this.description, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: _muted),
            const SizedBox(height: 16),
            Text(title, style: ApexTypography.headingMedium.copyWith(color: _text)),
            const SizedBox(height: 8),
            Text(description, style: ApexTypography.bodySmall.copyWith(color: _muted), textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
