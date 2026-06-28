import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/border_radius.dart';
import '../../providers/auth_provider.dart';
import '../../screens/school/school_dashboard_screen.dart';
import '../../models/dashboard.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check tenant type and show appropriate dashboard
    final authState = ref.watch(authProvider);
    final user = authState.value;
    if (user != null && user.isSchool) {
      return const SchoolDashboardScreen();
    }

    final statsAsync = ref.watch(dashboardStatsProvider);
    final chartAsync = ref.watch(dashboardChartProvider(7));
    final deptAsync = ref.watch(departmentDistributionProvider);
    final activityAsync = ref.watch(recentPunchLogsProvider);
    final syncAsync = ref.watch(syncHealthProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(dashboardChartProvider(7));
          ref.invalidate(departmentDistributionProvider);
          ref.invalidate(recentPunchLogsProvider);
          ref.invalidate(syncHealthProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── RULE 4: Header ──────────────────────────
              _Header(),
              const SizedBox(height: 16),

              // ── RULE 4: KPI Row ─────────────────────────
              statsAsync.when(
                data: (s) => _KpiRow(stats: s),
                loading: () => const SizedBox(height: 88, child: Center(child: CircularProgressIndicator())),
                error: (e, _) => _ErrorCard(msg: e.toString()),
              ),
              const SizedBox(height: 16),

              // ── Charts Row ───────────────────────────────
              if (Responsive.isDesktop(context))
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: chartAsync.when(
                        data: (t) => _TrendChart(data: t),
                        loading: () => const _LoadingCard(height: 200),
                        error: (e, _) => _ErrorCard(msg: e.toString()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: deptAsync.when(
                        data: (d) => _DeptDistribution(data: d),
                        loading: () => const _LoadingCard(height: 200),
                        error: (e, _) => _ErrorCard(msg: e.toString()),
                      ),
                    ),
                  ],
                )
              else ...[
                chartAsync.when(
                  data: (t) => _TrendChart(data: t),
                  loading: () => const _LoadingCard(height: 200),
                  error: (e, _) => _ErrorCard(msg: e.toString()),
                ),
                const SizedBox(height: 12),
                deptAsync.when(
                  data: (d) => _DeptDistribution(data: d),
                  loading: () => const _LoadingCard(height: 200),
                  error: (e, _) => _ErrorCard(msg: e.toString()),
                ),
              ],
              const SizedBox(height: 16),

              // ── Pending Work + Activity ──────────────────
              statsAsync.when(
                data: (stats) => Responsive.isDesktop(context)
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _PendingWork(stats: stats)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: activityAsync.when(
                            data: (a) => _RecentPunchLogs(data: a),
                            loading: () => const _LoadingCard(height: 300),
                            error: (e, _) => _ErrorCard(msg: e.toString()),
                          ),
                        ),
                      ],
                    )
                  : Column(children: [
                      _PendingWork(stats: stats),
                      const SizedBox(height: 12),
                      activityAsync.when(
                        data: (a) => _RecentPunchLogs(data: a),
                        loading: () => const _LoadingCard(height: 300),
                        error: (e, _) => _ErrorCard(msg: e.toString()),
                      ),
                    ]),
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),

              // ── Quick Actions + Sync Health ──────────────
              if (Responsive.isDesktop(context))
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _QuickActions()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: syncAsync.when(
                        data: (d) => _SyncHealth(data: d),
                        loading: () => const _LoadingCard(height: 120),
                        error: (_, __) => const SizedBox(),
                      ),
                    ),
                  ],
                )
              else ...[
                _QuickActions(),
                const SizedBox(height: 12),
                syncAsync.when(
                  data: (d) => _SyncHealth(data: d),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── RULE 4: Header ─────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard', style: ApexTypography.pageTitle.copyWith(color: ApexColors.neutral900)),
            Text(
              DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now()),
              style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500),
            ),
          ],
        ),
        const Spacer(),
        if (!Responsive.isMobile(context))
          ElevatedButton.icon(
            onPressed: () => context.push('/attendance/mark'),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Mark Attendance'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ApexColors.primary600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
      ],
    );
  }
}

// ── RULE 3: KPI Row — business purpose only ────────────────
class _KpiRow extends StatelessWidget {
  final DashboardStats stats;
  const _KpiRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final pct = stats.attendancePercentage;

