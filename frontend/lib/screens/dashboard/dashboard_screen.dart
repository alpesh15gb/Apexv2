import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/border_radius.dart';
import '../../design_system/components/apex_stat_card.dart';
import '../../design_system/components/apex_card.dart';
import '../../design_system/components/apex_badge.dart';
import '../../design_system/components/apex_empty_state.dart';
import '../../design_system/components/apex_loading_skeleton.dart';
import '../../models/dashboard.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final chartAsync = ref.watch(dashboardChartProvider(7));
    final deptDistAsync = ref.watch(departmentDistributionProvider);
    final activityAsync = ref.watch(recentActivityProvider);
    final syncHealthAsync = ref.watch(syncHealthProvider);
    final birthdaysAsync = ref.watch(birthdaysProvider);
    final anniversariesAsync = ref.watch(anniversariesProvider);

    final padding = Responsive.isMobile(context) ? 16.0 : 24.0;
    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(dashboardChartProvider(7));
          ref.invalidate(departmentDistributionProvider);
          ref.invalidate(recentActivityProvider);
          ref.invalidate(syncHealthProvider);
          ref.invalidate(birthdaysProvider);
          ref.invalidate(anniversariesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context),
              const SizedBox(height: 20),

              // KPI Row — compact
              statsAsync.when(
                data: (stats) => _buildKpiRow(context, stats, isMobile),
                loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
                error: (e, _) => _buildError(e.toString()),
              ),
              const SizedBox(height: 16),

              // Charts row
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: chartAsync.when(
                        data: (trends) => _buildTrendChart(context, trends),
                        loading: () => const ApexLoadingSkeleton(count: 1, type: ApexSkeletonType.card),
                        error: (e, _) => _buildError(e.toString()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: deptDistAsync.when(
                        data: (data) => _buildDeptDistribution(context, data),
                        loading: () => const ApexLoadingSkeleton(count: 1, type: ApexSkeletonType.card),
                        error: (e, _) => _buildError(e.toString()),
                      ),
                    ),
                  ],
                )
              else ...[
                chartAsync.when(
                  data: (trends) => _buildTrendChart(context, trends),
                  loading: () => const ApexLoadingSkeleton(count: 1, type: ApexSkeletonType.card),
                  error: (e, _) => _buildError(e.toString()),
                ),
                const SizedBox(height: 12),
                deptDistAsync.when(
                  data: (data) => _buildDeptDistribution(context, data),
                  loading: () => const ApexLoadingSkeleton(count: 1, type: ApexSkeletonType.card),
                  error: (e, _) => _buildError(e.toString()),
                ),
              ],
              const SizedBox(height: 16),

              // Activity + Sync Health row
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: activityAsync.when(
                        data: (activities) => _buildActivityFeed(context, activities),
                        loading: () => const ApexLoadingSkeleton(count: 5, type: ApexSkeletonType.list),
                        error: (e, _) => _buildError(e.toString()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          syncHealthAsync.when(
                            data: (data) => _buildSyncHealth(context, data),
                            loading: () => const ApexLoadingSkeleton(count: 1, type: ApexSkeletonType.card),
                            error: (e, _) => _buildError(e.toString()),
                          ),
                          const SizedBox(height: 12),
                          _buildQuickActions(context),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                activityAsync.when(
                  data: (activities) => _buildActivityFeed(context, activities),
                  loading: () => const ApexLoadingSkeleton(count: 5, type: ApexSkeletonType.list),
                  error: (e, _) => _buildError(e.toString()),
                ),
                const SizedBox(height: 12),
                _buildQuickActions(context),
              ],
              const SizedBox(height: 16),

              // Birthdays + Anniversaries
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: birthdaysAsync.when(
                        data: (data) => _buildBirthdays(context, data),
                        loading: () => const ApexLoadingSkeleton(count: 1, type: ApexSkeletonType.card),
                        error: (e, _) => _buildError(e.toString()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: anniversariesAsync.when(
                        data: (data) => _buildAnniversaries(context, data),
                        loading: () => const ApexLoadingSkeleton(count: 1, type: ApexSkeletonType.card),
                        error: (e, _) => _buildError(e.toString()),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard', style: ApexTypography.pageTitle.copyWith(
              color: isDark ? ApexColors.darkOnSurface : ApexColors.neutral900,
            )),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now()),
              style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500),
            ),
          ],
        ),
        if (!Responsive.isMobile(context))
          ElevatedButton.icon(
            onPressed: () => context.push('/attendance/mark'),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Manual Attendance'),
          ),
      ],
    );
  }

  Widget _buildKpiRow(BuildContext context, DashboardStats stats, bool isMobile) {
    final attendance = stats.attendancePercentage;
    final totalDevices = stats.onlineDevices + stats.offlineDevices;

    return GridView.count(
      crossAxisCount: isMobile ? 2 : 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: isMobile ? 1.8 : 2.2,
      children: [
        ApexStatCard(
          title: 'Attendance',
          value: '${attendance.toStringAsFixed(0)}%',
          icon: Icons.people_outline,
          color: attendance >= 90 ? ApexColors.success : attendance >= 75 ? ApexColors.warning : ApexColors.error,
          onTap: () => context.push('/attendance'),
        ),
        ApexStatCard(
          title: 'Present',
          value: '${stats.employeesPresent}',
          icon: Icons.check_circle_outline,
          color: ApexColors.success,
          onTap: () => context.push('/attendance'),
        ),
        ApexStatCard(
          title: 'Late',
          value: '${stats.lateToday}',
          icon: Icons.access_time,
          color: ApexColors.warning,
          onTap: () => context.push('/attendance'),
        ),
        ApexStatCard(
          title: 'Absent',
          value: '${stats.employeesAbsent}',
          icon: Icons.cancel_outlined,
          color: ApexColors.error,
          onTap: () => context.push('/attendance'),
        ),
        ApexStatCard(
          title: 'Devices',
          value: '${stats.onlineDevices}/$totalDevices',
          icon: Icons.biotech_outlined,
          color: stats.offlineDevices > 0 ? ApexColors.warning : ApexColors.success,
          onTap: () => context.push('/devices'),
        ),
        ApexStatCard(
          title: 'Pending',
          value: '${stats.pendingLeaves}',
          icon: Icons.event_busy_outlined,
          color: stats.pendingLeaves > 0 ? ApexColors.accent : ApexColors.neutral400,
          onTap: () => context.push('/leaves/requests'),
        ),
      ],
    );
  }

  Widget _buildTrendChart(BuildContext context, List<AttendanceTrend> trends) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ApexCard(
      header: Text('Attendance Trend', style: ApexTypography.titleMedium),
      child: trends.isEmpty
          ? const SizedBox(height: 180, child: Center(child: Text('No data')))
          : SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark ? ApexColors.neutral800 : ApexColors.neutral100,
                      strokeWidth: 0.5,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < trends.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                DateFormat('E').format(trends[idx].date),
                                style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500),
                              ),
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
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: trends.asMap().entries.map((e) =>
                        FlSpot(e.key.toDouble(), e.value.present.toDouble())
                      ).toList(),
                      isCurved: true,
                      color: ApexColors.primary,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: ApexColors.primary.withOpacity(0.08),
                      ),
                    ),
                    LineChartBarData(
                      spots: trends.asMap().entries.map((e) =>
                        FlSpot(e.key.toDouble(), e.value.absent.toDouble())
                      ).toList(),
                      isCurved: true,
                      color: ApexColors.error,
                      barWidth: 1.5,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDeptDistribution(BuildContext context, List<DepartmentDistribution> data) {
    return ApexCard(
      header: Text('Departments', style: ApexTypography.titleMedium),
      child: data.isEmpty
          ? const SizedBox(height: 180, child: Center(child: Text('No data')))
          : Column(
              children: data.take(6).map((dept) {
                final total = data.fold<int>(0, (sum, d) => sum + d.count);
                final pct = total > 0 ? dept.count / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(dept.department, style: ApexTypography.bodySmall, overflow: TextOverflow.ellipsis),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: ApexRadius.xsAll,
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: ApexColors.neutral100,
                            color: ApexColors.primary,
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 32,
                        child: Text('${dept.count}', style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildActivityFeed(BuildContext context, List<RecentActivity> activities) {
    return ApexCard(
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Recent Activity', style: ApexTypography.titleMedium),
          TextButton(
            onPressed: () => context.push('/notifications'),
            child: const Text('View All'),
          ),
        ],
      ),
      child: activities.isEmpty
          ? const ApexEmptyState(
              icon: Icons.notifications_outlined,
              title: 'No Activity',
              description: 'Activities will appear here.',
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length > 8 ? 8 : activities.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final act = activities[idx];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: _getActivityColor(act.activityType).withOpacity(0.1),
                    child: Icon(_getActivityIcon(act.activityType), size: 14, color: _getActivityColor(act.activityType)),
                  ),
                  title: Text(act.description, style: ApexTypography.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    DateFormat('hh:mm a').format(DateTime.tryParse(act.timestamp) ?? DateTime.now()),
                    style: ApexTypography.captionSmall,
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSyncHealth(BuildContext context, SyncHealthStatus data) {
    return ApexCard(
      header: Text('Sync Health', style: ApexTypography.titleMedium),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSyncStat('Servers', '${data.totalServers}', ApexColors.neutral600),
              _buildSyncStat('Connected', '${data.connected}', ApexColors.success),
              _buildSyncStat('Error', '${data.error}', data.error > 0 ? ApexColors.error : ApexColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: ApexTypography.headingMedium.copyWith(color: color)),
        Text(label, style: ApexTypography.kpiLabel),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return ApexCard(
      header: Text('Quick Actions', style: ApexTypography.titleMedium),
      child: Column(
        children: [
          _buildQuickAction(context, Icons.person_add, 'Add Employee', () => context.push('/employees/create')),
          const Divider(height: 1),
          _buildQuickAction(context, Icons.calendar_today, 'Mark Attendance', () => context.push('/attendance/mark')),
          const Divider(height: 1),
          _buildQuickAction(context, Icons.event_busy, 'Apply Leave', () => context.push('/leaves/apply')),
          const Divider(height: 1),
          _buildQuickAction(context, Icons.assessment, 'Reports', () => context.push('/reports')),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 18, color: ApexColors.primary),
      title: Text(label, style: ApexTypography.bodySmall),
      trailing: const Icon(Icons.chevron_right, size: 16, color: ApexColors.neutral400),
      onTap: onTap,
    );
  }

  Widget _buildBirthdays(BuildContext context, List<BirthdayItem> data) {
    return ApexCard(
      header: Row(
        children: [
          const Icon(Icons.cake, size: 16, color: ApexColors.accent),
          const SizedBox(width: 6),
          Text('Birthdays', style: ApexTypography.titleMedium),
        ],
      ),
      child: data.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No birthdays this month', style: TextStyle(color: ApexColors.neutral500)),
            )
          : Column(
              children: data.take(5).map((item) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: ApexColors.accent50,
                    child: Text(item.name[0].toUpperCase(), style: ApexTypography.captionSmall.copyWith(color: ApexColors.accent)),
                  ),
                  title: Text(item.name, style: ApexTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text(DateFormat('MMM dd').format(DateTime.parse(item.dateOfBirth)), style: ApexTypography.captionSmall),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildAnniversaries(BuildContext context, List<AnniversaryItem> data) {
    return ApexCard(
      header: Row(
        children: [
          const Icon(Icons.celebration, size: 16, color: ApexColors.secondary),
          const SizedBox(width: 6),
          Text('Anniversaries', style: ApexTypography.titleMedium),
        ],
      ),
      child: data.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No anniversaries this month', style: TextStyle(color: ApexColors.neutral500)),
            )
          : Column(
              children: data.take(5).map((item) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: ApexColors.secondary50,
                    child: Text('${item.years}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.secondary)),
                  ),
                  title: Text(item.name, style: ApexTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text('${item.years}yr', style: ApexTypography.captionSmall),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildError(String msg) {
    return ApexCard(
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: ApexColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: ApexTypography.bodySmall.copyWith(color: ApexColors.error))),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    if (type.contains('punch')) return Icons.fingerprint;
    if (type.contains('device')) return Icons.biotech;
    if (type.contains('visitor')) return Icons.card_membership;
    if (type.contains('leave')) return Icons.event_busy;
    if (type.contains('sync')) return Icons.sync;
    return Icons.notifications_none;
  }

  Color _getActivityColor(String type) {
    if (type.contains('punch')) return ApexColors.success;
    if (type.contains('device')) return ApexColors.info;
    if (type.contains('visitor')) return ApexColors.secondary;
    if (type.contains('leave')) return ApexColors.accent;
    return ApexColors.neutral400;
  }
}
