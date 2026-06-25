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

    final padding = Responsive.isMobile(context) ? 12.0 : 20.0;
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(dashboardChartProvider(7));
          ref.invalidate(departmentDistributionProvider);
          ref.invalidate(recentActivityProvider);
          ref.invalidate(syncHealthProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPI Block
              statsAsync.when(
                data: (stats) => _buildKpis(context, stats, isMobile),
                loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
                error: (e, _) => _err(e.toString()),
              ),
              const SizedBox(height: 12),

              // Trend Block
              chartAsync.when(
                data: (trends) => _buildTrend(context, trends),
                loading: () => const ApexLoadingSkeleton(count: 1, type: ApexSkeletonType.card),
                error: (e, _) => _err(e.toString()),
              ),
              const SizedBox(height: 12),

              // Department Block
              deptDistAsync.when(
                data: (data) => _buildDept(context, data),
                loading: () => const ApexLoadingSkeleton(count: 1, type: ApexSkeletonType.card),
                error: (e, _) => _err(e.toString()),
              ),
              const SizedBox(height: 12),

              // Pending Work Block
              _buildPendingWork(context),
              const SizedBox(height: 12),

              // Quick Actions Block
              _buildQuickActions(context),
              const SizedBox(height: 12),

              // Activity + Side widgets
              if (isMobile) ...[
                activityAsync.when(
                  data: (a) => _buildActivity(context, a),
                  loading: () => const ApexLoadingSkeleton(count: 5, type: ApexSkeletonType.list),
                  error: (e, _) => _err(e.toString()),
                ),
                const SizedBox(height: 12),
                syncHealthAsync.when(
                  data: (d) => _buildSyncHealth(context, d),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 12),
                birthdaysAsync.when(
                  data: (d) => _buildBirthdays(context, d),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: activityAsync.when(
                        data: (a) => _buildActivity(context, a),
                        loading: () => const ApexLoadingSkeleton(count: 5, type: ApexSkeletonType.list),
                        error: (e, _) => _err(e.toString()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          syncHealthAsync.when(
                            data: (d) => _buildSyncHealth(context, d),
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                          ),
                          const SizedBox(height: 12),
                          birthdaysAsync.when(
                            data: (d) => _buildBirthdays(context, d),
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                          ),
                          const SizedBox(height: 12),
                          anniversariesAsync.when(
                            data: (d) => _buildAnniversaries(context, d),
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                          ),
                        ],
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

  // ── KPI Block ────────────────────────────────────────────────
  Widget _buildKpis(BuildContext context, DashboardStats stats, bool isMobile) {
    final pct = stats.attendancePercentage;
    return GridView.count(
      crossAxisCount: isMobile ? 2 : 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: isMobile ? 1.6 : 2.0,
      children: [
        ApexStatCard(title: 'Attendance', value: '${pct.toStringAsFixed(0)}%', icon: Icons.people_outline,
          color: pct >= 90 ? ApexColors.success : pct >= 75 ? ApexColors.warning : ApexColors.error, onTap: () => context.push('/attendance')),
        ApexStatCard(title: 'Present', value: '${stats.employeesPresent}', icon: Icons.check_circle_outline,
          color: ApexColors.success, onTap: () => context.push('/attendance')),
        ApexStatCard(title: 'Absent', value: '${stats.employeesAbsent}', icon: Icons.cancel_outlined,
          color: ApexColors.error, onTap: () => context.push('/attendance')),
        ApexStatCard(title: 'Late', value: '${stats.lateToday}', icon: Icons.access_time,
          color: ApexColors.warning, onTap: () => context.push('/attendance')),
        ApexStatCard(title: 'Leave', value: '${stats.pendingLeaves}', icon: Icons.event_busy_outlined,
          color: ApexColors.accent, onTap: () => context.push('/leaves/requests')),
        ApexStatCard(title: 'Devices', value: '${stats.onlineDevices}', icon: Icons.biotech_outlined,
          color: stats.offlineDevices > 0 ? ApexColors.warning : ApexColors.success, onTap: () => context.push('/devices')),
        ApexStatCard(title: 'Visitors', value: '${stats.visitorsInside}', icon: Icons.card_membership_outlined,
          color: ApexColors.info, onTap: () => context.push('/visitors/active')),
      ],
    );
  }

  // ── Trend Block ──────────────────────────────────────────────
  Widget _buildTrend(BuildContext context, List<AttendanceTrend> trends) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ApexCard(
      header: Text('Attendance Trend', style: ApexTypography.titleMedium),
      child: trends.isEmpty
          ? const SizedBox(height: 160, child: Center(child: Text('No data')))
          : SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (v) => FlLine(color: isDark ? ApexColors.neutral800 : ApexColors.neutral100, strokeWidth: 0.5)),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                      final i = v.toInt();
                      if (i >= 0 && i < trends.length) return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(DateFormat('E').format(trends[i].date), style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                      );
                      return const SizedBox();
                    })),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: trends.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.present.toDouble())).toList(),
                      isCurved: true, color: ApexColors.primary, barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: ApexColors.primary.withOpacity(0.08)),
                    ),
                    LineChartBarData(
                      spots: trends.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.absent.toDouble())).toList(),
                      isCurved: true, color: ApexColors.error, barWidth: 1.5,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Department Block ─────────────────────────────────────────
  Widget _buildDept(BuildContext context, List<DepartmentDistribution> data) {
    return ApexCard(
      header: Text('Department Distribution', style: ApexTypography.titleMedium),
      child: data.isEmpty
          ? const SizedBox(height: 100, child: Center(child: Text('No data')))
          : Column(
              children: data.take(6).map((d) {
                final total = data.fold<int>(0, (s, x) => s + x.count);
                final pct = total > 0 ? d.count / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(width: 80, child: Text(d.department, style: ApexTypography.bodySmall, overflow: TextOverflow.ellipsis)),
                      Expanded(child: ClipRRect(
                        borderRadius: ApexRadius.xsAll,
                        child: LinearProgressIndicator(value: pct, backgroundColor: ApexColors.neutral100, color: ApexColors.primary, minHeight: 6),
                      )),
                      const SizedBox(width: 8),
                      SizedBox(width: 30, child: Text('${d.count}', style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  // ── Pending Work Block ───────────────────────────────────────
  Widget _buildPendingWork(BuildContext context) {
    return ApexCard(
      header: Text('Pending Work', style: ApexTypography.titleMedium),
      child: Column(
        children: [
          _pendingItem(context, Icons.warning_amber, 'Missing Punches', '3 employees', ApexColors.warning, () {}),
          const Divider(height: 1),
          _pendingItem(context, Icons.access_time, 'Late Arrivals', '5 employees', ApexColors.warning, () {}),
          const Divider(height: 1),
          _pendingItem(context, Icons.event_busy, 'Pending Approvals', '2 requests', ApexColors.accent, () => context.push('/leaves/requests')),
          const Divider(height: 1),
          _pendingItem(context, Icons.cloud_off, 'Offline Devices', '1 device', ApexColors.error, () => context.push('/devices')),
        ],
      ),
    );
  }

  Widget _pendingItem(BuildContext context, IconData icon, String title, String count, Color color, VoidCallback onTap) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 18, color: color),
      title: Text(title, style: ApexTypography.bodySmall),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(count, style: ApexTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: color)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 16, color: ApexColors.neutral400),
        ],
      ),
      onTap: onTap,
    );
  }

  // ── Quick Actions Block ──────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    return ApexCard(
      header: Text('Quick Actions', style: ApexTypography.titleMedium),
      child: Row(
        children: [
          Expanded(child: _actionBtn(context, Icons.person_add, 'Add Employee', () => context.push('/employees/create'))),
          const SizedBox(width: 8),
          Expanded(child: _actionBtn(context, Icons.calendar_today, 'Mark Attendance', () => context.push('/attendance/mark'))),
          const SizedBox(width: 8),
          Expanded(child: _actionBtn(context, Icons.event_busy, 'Apply Leave', () => context.push('/leaves/apply'))),
          const SizedBox(width: 8),
          Expanded(child: _actionBtn(context, Icons.assessment, 'Reports', () => context.push('/reports'))),
        ],
      ),
    );
  }

  Widget _actionBtn(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: ApexRadius.smAll,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: ApexColors.neutral200),
          borderRadius: ApexRadius.smAll,
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: ApexColors.primary),
            const SizedBox(height: 4),
            Text(label, style: ApexTypography.captionSmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── Activity Block ───────────────────────────────────────────
  Widget _buildActivity(BuildContext context, List<RecentActivity> activities) {
    return ApexCard(
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Recent Activity', style: ApexTypography.titleMedium),
          TextButton(onPressed: () => context.push('/notifications'), child: const Text('View All')),
        ],
      ),
      child: activities.isEmpty
          ? const Padding(padding: EdgeInsets.all(16), child: Text('No activity', style: TextStyle(color: ApexColors.neutral500)))
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length > 8 ? 8 : activities.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final a = activities[i];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: ApexColors.neutral100,
                    child: Icon(_actIcon(a.activityType), size: 14, color: ApexColors.neutral600),
                  ),
                  title: Text(a.description, style: ApexTypography.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(DateFormat('hh:mm a').format(DateTime.tryParse(a.timestamp) ?? DateTime.now()), style: ApexTypography.captionSmall),
                );
              },
            ),
    );
  }

  // ── Sync Health Block ────────────────────────────────────────
  Widget _buildSyncHealth(BuildContext context, SyncHealthStatus data) {
    return ApexCard(
      header: Text('Sync Health', style: ApexTypography.titleMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _syncStat('Servers', '${data.totalServers}', ApexColors.neutral600),
          _syncStat('Connected', '${data.connected}', ApexColors.success),
          _syncStat('Error', '${data.error}', data.error > 0 ? ApexColors.error : ApexColors.success),
        ],
      ),
    );
  }

  Widget _syncStat(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: ApexTypography.headingMedium.copyWith(color: color)),
      Text(label, style: ApexTypography.kpiLabel),
    ]);
  }

  // ── Birthdays Block ──────────────────────────────────────────
  Widget _buildBirthdays(BuildContext context, List<BirthdayItem> data) {
    return ApexCard(
      header: Row(children: [
        const Icon(Icons.cake, size: 14, color: ApexColors.accent),
        const SizedBox(width: 6),
        Text('Birthdays', style: ApexTypography.titleMedium),
      ]),
      child: data.isEmpty
          ? const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('None this month', style: TextStyle(color: ApexColors.neutral500)))
          : Column(children: data.take(3).map((b) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(radius: 12, backgroundColor: ApexColors.accent50, child: Text(b.name[0].toUpperCase(), style: ApexTypography.captionSmall.copyWith(color: ApexColors.accent))),
              title: Text(b.name, style: ApexTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(DateFormat('MMM dd').format(DateTime.parse(b.dateOfBirth)), style: ApexTypography.captionSmall),
            )).toList()),
    );
  }

  // ── Anniversaries Block ──────────────────────────────────────
  Widget _buildAnniversaries(BuildContext context, List<AnniversaryItem> data) {
    return ApexCard(
      header: Row(children: [
        const Icon(Icons.celebration, size: 14, color: ApexColors.secondary),
        const SizedBox(width: 6),
        Text('Anniversaries', style: ApexTypography.titleMedium),
      ]),
      child: data.isEmpty
          ? const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('None this month', style: TextStyle(color: ApexColors.neutral500)))
          : Column(children: data.take(3).map((a) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(radius: 12, backgroundColor: ApexColors.secondary50, child: Text('${a.years}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.secondary))),
              title: Text(a.name, style: ApexTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text('${a.years}yr', style: ApexTypography.captionSmall),
            )).toList()),
    );
  }

  Widget _err(String msg) => ApexCard(child: Row(children: [
    const Icon(Icons.error_outline, color: ApexColors.error, size: 18),
    const SizedBox(width: 8),
    Expanded(child: Text(msg, style: ApexTypography.bodySmall.copyWith(color: ApexColors.error))),
  ]));

  IconData _actIcon(String type) {
    if (type.contains('punch')) return Icons.fingerprint;
    if (type.contains('device')) return Icons.biotech;
    if (type.contains('visitor')) return Icons.card_membership;
    if (type.contains('leave')) return Icons.event_busy;
    return Icons.notifications_none;
  }
}
