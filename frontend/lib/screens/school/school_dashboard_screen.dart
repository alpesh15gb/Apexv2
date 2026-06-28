import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/stat_card.dart';

final schoolStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/school/dashboard/stats');
    return Map<String, dynamic>.from(res.data);
  } catch (e) {
    return {};
  }
});

final attendanceOverviewProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/school/dashboard/attendance-overview', queryParameters: {'days': 7});
    return res.data is List ? res.data : [];
  } catch (e) {
    return [];
  }
});

class SchoolDashboardScreen extends ConsumerWidget {
  const SchoolDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(schoolStatsProvider);
    final attendanceAsync = ref.watch(attendanceOverviewProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('School Dashboard', style: ApexTypography.pageTitle.copyWith(color: ApexColors.neutral900)),
            const SizedBox(height: 8),
            Text('Overview of your school operations', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
            const SizedBox(height: 24),
            statsAsync.when(
              data: (stats) => _StatsGrid(stats: stats),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e', style: ApexTypography.body.copyWith(color: ApexColors.error)),
            ),
            const SizedBox(height: 24),
            _QuickActions(),
            const SizedBox(height: 24),
            attendanceAsync.when(
              data: (data) => _AttendanceOverview(data: data),
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : (MediaQuery.of(context).size.width > 800 ? 3 : 2),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.6,
      children: [
        StatCard(title: 'Total Students', value: '${stats['total_students'] ?? 0}', icon: Icons.school, color: ApexColors.primary600),
        StatCard(title: 'Present Today', value: '${stats['present_today'] ?? 0}', icon: Icons.check_circle, color: ApexColors.success),
        StatCard(title: 'Absent Today', value: '${stats['absent_today'] ?? 0}', icon: Icons.cancel, color: ApexColors.error),
        StatCard(title: 'Attendance %', value: '${stats['attendance_percentage'] ?? 0}%', icon: Icons.pie_chart, color: ApexColors.warning),
        StatCard(title: 'Total Grades', value: '${stats['total_grades'] ?? 0}', icon: Icons.class_, color: ApexColors.primary600),
        StatCard(title: 'Total Sections', value: '${stats['total_sections'] ?? 0}', icon: Icons.group, color: ApexColors.success),
        StatCard(title: 'Fee Collected', value: '₹${stats['total_fee_collected'] ?? 0}', icon: Icons.payment, color: ApexColors.primary600),
        StatCard(title: 'Pending Fees', value: '${stats['pending_fee_count'] ?? 0}', icon: Icons.warning, color: ApexColors.error),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: ApexTypography.sectionTitle.copyWith(color: ApexColors.neutral900)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _actionChip(context, Icons.person_add, 'Add Student', '/school/students/create'),
            _actionChip(context, Icons.check_circle, 'Mark Attendance', '/school/attendance/mark'),
            _actionChip(context, Icons.assignment, 'Create Homework', '/school/homework/create'),
            _actionChip(context, Icons.payment, 'Fee Collection', '/school/fees/collection'),
            _actionChip(context, Icons.event, 'Exam Management', '/school/exams'),
            _actionChip(context, Icons.calendar_today, 'Timetable', '/school/timetable'),
          ],
        ),
      ],
    );
  }

  Widget _actionChip(BuildContext context, IconData icon, String label, String route) {
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: ApexColors.neutral0,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ApexColors.neutral200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: ApexColors.primary600),
            const SizedBox(width: 8),
            Text(label, style: ApexTypography.body.copyWith(color: ApexColors.neutral900, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _AttendanceOverview extends StatelessWidget {
  final List<dynamic> data;
  const _AttendanceOverview({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ApexColors.neutral0,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ApexColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attendance Trend (Last 7 Days)', style: ApexTypography.sectionTitle.copyWith(color: ApexColors.neutral900)),
          const SizedBox(height: 16),
          ...data.map((day) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(width: 100, child: Text(day['date'] ?? '', style: ApexTypography.caption.copyWith(color: ApexColors.neutral500))),
                Expanded(
                  child: LinearProgressIndicator(
                    value: (day['present'] ?? 0) > 0 ? (day['present'] as int) / ((day['present'] ?? 0) + (day['absent'] ?? 0)) : 0,
                    backgroundColor: ApexColors.neutral200,
                    color: ApexColors.success,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 12),
                Text('${day['present'] ?? 0}P / ${day['absent'] ?? 0}A', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