    return GridView.count(
      crossAxisCount: isMobile ? 2 : 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: isMobile ? 1.6 : 2.0,
      children: [
        _KpiCard(label: 'Attendance', value: '${pct.toStringAsFixed(0)}%', color: pct >= 90 ? ApexColors.successDark : ApexColors.warning, onTap: () => context.push('/attendance')),
        _KpiCard(label: 'Present', value: '${stats.employeesPresent}', color: ApexColors.successDark, onTap: () => context.push('/attendance')),
        _KpiCard(label: 'Absent', value: '${stats.employeesAbsent}', color: ApexColors.error, onTap: () => context.push('/attendance')),
        _KpiCard(label: 'Late', value: '${stats.lateToday}', color: ApexColors.warning, onTap: () => context.push('/attendance')),
        _KpiCard(label: 'Leave', value: '${stats.pendingLeaves}', color: ApexColors.primary600, onTap: () => context.push('/leaves/requests')),
        _KpiCard(label: 'Devices', value: '${stats.onlineDevices}', color: stats.offlineDevices > 0 ? ApexColors.warning : ApexColors.successDark, onTap: () => context.push('/devices')),
        _KpiCard(label: 'Visitors', value: '${stats.visitorsInside}', color: ApexColors.primary600, onTap: () => context.push('/visitors/active')),
      ],
    );
  }
}

class _KpiCard extends StatefulWidget {
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _KpiCard({required this.label, required this.value, required this.color, this.onTap});

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: ApexColors.neutral0,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _hovered ? widget.color.withOpacity(0.4) : ApexColors.neutral200),
          ),
          child: Row(
            children: [
              Container(width: 4, decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.value, style: ApexTypography.kpiValue.copyWith(color: ApexColors.neutral900)),
                    Text(widget.label, style: ApexTypography.kpiLabel),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Trend Chart ─────────────────────────────────────────────
class _TrendChart extends StatelessWidget {
  final List<AttendanceTrend> data;
  const _TrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Attendance Trend',
      child: data.isEmpty
          ? const _EmptyBlock(msg: 'No attendance data yet')
          : SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (v) => FlLine(color: ApexColors.neutral200, strokeWidth: 0.5),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                      final i = v.toInt();
                      if (i >= 0 && i < data.length) return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(DateFormat('E').format(data[i].date), style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
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
                      spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.present.toDouble())).toList(),
                      isCurved: true, color: ApexColors.primary600, barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: ApexColors.primary600.withOpacity(0.08)),
                    ),
                    LineChartBarData(
                      spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.absent.toDouble())).toList(),
                      isCurved: true, color: ApexColors.error, barWidth: 1.5,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ── Department Distribution ─────────────────────────────────
class _DeptDistribution extends StatelessWidget {
  final List<DepartmentDistribution> data;
  const _DeptDistribution({required this.data});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Departments',
      child: data.isEmpty
          ? const _EmptyBlock(msg: 'No departments configured')
          : Column(
              children: data.take(6).map((d) {
                final total = data.fold<int>(0, (s, x) => s + x.count);
                final pct = total > 0 ? d.count / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(width: 80, child: Text(d.department, style: ApexTypography.bodySmall, overflow: TextOverflow.ellipsis)),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(value: pct, backgroundColor: ApexColors.neutral200, color: ApexColors.primary600, minHeight: 6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(width: 30, child: Text('${d.count}', style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ── RULE 3: Pending Work — business purpose ─────────────────
class _PendingWork extends StatelessWidget {
  final DashboardStats stats;
  const _PendingWork({required this.stats});
  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Pending Work',
      child: Column(
        children: [
          _PendingItem(icon: Icons.warning_amber, label: 'Missing Punches', count: '${stats.missingPunches} employees', color: ApexColors.warning, onTap: () => context.push('/attendance')),
          const Divider(height: 1, color: ApexColors.neutral200),
          _PendingItem(icon: Icons.access_time, label: 'Late Today', count: '${stats.lateToday} employees', color: ApexColors.warning, onTap: () => context.push('/attendance')),
          const Divider(height: 1, color: ApexColors.neutral200),
          _PendingItem(icon: Icons.event_busy, label: 'Pending Approvals', count: '${stats.pendingLeaves} requests', color: ApexColors.primary600, onTap: () => context.push('/leaves/requests')),
          const Divider(height: 1, color: ApexColors.neutral200),
          _PendingItem(icon: Icons.cloud_off, label: 'Offline Devices', count: '${stats.offlineDevices} devices', color: ApexColors.error, onTap: () => context.push('/devices')),
        ],
      ),
    );
  }
}

class _PendingItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final Color color;
  final VoidCallback? onTap;

  const _PendingItem({required this.icon, required this.label, required this.count, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 18, color: color),
      title: Text(label, style: ApexTypography.bodySmall),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(count, style: ApexTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: color)),
          Icon(Icons.chevron_right, size: 16, color: ApexColors.neutral500),
        ],
      ),
      onTap: onTap,
    );
  }
}

