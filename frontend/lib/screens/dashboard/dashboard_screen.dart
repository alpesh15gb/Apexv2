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
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final chartAsync = ref.watch(dashboardChartProvider(7));
    final heatmapAsync = ref.watch(attendanceHeatmapProvider(30));
    final birthdaysAsync = ref.watch(birthdaysProvider);
    final anniversariesAsync = ref.watch(anniversariesProvider);
    final deptDistAsync = ref.watch(departmentDistributionProvider);
    final monthlyTrendAsync = ref.watch(monthlyTrendProvider(6));
    final syncHealthAsync = ref.watch(syncHealthProvider);
    final activityAsync = ref.watch(recentActivityProvider);

    final padding = Responsive.contentPadding(context);
    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(dashboardChartProvider(7));
          ref.invalidate(attendanceHeatmapProvider(30));
          ref.invalidate(birthdaysProvider);
          ref.invalidate(anniversariesProvider);
          ref.invalidate(departmentDistributionProvider);
          ref.invalidate(monthlyTrendProvider(6));
          ref.invalidate(syncHealthProvider);
          ref.invalidate(recentActivityProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context),
              SizedBox(height: isMobile ? 16 : 24),

              // Executive Summary Cards
              statsAsync.when(
                data: (stats) => _buildExecutiveSummary(context, stats, isMobile),
                loading: () => const ApexLoadingSkeleton(count: 6, type: ApexSkeletonType.stat),
                error: (err, stack) => _buildErrorCard(context, err.toString()),
              ),
              SizedBox(height: isMobile ? 16 : 24),

              // Attendance Heatmap + Weekly Trend
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: heatmapAsync.when(
                        data: (data) => _buildAttendanceHeatmap(context, data),
                        loading: () => const ApexLoadingSkeleton(count: 1, type: ApexSkeletonType.card),
                        error: (err, stack) => _buildErrorCard(context, err.toString()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: chartAsync.when(
                        data: (trends) => _buildWeeklyTrend(context, trends),
                        loading: () => const ApexLoadingSkeleton(count: 1, type: ApexSkeletonType.card),
                        error: (err, stack) => _buildErrorCard(context, err.toString()),
                      ),
                    ),
                  ],
                )
              else ...[
                heatmapAsync.when(
                  data: (data) => _buildAttendanceHeatmap(context, data),
                  loading: () => const ApexLoadingSkeleton(count: 1, type: ApexSkeletonType.card),
                  error: (err, stack) => _buildErrorCard(context, err.toString()),
                ),
                const SizedBox(height: 16),
                chartAsync.when(
                  data: (trends) => _buildWeeklyTrend(context, trends),
                  loading: () => const ApexLoadingSkeleton(count: 1, type: ApexSkeletonType.card),
                  error: (err, stack) => _buildErrorCard(context, err.toString()),
                ),
              ],
              SizedBox(height: isMobile ? 16 : 24),

              // Department Distribution + Monthly Trend
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: deptDistAsync.when(
                        data: (data) => _buildDepartmentDistribution(context, data),
                        loading: () => const ApexLoadingSkeleton(count: 1, type: ApexSkeletonType.card),
                        error: (err, stack) => _buildErrorCard(context, err.toString()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: monthlyTrendAsync.when(
                        data: (data) => _buildMonthlyTrend(context, data),
                        loading: () => const ApexLoadingSkeleton(count: 1, type: ApexSkeletonType.card),
                        error: (err, stack) => _buildErrorCard(context, err.toString()),
                      ),
                    ),
                  ],
                )
              else ...[
                deptDistAsync.when(
                  data: (data) => _buildDepartmentDistribution(context, data),
                  loading: () => const ApexLoadingSkeleton(count: 1, type: ApexSkeletonType.card),
                  error: (err, stack) => _buildErrorCard(context, err.toString()),
                ),
                const SizedBox(height: 16),
                monthlyTrendAsync.when(
                  data: (data) => _buildMonthlyTrend(context, data),
                  loading: () => const ApexLoadingSkeleton(count: 1, type: ApexSkeletonType.card),
                  error: (err, stack) => _buildErrorCard(context, err.toString()),
                ),
              ],
              SizedBox(height: isMobile ? 16 : 24),

              // Birthdays + Anniversaries + Sync Health
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: birthdaysAsync.when(
                        data: (data) => _buildBirthdays(context, data),
                        loading: () => const ApexLoadingSkeleton(count: 1, type: ApexSkeletonType.card),
                        error: (err, stack) => _buildErrorCard(context, err.toString()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: anniversariesAsync.when(
                        data: (data) => _buildAnniversaries(context, data),
                        loading: () => const ApexLoadingSkeleton(count: 1, type: ApexSkeletonType.card),
                        error: (err, stack) => _buildErrorCard(context, err.toString()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: syncHealthAsync.when(
                        data: (data) => _buildSyncHealth(context, data),
                        loading: () => const ApexLoadingSkeleton(count: 1, type: ApexSkeletonType.card),
                        error: (err, stack) => _buildErrorCard(context, err.toString()),
                      ),
                    ),
                  ],
                )
              else ...[
                birthdaysAsync.when(
                  data: (data) => _buildBirthdays(context, data),
                  loading: () => const ApexLoadingSkeleton(count: 1, type: ApexSkeletonType.card),
                  error: (err, stack) => _buildErrorCard(context, err.toString()),
                ),
                const SizedBox(height: 16),
                anniversariesAsync.when(
                  data: (data) => _buildAnniversaries(context, data),
                  loading: () => const ApexLoadingSkeleton(count: 1, type: ApexSkeletonType.card),
                  error: (err, stack) => _buildErrorCard(context, err.toString()),
                ),
                const SizedBox(height: 16),
                syncHealthAsync.when(
                  data: (data) => _buildSyncHealth(context, data),
                  loading: () => const ApexLoadingSkeleton(count: 1, type: ApexSkeletonType.card),
                  error: (err, stack) => _buildErrorCard(context, err.toString()),
                ),
              ],
              SizedBox(height: isMobile ? 16 : 24),

              // Activity Feed + Quick Actions
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: activityAsync.when(
                        data: (activities) => _buildActivityFeed(context, activities),
                        loading: () => const ApexLoadingSkeleton(count: 5, type: ApexSkeletonType.list),
                        error: (err, stack) => _buildErrorCard(context, err.toString()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActions(context),
                    ),
                  ],
                )
              else ...[
                activityAsync.when(
                  data: (activities) => _buildActivityFeed(context, activities),
                  loading: () => const ApexLoadingSkeleton(count: 5, type: ApexSkeletonType.list),
                  error: (err, stack) => _buildErrorCard(context, err.toString()),
                ),
                const SizedBox(height: 16),
                _buildQuickActions(context),
              ],
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
            Text(
              'Dashboard',
              style: ApexTypography.headingLarge.copyWith(
                color: isDark ? ApexColors.darkOnSurface : ApexColors.neutral900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now()),
              style: ApexTypography.bodyMedium.copyWith(
                color: isDark ? ApexColors.darkOnSurfaceVariant : ApexColors.neutral500,
              ),
            ),
          ],
        ),
        if (!Responsive.isMobile(context))
          ElevatedButton.icon(
            onPressed: () => context.push('/attendance/mark'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Manual Attendance'),
          ),
      ],
    );
  }

  Widget _buildExecutiveSummary(BuildContext context, DashboardStats stats, bool isMobile) {
    final columns = Responsive.gridColumns(context);

    return GridView.count(
      crossAxisCount: isMobile ? 2 : (columns > 3 ? 3 : columns),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isMobile ? 1.3 : 1.5,
      children: [
        ApexStatCard(
          title: 'Present Today',
          value: '${stats.employeesPresent}',
          icon: Icons.people_outline,
          color: ApexColors.success,
          subtitle: '${stats.attendancePercentage.toStringAsFixed(1)}% attendance',
          onTap: () => context.push('/attendance'),
        ),
        ApexStatCard(
          title: 'Absent Today',
          value: '${stats.employeesAbsent}',
          icon: Icons.people_alt_outlined,
          color: ApexColors.error,
          onTap: () => context.push('/attendance'),
        ),
        ApexStatCard(
          title: 'Late Today',
          value: '${stats.lateToday}',
          icon: Icons.access_time,
          color: ApexColors.warning,
          onTap: () => context.push('/attendance'),
        ),
        ApexStatCard(
          title: 'Active Devices',
          value: '${stats.onlineDevices}/${stats.onlineDevices + stats.offlineDevices}',
          icon: Icons.biotech_outlined,
          color: ApexColors.info,
          onTap: () => context.push('/devices'),
        ),
        ApexStatCard(
          title: 'Pending Leaves',
          value: '${stats.pendingLeaves}',
          icon: Icons.event_busy_outlined,
          color: ApexColors.accent,
          onTap: () => context.push('/leaves/requests'),
        ),
        ApexStatCard(
          title: 'Missing Punches',
          value: '${stats.missingPunches}',
          icon: Icons.warning_amber_outlined,
          color: stats.missingPunches > 0 ? ApexColors.error : ApexColors.success,
          onTap: () => context.push('/attendance'),
        ),
      ],
    );
  }

  Widget _buildAttendanceHeatmap(BuildContext context, List<AttendanceHeatmapItem> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ApexCard(
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Attendance Heatmap', style: ApexTypography.titleMedium),
          Text('Last 30 days', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
        ],
      ),
      child: data.isEmpty
          ? const ApexEmptyState(
              icon: Icons.calendar_month,
              title: 'No Data',
              description: 'Attendance data will appear here.',
            )
          : SizedBox(
              height: 200,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final item = data[index];
                  final rate = item.attendanceRate;
                  Color color;
                  if (rate >= 90) {
                    color = ApexColors.success;
                  } else if (rate >= 70) {
                    color = ApexColors.warning;
                  } else if (rate > 0) {
                    color = ApexColors.error;
                  } else {
                    color = isDark ? ApexColors.darkSurfaceVariant : ApexColors.neutral100;
                  }

                  return Tooltip(
                    message: '${item.date}\n${item.present} present, ${item.absent} absent\n${rate.toStringAsFixed(1)}%',
                    child: Container(
                      decoration: BoxDecoration(
                        color: color.withOpacity(rate > 0 ? 0.8 : 1),
                        borderRadius: ApexRadius.xsAll,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildWeeklyTrend(BuildContext context, List<AttendanceTrend> trends) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ApexCard(
      header: Text('Weekly Trend', style: ApexTypography.titleMedium),
      child: trends.isEmpty
          ? const ApexEmptyState(
              icon: Icons.bar_chart,
              title: 'No Data',
              description: 'Weekly trend will appear here.',
            )
          : SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: trends
                          .map((e) => (e.present + e.absent + e.late).toDouble())
                          .reduce((a, b) => a > b ? a : b) +
                      2,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < trends.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('E').format(trends[index].date),
                                style: ApexTypography.captionSmall.copyWith(
                                  color: ApexColors.neutral500,
                                ),
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
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: trends.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final trend = entry.value;
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: trend.present.toDouble(),
                          color: ApexColors.success,
                          width: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: trend.absent.toDouble(),
                          color: ApexColors.error,
                          width: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
    );
  }

  Widget _buildDepartmentDistribution(BuildContext context, List<DepartmentDistribution> data) {
    return ApexCard(
      header: Text('Department Distribution', style: ApexTypography.titleMedium),
      child: data.isEmpty
          ? const ApexEmptyState(
              icon: Icons.pie_chart,
              title: 'No Data',
              description: 'Department distribution will appear here.',
            )
          : Column(
              children: data.take(5).map((dept) {
                final total = data.fold<int>(0, (sum, d) => sum + d.count);
                final percentage = total > 0 ? (dept.count / total * 100) : 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          dept.department,
                          style: ApexTypography.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: ClipRRect(
                          borderRadius: ApexRadius.xsAll,
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: ApexColors.neutral100,
                            color: ApexColors.primary,
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${dept.count}',
                          style: ApexTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildMonthlyTrend(BuildContext context, List<MonthlyTrend> data) {
    return ApexCard(
      header: Text('Monthly Trend', style: ApexTypography.titleMedium),
      child: data.isEmpty
          ? const ApexEmptyState(
              icon: Icons.trending_up,
              title: 'No Data',
              description: 'Monthly trend will appear here.',
            )
          : SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < data.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                data[index].month.substring(5),
                                style: ApexTypography.captionSmall.copyWith(
                                  color: ApexColors.neutral500,
                                ),
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
                      spots: data.asMap().entries.map((e) =>
                        FlSpot(e.key.toDouble(), e.value.attendanceRate)
                      ).toList(),
                      isCurved: true,
                      color: ApexColors.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: ApexColors.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBirthdays(BuildContext context, List<BirthdayItem> data) {
    return ApexCard(
      header: Row(
        children: [
          const Icon(Icons.cake, size: 20, color: ApexColors.accent),
          const SizedBox(width: 8),
          Text('Birthdays This Month', style: ApexTypography.titleMedium),
        ],
      ),
      child: data.isEmpty
          ? const ApexEmptyState(
              icon: Icons.cake_outlined,
              title: 'No Birthdays',
              description: 'No employees have birthdays this month.',
            )
          : Column(
              children: data.take(5).map((item) {
                final dob = DateTime.parse(item.dateOfBirth);
                final day = DateFormat('MMM dd').format(dob);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: ApexColors.accent50,
                    child: Text(
                      item.name[0].toUpperCase(),
                      style: ApexTypography.titleSmall.copyWith(color: ApexColors.accent),
                    ),
                  ),
                  title: Text(item.name, style: ApexTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text(day, style: ApexTypography.captionMedium),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            ),
    );
  }

  Widget _buildAnniversaries(BuildContext context, List<AnniversaryItem> data) {
    return ApexCard(
      header: Row(
        children: [
          const Icon(Icons.celebration, size: 20, color: ApexColors.secondary),
          const SizedBox(width: 8),
          Text('Work Anniversaries', style: ApexTypography.titleMedium),
        ],
      ),
      child: data.isEmpty
          ? const ApexEmptyState(
              icon: Icons.celebration_outlined,
              title: 'No Anniversaries',
              description: 'No employees have work anniversaries this month.',
            )
          : Column(
              children: data.take(5).map((item) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: ApexColors.secondary50,
                    child: Text(
                      '${item.years}',
                      style: ApexTypography.titleSmall.copyWith(color: ApexColors.secondary),
                    ),
                  ),
                  title: Text(item.name, style: ApexTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text('${item.years} year${item.years > 1 ? 's' : ''}', style: ApexTypography.captionMedium),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            ),
    );
  }

  Widget _buildSyncHealth(BuildContext context, SyncHealthStatus data) {
    return ApexCard(
      header: Row(
        children: [
          const Icon(Icons.sync, size: 20, color: ApexColors.info),
          const SizedBox(width: 8),
          Text('Sync Health', style: ApexTypography.titleMedium),
        ],
      ),
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
          if (data.recentSyncs.isNotEmpty) ...[
            const Divider(height: 24),
            ...data.recentSyncs.take(3).map((sync) {
              return ListTile(
                leading: Icon(
                  sync['status'] == 'completed' ? Icons.check_circle : Icons.sync,
                  size: 18,
                  color: sync['status'] == 'completed' ? ApexColors.success : ApexColors.info,
                ),
                title: Text(
                  '${sync['sync_type']} sync',
                  style: ApexTypography.bodySmall,
                ),
                subtitle: Text(
                  '${sync['records_fetched']} records',
                  style: ApexTypography.captionSmall,
                ),
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSyncStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: ApexTypography.headingMedium.copyWith(color: color),
        ),
        Text(
          label,
          style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500),
        ),
      ],
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
              title: 'No Recent Activity',
              description: 'Activities will appear here as they occur.',
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length > 10 ? 10 : activities.length,
              separatorBuilder: (context, idx) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final act = activities[idx];
                return _buildActivityItem(context, act);
              },
            ),
    );
  }

  Widget _buildActivityItem(BuildContext context, RecentActivity act) {
    final iconData = _getActivityIcon(act.activityType);
    final iconColor = _getActivityColor(act.activityType);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(iconData, color: iconColor, size: 20),
      ),
      title: Text(act.description, style: ApexTypography.bodyMedium),
      subtitle: Text(
        DateFormat('hh:mm a').format(DateTime.tryParse(act.timestamp) ?? DateTime.now()),
        style: ApexTypography.captionMedium,
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return ApexCard(
      header: Text('Quick Actions', style: ApexTypography.titleMedium),
      child: Column(
        children: [
          _buildQuickActionTile(
            context,
            Icons.person_add,
            'Add Employee',
            'Create a new employee record',
            () => context.push('/employees/create'),
          ),
          const Divider(height: 1),
          _buildQuickActionTile(
            context,
            Icons.calendar_today,
            'Mark Attendance',
            'Record employee attendance',
            () => context.push('/attendance/mark'),
          ),
          const Divider(height: 1),
          _buildQuickActionTile(
            context,
            Icons.event_busy,
            'Apply Leave',
            'Submit a leave request',
            () => context.push('/leaves/apply'),
          ),
          const Divider(height: 1),
          _buildQuickActionTile(
            context,
            Icons.assessment,
            'Generate Report',
            'Create attendance reports',
            () => context.push('/reports'),
          ),
          const Divider(height: 1),
          _buildQuickActionTile(
            context,
            Icons.sync,
            'eSSL Dashboard',
            'View sync status',
            () => context.push('/settings/essl/dashboard'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: ApexColors.primary50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: ApexColors.primary, size: 20),
      ),
      title: Text(title, style: ApexTypography.titleMedium),
      subtitle: Text(subtitle, style: ApexTypography.bodySmall),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildErrorCard(BuildContext context, String error) {
    return ApexCard(
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: ApexColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Error: $error',
              style: ApexTypography.bodyMedium.copyWith(color: ApexColors.error),
            ),
          ),
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
    if (type.contains('sync')) return ApexColors.primary;
    return ApexColors.neutral400;
  }
}
