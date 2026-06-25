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
import '../../models/attendance.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/employee_provider.dart';

class AttendanceListScreen extends ConsumerStatefulWidget {
  const AttendanceListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends ConsumerState<AttendanceListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _selectedDate.toIso8601String().substring(0, 10);
    final summaryAsync = ref.watch(dailySummaryProvider(dateStr));
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(icon: const Icon(Icons.add_task, size: 20), tooltip: 'Manual Mark', onPressed: () => context.push('/attendance/mark')),
          IconButton(icon: const Icon(Icons.summarize_outlined, size: 20), tooltip: 'Summary', onPressed: () => context.push('/attendance/summary')),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Calendar'),
            Tab(text: 'Timeline'),
            Tab(text: 'Exceptions'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Summary bar
          summaryAsync.when(
            data: (s) => _buildSummaryBar(s, isMobile),
            loading: () => const SizedBox(height: 60),
            error: (_, __) => const SizedBox(),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTab(),
                _buildCalendarTab(),
                _buildTimelineTab(),
                _buildExceptionsTab(),
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary Bar ──────────────────────────────────────────────
  Widget _buildSummaryBar(DailyAttendanceSummary s, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? ApexColors.darkSurface : ApexColors.neutral0,
        border: const Border(bottom: BorderSide(color: ApexColors.neutral200)),
      ),
      child: Row(
        children: [
          _summaryChip('Present', '${s.present}', ApexColors.success),
          _summaryChip('Absent', '${s.absent}', ApexColors.error),
          _summaryChip('Late', '${s.late}', ApexColors.warning),
          _summaryChip('Half Day', '${s.halfDay}', ApexColors.accent),
          _summaryChip('Leave', '${s.onLeave}', ApexColors.info),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$value $label', style: ApexTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Today Tab ────────────────────────────────────────────────
  Widget _buildTodayTab() {
    final listState = ref.watch(attendanceListProvider);
    return listState.records.when(
      data: (records) {
        if (records.isEmpty) return const ApexEmptyState(icon: Icons.calendar_today_outlined, title: 'No Records', description: 'No attendance for today.');
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: records.length,
          itemBuilder: (context, i) {
            final r = records[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  child: Text((r.employeeName ?? 'U')[0].toUpperCase(), style: ApexTypography.captionSmall),
                ),
                title: Text(r.employeeName ?? 'Unknown', style: ApexTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${r.punchIn != null ? DateFormat('hh:mm a').format(r.punchIn!) : 'No in'} - ${r.punchOut != null ? DateFormat('hh:mm a').format(r.punchOut!) : 'No out'}',
                  style: ApexTypography.captionSmall,
                ),
                trailing: ApexBadge(status: r.status, category: 'attendance'),
                onTap: () => context.push('/attendance/detail?employeeId=${r.employeeId}'),
              ),
            );
          },
        );
      },
      loading: () => const ApexLoadingSkeleton(count: 10, type: ApexSkeletonType.list),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  // ── Calendar Tab ─────────────────────────────────────────────
  Widget _buildCalendarTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildCalendarGrid(),
          const SizedBox(height: 16),
          _buildSelectedDayDetails(),
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
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1))),
              Text(DateFormat('MMMM yyyy').format(_focusedMonth), style: ApexTypography.titleMedium),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1))),
            ],
          ),
          const SizedBox(height: 8),
          // Weekday headers
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) =>
              Expanded(child: Center(child: Text(d, style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500))))
            ).toList(),
          ),
          const SizedBox(height: 4),
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1),
            itemCount: (startWeekday - 1) + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startWeekday - 1) return const SizedBox();
              final day = index - (startWeekday - 1) + 1;
              final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
              final isSelected = _selectedDate.year == date.year && _selectedDate.month == date.month && _selectedDate.day == date.day;
              final isToday = DateTime.now().year == date.year && DateTime.now().month == date.month && DateTime.now().day == date.day;
              final isWeekend = date.weekday >= 6;

              // Simulate status color
              Color? dotColor;
              if (!isWeekend && date.isBefore(DateTime.now())) {
                final hash = date.day.hashCode % 10;
                if (hash < 7) dotColor = ApexColors.success;
                else if (hash < 9) dotColor = ApexColors.warning;
                else dotColor = ApexColors.error;
              }

              return InkWell(
                onTap: () => setState(() => _selectedDate = date),
                borderRadius: ApexRadius.xsAll,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected ? ApexColors.primary : isToday ? ApexColors.primary50 : null,
                    borderRadius: ApexRadius.xsAll,
                    border: isToday && !isSelected ? Border.all(color: ApexColors.primary) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$day', style: ApexTypography.bodySmall.copyWith(
                        color: isSelected ? Colors.white : isWeekend ? ApexColors.neutral400 : null,
                        fontWeight: isToday ? FontWeight.w700 : null,
                      )),
                      if (dotColor != null)
                        Container(width: 5, height: 5, margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(color: isSelected ? Colors.white : dotColor, shape: BoxShape.circle)),
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
    final summaryAsync = ref.watch(dailySummaryProvider(dateStr));

    return ApexCard(
      header: Text(DateFormat('EEEE, MMMM dd').format(_selectedDate), style: ApexTypography.titleMedium),
      child: summaryAsync.when(
        data: (s) => Column(
          children: [
            _detailRow('Present', '${s.present}', ApexColors.success),
            _detailRow('Absent', '${s.absent}', ApexColors.error),
            _detailRow('Late', '${s.late}', ApexColors.warning),
            _detailRow('Half Day', '${s.halfDay}', ApexColors.accent),
            _detailRow('Leave', '${s.onLeave}', ApexColors.info),
          ],
        ),
        loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => Text('Error: $e'),
      ),
    );
  }

  Widget _detailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: ApexTypography.bodySmall)),
          Text(value, style: ApexTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  // ── Timeline Tab ─────────────────────────────────────────────
  Widget _buildTimelineTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Punch Timeline — ${DateFormat('MMM dd, yyyy').format(_selectedDate)}', style: ApexTypography.titleMedium),
          const SizedBox(height: 12),
          ApexCard(
            child: Column(
              children: [
                _timelineEntry('John Doe', '09:05 AM', 'IN', ApexColors.success),
                _timelineEntry('John Doe', '06:10 PM', 'OUT', ApexColors.info),
                _timelineEntry('Jane Smith', '09:25 AM', 'IN', ApexColors.warning),
                _timelineEntry('Jane Smith', '05:45 PM', 'OUT', ApexColors.info),
                _timelineEntry('Bob Johnson', '10:15 AM', 'IN', ApexColors.error),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineEntry(String name, String time, String type, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: ApexTypography.bodySmall.copyWith(fontWeight: FontWeight.w600))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: ApexRadius.xsAll),
            child: Text(type, style: ApexTypography.captionSmall.copyWith(color: color, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Text(time, style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500)),
        ],
      ),
    );
  }

  // ── Exceptions Tab ───────────────────────────────────────────
  Widget _buildExceptionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ApexCard(
            header: Row(children: [
              const Icon(Icons.warning_amber, size: 16, color: ApexColors.warning),
              const SizedBox(width: 6),
              Text('Missing Punches', style: ApexTypography.titleMedium),
            ]),
            child: Column(children: [
              _exceptionItem('John Doe', 'EMP001', 'Missing Punch Out', '09:15 AM'),
              const Divider(height: 1),
              _exceptionItem('Jane Smith', 'EMP002', 'Missing Punch In', '--'),
            ]),
          ),
          const SizedBox(height: 12),
          ApexCard(
            header: Row(children: [
              const Icon(Icons.access_time, size: 16, color: ApexColors.warning),
              const SizedBox(width: 6),
              Text('Late Arrivals', style: ApexTypography.titleMedium),
            ]),
            child: Column(children: [
              _exceptionItem('Bob Johnson', 'EMP003', '15 minutes late', '09:15 AM'),
              const Divider(height: 1),
              _exceptionItem('Alice Brown', 'EMP004', '25 minutes late', '09:25 AM'),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _exceptionItem(String name, String code, String issue, String time) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(radius: 14, child: Text(name[0].toUpperCase(), style: ApexTypography.captionSmall)),
      title: Text(name, style: ApexTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text('$code • $issue • $time', style: ApexTypography.captionSmall),
      trailing: IconButton(icon: const Icon(Icons.edit, size: 16), onPressed: () => context.push('/attendance/mark')),
    );
  }

  // ── Analytics Tab ────────────────────────────────────────────
  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ApexCard(
            header: Text('Late Arrival Analysis', style: ApexTypography.titleMedium),
            child: SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 10,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
                      final i = v.toInt();
                      if (i >= 0 && i < days.length) return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(days[i], style: ApexTypography.captionSmall),
                      );
                      return const SizedBox();
                    })),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 3, color: ApexColors.warning, width: 20, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 5, color: ApexColors.warning, width: 20, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 2, color: ApexColors.warning, width: 20, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 4, color: ApexColors.warning, width: 20, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 1, color: ApexColors.warning, width: 20, borderRadius: BorderRadius.circular(4))]),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ApexCard(
            header: Text('Overtime Analysis', style: ApexTypography.titleMedium),
            child: Column(children: [
              _overtimeStat('This Week', '12.5 hrs', ApexColors.info),
              _overtimeStat('This Month', '48.0 hrs', ApexColors.primary),
              _overtimeStat('Top Performer', 'EMP003', ApexColors.success),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _overtimeStat(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ApexTypography.bodySmall),
          Text(value, style: ApexTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