// ── Activity Feed ───────────────────────────────────────────
class _RecentPunchLogs extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _RecentPunchLogs({required this.data});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Recent Punch Logs',
      child: data.isEmpty
          ? const _EmptyBlock(msg: 'No punch logs yet')
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length > 8 ? 8 : data.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: ApexColors.neutral200),
              itemBuilder: (context, i) {
                final log = data[i];
                final empName = log['employee_name'] ?? log['employee_code'] ?? 'Unknown';
                final punchTime = log['punch_time'] ?? '';
                final punchType = log['punch_type'] ?? '';
                final isIn = punchType.toString().toLowerCase().contains('in');
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: isIn ? ApexColors.successDark.withOpacity(0.1) : ApexColors.error.withOpacity(0.1),
                    child: Icon(Icons.fingerprint, size: 14, color: isIn ? ApexColors.successDark : ApexColors.error),
                  ),
                  title: Text('$empName', style: ApexTypography.caption.copyWith(fontWeight: FontWeight.w500, color: ApexColors.neutral900), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${punchType.toString().toUpperCase()}  •  ${_formatTime(punchTime)}',
                    style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500),
                  ),
                );
              },
            ),
    );
  }

  String _formatTime(dynamic time) {
    if (time == null) return '';
    try {
      final dt = DateTime.parse(time.toString());
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return time.toString();
    }
  }
}

// ── Quick Actions ───────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Quick Actions',
      child: Row(
        children: [
          Expanded(child: _ActionBtn(icon: Icons.person_add, label: 'Add Employee', onTap: () => context.push('/employees/create'))),
          const SizedBox(width: 8),
          Expanded(child: _ActionBtn(icon: Icons.calendar_today, label: 'Mark Attendance', onTap: () => context.push('/attendance/mark'))),
          const SizedBox(width: 8),
          Expanded(child: _ActionBtn(icon: Icons.event_busy, label: 'Apply Leave', onTap: () => context.push('/leaves/apply'))),
          const SizedBox(width: 8),
          Expanded(child: _ActionBtn(icon: Icons.assessment, label: 'Reports', onTap: () => context.push('/reports'))),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionBtn({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: ApexColors.neutral200),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: ApexColors.primary600),
            const SizedBox(height: 4),
            Text(label, style: ApexTypography.captionSmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Sync Health ─────────────────────────────────────────────
class _SyncHealth extends StatelessWidget {
  final SyncHealthStatus data;
  const _SyncHealth({required this.data});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Sync Health',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SyncStat(label: 'Servers', value: '${data.totalServers}', color: ApexColors.neutral500),
          _SyncStat(label: 'Connected', value: '${data.connected}', color: ApexColors.successDark),
          _SyncStat(label: 'Error', value: '${data.error}', color: data.error > 0 ? ApexColors.error : ApexColors.successDark),
        ],
      ),
    );
  }
}

class _SyncStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SyncStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: ApexTypography.headingMedium.copyWith(color: color)),
      Text(label, style: ApexTypography.kpiLabel),
    ]);
  }
}

// ── Shared Widgets ──────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ApexColors.neutral0,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ApexColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: ApexTypography.sectionHeader),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  final String msg;
  const _EmptyBlock({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(child: Text(msg, style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500))),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String msg;
  const _ErrorCard({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ApexColors.neutral0,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ApexColors.neutral200),
      ),
      child: Row(children: [
        Icon(Icons.error_outline, color: ApexColors.error, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: ApexTypography.bodySmall.copyWith(color: ApexColors.error))),
      ]),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final double height;
  const _LoadingCard({this.height = 100});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: ApexColors.neutral0,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ApexColors.neutral200),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

