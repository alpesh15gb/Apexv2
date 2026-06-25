import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/border_radius.dart';
import '../../design_system/components/apex_card.dart';
import '../../design_system/components/apex_badge.dart';
import '../../design_system/components/apex_empty_state.dart';
import '../../design_system/components/apex_loading_skeleton.dart';
import '../../design_system/components/apex_stat_card.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/employee_provider.dart';

enum _ViewMode { calendar, timeline, heatmap, table }

class AttendanceListScreen extends ConsumerStatefulWidget {
  const AttendanceListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends ConsumerState<AttendanceListScreen> {
  _ViewMode _viewMode = _ViewMode.calendar;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.contentPadding(context);
    final isMobile = Responsive.isMobile(context);
    final dateStr = _selectedDate.toIso8601String().substring(0, 10);
    final summaryAsync = ref.watch(dailySummaryProvider(dateStr));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          // View toggle
          if (!isMobile)
            SegmentedButton<_ViewMode>(
              segments: const [
                ButtonSegment(value: _ViewMode.calendar, icon: Icon(Icons.calendar_month, size: 18), label: Text('Calendar')),
                ButtonSegment(value: _ViewMode.timeline, icon: Icon(Icons.timeline, size: 18), label: Text('Timeline')),
                ButtonSegment(value: _ViewMode.heatmap, icon: Icon(Icons.grid_on, size: 18), label: Text('Heatmap')),
                ButtonSegment(value: _ViewMode.table, icon: Icon(Icons.view_list, size: 18), label: Text('Table')),
              ],
              selected: {_viewMode},
              onSelectionChanged: (value) => setState(() => _viewMode = value.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: ApexRadius.mdAll)),
              ),
            ),
          if (!isMobile) const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_task),
            tooltip: 'Manual Mark',
            onPressed: () => context.push('/attendance/mark'),
          ),
          IconButton(
            icon: const Icon(Icons.summarize_outlined),
            tooltip: 'Daily Summary',
            onPressed: () => context.push('/attendance/summary'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selector + Quick dates
          _buildDateSelector(isMobile),

          // Daily Summary Cards
          summaryAsync.when(
            data: (summary) => _buildDailySummary(summary, isMobile),
            loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
            error: (err, stack) => const SizedBox(),
          ),

          const Divider(height: 1),

          // Main content
          Expanded(
            child: _viewMode == _ViewMode.calendar
                ? _buildCalendarView()
                : _viewMode == _ViewMode.timeline
                    ? _buildTimelineView()
                    : _viewMode == _ViewMode.heatmap
                        ? _buildHeatmapView()
                        : _buildTableView(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? ApexColors.darkSurface
            : ApexColors.neutral0,
        border: const Border(bottom: BorderSide(color: ApexColors.neutral200)),
      ),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                  });
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(_focusedMonth),
                style: ApexTypography.headingSmall,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Quick date buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickDateChip('Today', DateTime.now()),
                const SizedBox(width: 8),
                _buildQuickDateChip('Yesterday', DateTime.now().subtract(const Duration(days: 1))),
                const SizedBox(width: 8),
                _buildQuickDateChip('This Week', DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1))),
                const SizedBox(width: 8),
                _buildQuickDateChip('This Month', DateTime(DateTime.now().year, DateTime.now().month, 1)),
                const SizedBox(width: 8),
                _buildQuickDateChip('Last Month', DateTime(DateTime.now().year, DateTime.now().month - 1, 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDateChip(String label, DateTime date) {
    final isSelected = _selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedDate = date);
      },
      selectedColor: ApexColors.primary100,
      checkmarkColor: ApexColors.primary,
    );
  }

  Widget _buildDailySummary(DailyAttendanceSummary summary, bool isMobile) {
    final total = summary.present + summary.absent + summary.late + summary.halfDay + summary.onLeave;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 12),
      child: Row(
        children: [
          Expanded(child: _buildSummaryCard('Present', '${summary.present}', ApexColors.success, total > 0 ? summary.present / total : 0)),
          const SizedBox(width: 8),
          Expanded(child: _buildSummaryCard('Absent', '${summary.absent}', ApexColors.error, total > 0 ? summary.absent / total : 0)),
          const SizedBox(width: 8),
          Expanded(child: _buildSummaryCard('Late', '${summary.late}', ApexColors.warning, total > 0 ? summary.late / total : 0)),
          const SizedBox(width: 8),
          Expanded(child: _buildSummaryCard('Half Day', '${summary.halfDay}', ApexColors.accent, total > 0 ? summary.halfDay / total : 0)),
          const SizedBox(width: 8),
          Expanded(child: _buildSummaryCard('Leave', '${summary.onLeave}', ApexColors.info, total > 0 ? summary.onLeave / total : 0)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, double percentage) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: ApexRadius.mdAll,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: ApexTypography.headingMedium.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: ApexRadius.xsAll,
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withOpacity(0.1),
              color: color,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Calendar View ──────────────────────────────────────────────

  Widget _buildCalendarView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar grid
          _buildCalendarGrid(),
          const SizedBox(height: 24),

          // Selected day details
          _buildSelectedDayDetails(),
          const SizedBox(height: 24),

          // Missing Punches Alert
          _buildMissingPunchesAlert(),
          const SizedBox(height: 24),

          // Attendance Exceptions
          _buildAttendanceExceptions(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startWeekday = firstDay.weekday;
    final daysInMonth = lastDay.day;

    return ApexCard(
      child: Column(
        children: [
          // Weekday headers
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(day, style: ApexTypography.captionLarge.copyWith(color: ApexColors.neutral500)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Calendar days
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: (startWeekday - 1) + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startWeekday - 1) {
                return const SizedBox();
              }

              final day = index - (startWeekday - 1) + 1;
              final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
              final isSelected = _selectedDate.year == date.year &&
                  _selectedDate.month == date.month &&
                  _selectedDate.day == date.day;
              final isToday = DateTime.now().year == date.year &&
                  DateTime.now().month == date.month &&
                  DateTime.now().day == date.day;
              final isWeekend = date.weekday >= 6;

              // Simulate attendance status (in real app, this would come from data)
              Color? statusColor;
              if (!isWeekend && date.isBefore(DateTime.now())) {
                // Random status for demo
                final hash = date.day.hashCode % 10;
                if (hash < 7) statusColor = ApexColors.success;
                else if (hash < 9) statusColor = ApexColors.warning;
                else statusColor = ApexColors.error;
              }

              return InkWell(
                onTap: () => setState(() => _selectedDate = date),
                borderRadius: ApexRadius.smAll,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ApexColors.primary
                        : isToday
                            ? ApexColors.primary50
                            : null,
                    borderRadius: ApexRadius.smAll,
                    border: isToday && !isSelected
                        ? Border.all(color: ApexColors.primary)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: ApexTypography.bodyMedium.copyWith(
                          color: isSelected
                              ? Colors.white
                              : isWeekend
                                  ? ApexColors.neutral400
                                  : null,
                          fontWeight: isToday ? FontWeight.w700 : null,
                        ),
                      ),
                      if (statusColor != null)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayDetails() {
    final dateStr = _selectedDate.toIso8601String().substring(0, 10);
    final listState = ref.watch(attendanceListProvider);

    return ApexCard(
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('EEEE, MMMM dd, yyyy').format(_selectedDate),
            style: ApexTypography.titleMedium,
          ),
          TextButton(
            onPressed: () => context.push('/attendance/summary'),
            child: const Text('View All'),
          ),
        ],
      ),
      child: listState.records.when(
        data: (records) {
          final dayRecords = records.where((r) =>
            r.date.year == _selectedDate.year &&
            r.date.month == _selectedDate.month &&
            r.date.day == _selectedDate.day
          ).toList();

          if (dayRecords.isEmpty) {
            return const ApexEmptyState(
              icon: Icons.calendar_today_outlined,
              title: 'No Records',
              description: 'No attendance records for this date.',
            );
          }

          return Column(
            children: dayRecords.take(10).map((record) {
              return ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  child: Text(
                    (record.employeeName ?? 'U')[0].toUpperCase(),
                    style: ApexTypography.captionLarge,
                  ),
                ),
                title: Text(record.employeeName ?? 'Unknown', style: ApexTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${record.punchIn != null ? DateFormat('hh:mm a').format(record.punchIn!) : 'No punch in'} • '
                  '${record.punchOut != null ? DateFormat('hh:mm a').format(record.punchOut!) : 'No punch out'}',
                  style: ApexTypography.captionMedium,
                ),
                trailing: ApexBadge(status: record.status, category: 'attendance'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          );
        },
        loading: () => const ApexLoadingSkeleton(count: 5, type: ApexSkeletonType.list),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildMissingPunchesAlert() {
    // This would come from a dedicated API in production
    return ApexCard(
      header: Row(
        children: [
          const Icon(Icons.warning_amber, color: ApexColors.warning, size: 20),
          const SizedBox(width: 8),
          Text('Missing Punches', style: ApexTypography.titleMedium),
        ],
      ),
      child: Column(
        children: [
          _buildMissingPunchItem('John Doe', 'EMP001', 'Missing Punch Out', '09:15 AM'),
          const Divider(height: 1),
          _buildMissingPunchItem('Jane Smith', 'EMP002', 'Missing Punch In', '--'),
        ],
      ),
    );
  }

  Widget _buildMissingPunchItem(String name, String code, String issue, String punchTime) {
    return ListTile(
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: ApexColors.warning.withOpacity(0.1),
        child: Text(name[0], style: ApexTypography.captionLarge.copyWith(color: ApexColors.warning)),
      ),
      title: Text(name, style: ApexTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text('$code • $issue • $punchTime', style: ApexTypography.captionMedium),
      trailing: IconButton(
        icon: const Icon(Icons.edit, size: 18),
        onPressed: () => context.push('/attendance/mark'),
      ),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildAttendanceExceptions() {
    return ApexCard(
      header: Row(
        children: [
          const Icon(Icons.error_outline, color: ApexColors.error, size: 20),
          const SizedBox(width: 8),
          Text('Attendance Exceptions', style: ApexTypography.titleMedium),
        ],
      ),
      child: Column(
        children: [
          _buildExceptionItem('Late Arrival', '5 employees', ApexColors.warning),
          const Divider(height: 1),
          _buildExceptionItem('Early Departure', '2 employees', ApexColors.accent),
          const Divider(height: 1),
          _buildExceptionItem('Overtime', '3 employees', ApexColors.info),
          const Divider(height: 1),
          _buildExceptionItem('Absent Without Notice', '1 employee', ApexColors.error),
        ],
      ),
    );
  }

  Widget _buildExceptionItem(String type, String count, Color color) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: ApexRadius.mdAll,
        ),
        child: Icon(Icons.warning, color: color, size: 20),
      ),
      title: Text(type, style: ApexTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      trailing: Text(count, style: ApexTypography.bodyMedium.copyWith(color: color)),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  // ── Timeline View ──────────────────────────────────────────────

  Widget _buildTimelineView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Punch Timeline', style: ApexTypography.headingSmall),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, MMMM dd, yyyy').format(_selectedDate),
            style: ApexTypography.bodyMedium.copyWith(color: ApexColors.neutral500),
          ),
          const SizedBox(height: 16),

          // Timeline
          _buildPunchTimeline(),
          const SizedBox(height: 24),

          // Late Arrival Analysis
          _buildLateArrivalAnalysis(),
          const SizedBox(height: 24),

          // Overtime Analysis
          _buildOvertimeAnalysis(),
        ],
      ),
    );
  }

  Widget _buildPunchTimeline() {
    // Demo data - in production, this would come from punch logs API
    final punches = [
      _PunchEntry('John Doe', 'EMP001', '08:55 AM', 'in', ApexColors.success),
      _PunchEntry('Jane Smith', 'EMP002', '09:15 AM', 'in', ApexColors.warning),
      _PunchEntry('Bob Johnson', 'EMP003', '09:30 AM', 'in', ApexColors.error),
      _PunchEntry('John Doe', 'EMP001', '06:05 PM', 'out', ApexColors.success),
      _PunchEntry('Jane Smith', 'EMP002', '05:30 PM', 'out', ApexColors.success),
    ];

    return ApexCard(
      child: Column(
        children: punches.asMap().entries.map((entry) {
          final index = entry.key;
          final punch = entry.value;
          final isFirst = index == 0;
          final isLast = index == punches.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline indicator
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: punch.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        color: ApexColors.neutral200,
                      ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(punch.name, style: ApexTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                            Text('${punch.code} • ${punch.type.toUpperCase()}', style: ApexTypography.captionMedium),
                          ],
                        ),
                      ),
                      Text(punch.time, style: ApexTypography.bodyMedium.copyWith(color: punch.color)),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLateArrivalAnalysis() {
    return ApexCard(
      header: Text('Late Arrival Analysis', style: ApexTypography.titleMedium),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
                        final index = value.toInt();
                        if (index >= 0 && index < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(days[index], style: ApexTypography.captionSmall),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 3, color: ApexColors.warning, width: 24, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 5, color: ApexColors.warning, width: 24, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 2, color: ApexColors.warning, width: 24, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 4, color: ApexColors.warning, width: 24, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 1, color: ApexColors.warning, width: 24, borderRadius: BorderRadius.circular(4))]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '5 late arrivals this week',
            style: ApexTypography.bodyMedium.copyWith(color: ApexColors.warning),
          ),
        ],
      ),
    );
  }

  Widget _buildOvertimeAnalysis() {
    return ApexCard(
      header: Text('Overtime Analysis', style: ApexTypography.titleMedium),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOvertimeStat('This Week', '12.5 hrs', ApexColors.info),
              _buildOvertimeStat('This Month', '48.0 hrs', ApexColors.primary),
              _buildOvertimeStat('Top Performer', 'EMP003', ApexColors.success),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildOvertimeItem('John Doe', 'EMP001', '2.5 hrs', 'Today'),
          const Divider(height: 1),
          _buildOvertimeItem('Jane Smith', 'EMP002', '1.5 hrs', 'Yesterday'),
        ],
      ),
    );
  }

  Widget _buildOvertimeStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: ApexTypography.headingMedium.copyWith(color: color)),
        Text(label, style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
      ],
    );
  }

  Widget _buildOvertimeItem(String name, String code, String hours, String when) {
    return ListTile(
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: ApexColors.info.withOpacity(0.1),
        child: Text(name[0], style: ApexTypography.captionLarge.copyWith(color: ApexColors.info)),
      ),
      title: Text(name, style: ApexTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text('$code • $when', style: ApexTypography.captionMedium),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: ApexColors.info.withOpacity(0.1),
          borderRadius: ApexRadius.smAll,
        ),
        child: Text(hours, style: ApexTypography.captionLarge.copyWith(color: ApexColors.info, fontWeight: FontWeight.w600)),
      ),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  // ── Heatmap View ───────────────────────────────────────────────

  Widget _buildHeatmapView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attendance Heatmap', style: ApexTypography.headingSmall),
          const SizedBox(height: 8),
          Text(
            'Last 90 days attendance pattern',
            style: ApexTypography.bodyMedium.copyWith(color: ApexColors.neutral500),
          ),
          const SizedBox(height: 16),

          // Heatmap
          _buildAttendanceHeatmap(),
          const SizedBox(height: 24),

          // Department Comparison
          _buildDepartmentComparison(),
          const SizedBox(height: 24),

          // Employee Distribution
          _buildEmployeeDistribution(),
        ],
      ),
    );
  }

  Widget _buildAttendanceHeatmap() {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Attendance Rate', style: ApexTypography.titleMedium),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: 90,
            itemBuilder: (context, index) {
              final date = DateTime.now().subtract(Duration(days: 89 - index));
              final rate = (date.day.hashCode % 30 + 70) / 100; // Demo data

              Color color;
              if (rate >= 0.9) color = ApexColors.success;
              else if (rate >= 0.8) color = ApexColors.success.withOpacity(0.7);
              else if (rate >= 0.7) color = ApexColors.warning;
              else color = ApexColors.error;

              return Tooltip(
                message: '${DateFormat('MMM dd').format(date)}\n${(rate * 100).toStringAsFixed(0)}% attendance',
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: ApexRadius.xsAll,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeatmapLegend('Low', ApexColors.error),
              const SizedBox(width: 16),
              _buildHeatmapLegend('Medium', ApexColors.warning),
              const SizedBox(width: 16),
              _buildHeatmapLegend('High', ApexColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: ApexRadius.xsAll,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: ApexTypography.captionSmall),
      ],
    );
  }

  Widget _buildDepartmentComparison() {
    return ApexCard(
      header: Text('Department Comparison', style: ApexTypography.titleMedium),
      child: Column(
        children: [
          _buildDepartmentRow('Engineering', 92, ApexColors.success),
          const SizedBox(height: 8),
          _buildDepartmentRow('Marketing', 88, ApexColors.success),
          const SizedBox(height: 8),
          _buildDepartmentRow('Sales', 85, ApexColors.warning),
          const SizedBox(height: 8),
          _buildDepartmentRow('HR', 95, ApexColors.success),
          const SizedBox(height: 8),
          _buildDepartmentRow('Finance', 78, ApexColors.error),
        ],
      ),
    );
  }

  Widget _buildDepartmentRow(String name, int percentage, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(name, style: ApexTypography.bodySmall),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: ApexRadius.xsAll,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: ApexColors.neutral100,
              color: color,
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '$percentage%',
            style: ApexTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeDistribution() {
    return ApexCard(
      header: Text('Attendance Distribution', style: ApexTypography.titleMedium),
      child: SizedBox(
        height: 200,
        child: PieChart(
          PieChartData(
            sections: [
              PieChartSectionData(value: 70, color: ApexColors.success, title: '70%', radius: 60),
              PieChartSectionData(value: 15, color: ApexColors.warning, title: '15%', radius: 60),
              PieChartSectionData(value: 10, color: ApexColors.error, title: '10%', radius: 60),
              PieChartSectionData(value: 5, color: ApexColors.info, title: '5%', radius: 60),
            ],
            sectionsSpace: 2,
            centerSpaceRadius: 40,
          ),
        ),
      ),
    );
  }

  // ── Table View (Secondary) ─────────────────────────────────────

  Widget _buildTableView() {
    final listState = ref.watch(attendanceListProvider);

    return listState.records.when(
      data: (records) {
        if (records.isEmpty) {
          return const ApexEmptyState(
            icon: Icons.calendar_today_outlined,
            title: 'No Attendance Records',
            description: 'No attendance data found for the selected filters.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  child: Text(
                    (record.employeeName ?? 'U')[0].toUpperCase(),
                    style: ApexTypography.captionLarge,
                  ),
                ),
                title: Text(record.employeeName ?? 'Unknown', style: ApexTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${DateFormat('MMM dd').format(record.date)} • '
                  '${record.punchIn != null ? DateFormat('hh:mm a').format(record.punchIn!) : 'No in'} - '
                  '${record.punchOut != null ? DateFormat('hh:mm a').format(record.punchOut!) : 'No out'}',
                  style: ApexTypography.captionMedium,
                ),
                trailing: ApexBadge(status: record.status, category: 'attendance'),
                onTap: () => context.push('/attendance/detail?employeeId=${record.employeeId}'),
              ),
            );
          },
        );
      },
      loading: () => const ApexLoadingSkeleton(count: 10, type: ApexSkeletonType.list),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: ApexColors.error),
            const SizedBox(height: 16),
            Text('Error: ${err.toString()}', style: ApexTypography.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(attendanceListProvider.notifier).fetchRecords(isRefresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PunchEntry {
  final String name;
  final String code;
  final String time;
  final String type;
  final Color color;

  _PunchEntry(this.name, this.code, this.time, this.type, this.color);
}
