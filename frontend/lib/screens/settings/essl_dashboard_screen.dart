import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../models/essl_server.dart';
import '../../providers/essl_provider.dart';
import '../../services/essl_service.dart';
import '../../core/dio_client.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';

class EsslDashboardScreen extends ConsumerStatefulWidget {
  const EsslDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EsslDashboardScreen> createState() => _EsslDashboardScreenState();
}

class _EsslDashboardScreenState extends ConsumerState<EsslDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        title: const Text('eSSL Sync Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: ApexColors.neutral200),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(esslDashboardProvider);
              ref.invalidate(enterpriseSyncDashboardProvider(7));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: ApexColors.primary,
              unselectedLabelColor: ApexColors.neutral500,
              indicatorColor: ApexColors.primary,
              tabs: const [
                Tab(text: 'Health Overview', icon: Icon(Icons.monitor_heart)),
                Tab(text: 'Server Details', icon: Icon(Icons.dns)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _EnterpriseTab(),
                _ServerDetailsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnterpriseTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enterpriseAsync = ref.watch(enterpriseSyncDashboardProvider(7));

    return enterpriseAsync.when(
      data: (data) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(enterpriseSyncDashboardProvider(7)),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverallHealthCard(context, data),
              const SizedBox(height: 16),
              _buildAggregateStats(context, data),
              const SizedBox(height: 16),
              if (data.servers.isNotEmpty) ...[
                Text('Server Health', style: ApexTypography.cardTitle),
                const SizedBox(height: 8),
                ...data.servers.map((s) => _buildServerHealthCard(context, s)),
              ],
              if (data.throughputTrend.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Sync Throughput (7 days)', style: ApexTypography.cardTitle),
                const SizedBox(height: 8),
                _buildThroughputChart(context, data.throughputTrend),
              ],
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: ApexColors.error),
            const SizedBox(height: 16),
            Text('Error: $err', style: ApexTypography.body),
            const SizedBox(height: 16),
            ApexButton(
              label: 'Retry',
              onPressed: () => ref.invalidate(enterpriseSyncDashboardProvider(7)),
              type: ApexButtonType.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallHealthCard(BuildContext context, EnterpriseSyncDashboard data) {
    final color = _healthColor(data.overallHealthScore);
    return ApexCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: data.overallHealthScore / 100,
                  strokeWidth: 8,
                  backgroundColor: ApexColors.neutral200,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                Text(
                  '${data.overallHealthScore}',
                  style: ApexTypography.headingLarge.copyWith(color: color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall Sync Health', style: ApexTypography.sectionTitle),
                const SizedBox(height: 4),
                Text(
                  '${data.healthyServers} healthy, ${data.degradedServers} degraded, ${data.downServers} down',
                  style: ApexTypography.body.copyWith(color: ApexColors.neutral500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAggregateStats(BuildContext context, EnterpriseSyncDashboard data) {
    return Row(
      children: [
        Expanded(child: _buildMiniStat('Servers', '${data.totalServers}', Icons.dns, ApexColors.info)),
        const SizedBox(width: 8),
        Expanded(child: _buildMiniStat('Pending', '${data.totalPendingRawLogs}', Icons.hourglass_empty, ApexColors.warning)),
        const SizedBox(width: 8),
        Expanded(child: _buildMiniStat('Syncs Today', '${data.totalSyncsToday}', Icons.sync, ApexColors.success)),
        const SizedBox(width: 8),
        Expanded(child: _buildMiniStat('Errors', '${data.totalErrorsToday}', Icons.error_outline, ApexColors.error)),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return ApexCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: ApexTypography.cardTitle.copyWith(color: color)),
          Text(label, style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
        ],
      ),
    );
  }

  Widget _buildServerHealthCard(BuildContext context, ServerSyncHealth server) {
    final color = _healthColor(server.healthScore);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ApexCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: server.healthScore / 100,
                        strokeWidth: 5,
                        backgroundColor: ApexColors.neutral200,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                      Text('${server.healthScore}', style: ApexTypography.caption.copyWith(fontWeight: FontWeight.bold, color: color)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(server.serverName, style: ApexTypography.body.copyWith(fontWeight: FontWeight.bold)),
                      Text(server.connectionStatus.toUpperCase(), style: ApexTypography.captionSmall.copyWith(color: _statusColor(server.connectionStatus))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (server.throughputPerHour > 0)
                      Text('${server.throughputPerHour.toStringAsFixed(0)}/hr', style: ApexTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                    if (server.rawLogBacklog > 0)
                      Text('${server.rawLogBacklog} pending', style: ApexTypography.captionSmall.copyWith(color: ApexColors.warning)),
                  ],
                ),
              ],
            ),
            if (server.alerts.isNotEmpty) ...[
              Divider(height: 16, color: ApexColors.neutral200),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: server.alerts.map((a) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ApexColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(a, style: ApexTypography.captionSmall.copyWith(color: ApexColors.error)),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThroughputChart(BuildContext context, List<SyncThroughputPoint> points) {
    return ApexCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: ApexColors.neutral200, strokeWidth: 0.5)),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= 0 && idx < points.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(DateFormat('MM/dd').format(points[idx].timestamp), style: ApexTypography.captionSmall),
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
                spots: points.asMap().entries.map((e) =>
                  FlSpot(e.key.toDouble(), e.value.recordsSynced.toDouble())
                ).toList(),
                isCurved: true,
                color: ApexColors.primary,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: ApexColors.primary.withValues(alpha: 0.1)),
              ),
              LineChartBarData(
                spots: points.asMap().entries.map((e) =>
                  FlSpot(e.key.toDouble(), e.value.errors.toDouble())
                ).toList(),
                isCurved: true,
                color: ApexColors.error,
                barWidth: 2,
                dotData: const FlDotData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServerDetailsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(esslDashboardProvider);

    return dashboardAsync.when(
      data: (servers) {
        if (servers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.dns_outlined, size: 64, color: ApexColors.neutral400),
                const SizedBox(height: 16),
                Text('No eSSL Servers Configured', style: ApexTypography.sectionTitle),
                const SizedBox(height: 8),
                Text('Add an eSSL server to start syncing attendance data.', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(esslDashboardProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: servers.length,
            itemBuilder: (context, index) => _buildServerCard(context, ref, servers[index]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: ApexColors.error),
            const SizedBox(height: 16),
            Text('Error: $err', style: ApexTypography.body),
            const SizedBox(height: 16),
            ApexButton(
              label: 'Retry',
              onPressed: () => ref.invalidate(esslDashboardProvider),
              type: ApexButtonType.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerCard(BuildContext context, WidgetRef ref, EsslSyncDashboardStatus server) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ApexCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_statusIcon(server.connectionStatus), color: _statusColor(server.connectionStatus), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(server.serverName, style: ApexTypography.sectionTitle),
                      Text('Server ID: ${server.serverId.substring(0, 8)}...', style: ApexTypography.caption),
                    ],
                  ),
                ),
                _buildStatusChip(server.connectionStatus),
              ],
            ),
            Divider(height: 24, color: ApexColors.neutral200),

            if (server.currentSyncState != null) ...[
              _buildSection('Current Sync', [
                _buildRow('State', server.currentSyncState!.toUpperCase(), _syncStateColor(server.currentSyncState)),
                if (server.currentSyncState == 'running' || server.currentSyncState == 'paused')
                  _buildProgressBar(server.currentProgressPercent),
              ]),
              Divider(height: 16, color: ApexColors.neutral200),
            ],

            _buildSection('Connection & Sync', [
              _buildRow('Last Connected', _formatDateTime(server.lastConnectedAt)),
              _buildRow('SOAP Response Time', server.soapResponseTimeMs != null ? '${server.soapResponseTimeMs}ms' : 'N/A'),
              _buildRow('Last Sync Duration', server.lastSyncDurationSeconds != null ? '${server.lastSyncDurationSeconds!.toStringAsFixed(1)}s' : 'N/A'),
              _buildRow('Recovery Status', server.recoveryStatus ?? 'ok', _recoveryColor(server.recoveryStatus)),
            ]),
            Divider(height: 16, color: ApexColors.neutral200),

            _buildSection('Last Successful Sync', [
              _buildRow('Attendance', _formatDateTime(server.lastAttendanceSync)),
              _buildRow('Employees', _formatDateTime(server.lastEmployeeSync)),
              _buildRow('Devices', _formatDateTime(server.lastDeviceSync)),
              _buildRow('Next Scheduled', _formatDateTime(server.nextScheduledSync)),
            ]),
            Divider(height: 16, color: ApexColors.neutral200),

            _buildSection('Data Statistics', [
              Row(
                children: [
                  Expanded(child: _buildStatCard('Devices', '${server.totalDevices}', Icons.devices, ApexColors.info)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Employees', '${server.totalEmployeesSynced}', Icons.people, ApexColors.success)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Today', '${server.recordsDownloadedToday}', Icons.today, ApexColors.warning)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Pending', '${server.pendingRawLogs}', Icons.hourglass_empty, ApexColors.accent500)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Duplicates', '${server.duplicatePunchesDetected}', Icons.copy, ApexColors.secondary)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Failed', '${server.failedSyncAttempts}', Icons.error, ApexColors.error)),
                ],
              ),
            ]),
            Divider(height: 16, color: ApexColors.neutral200),

            _buildSection('Cursor & Recovery', [
              _buildRow('Cursor Position', _formatDateTime(server.currentCursorPosition)),
              _buildRow('Consecutive Failures', '${server.consecutiveFailures}', server.consecutiveFailures > 3 ? ApexColors.error : null),
              _buildRow('Duplicates Detected', '${server.duplicatePunchesDetected}'),
              _buildRow('Duplicates Resolved', '${server.duplicatePunchesResolved}'),
            ]),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton('Sync Attendance', Icons.sync, () => _syncAction(context, ref, server.serverId, 'attendance')),
                _buildActionButton('Sync Employees', Icons.people, () => _syncAction(context, ref, server.serverId, 'employees')),
                _buildActionButton('Sync Devices', Icons.devices, () => _syncAction(context, ref, server.serverId, 'devices')),
                _buildActionButton('Reprocess', Icons.refresh, () => context.push('/settings/essl/${server.serverId}/reprocess')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: ApexTypography.sectionHeader),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ApexTypography.body),
          Text(value, style: ApexTypography.body.copyWith(fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percent / 100,
          backgroundColor: ApexColors.neutral200,
          color: ApexColors.primary,
          minHeight: 8,
        ),
        const SizedBox(height: 4),
        Text('$percent%', style: ApexTypography.caption.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: ApexTypography.cardTitle.copyWith(color: color)),
          Text(label, style: ApexTypography.captionSmall.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toUpperCase(),
        style: ApexTypography.caption.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return TextButton.icon(
      icon: Icon(icon, size: 16, color: ApexColors.primary),
      label: Text(label, style: ApexTypography.captionSmall.copyWith(color: ApexColors.primary)),
      onPressed: onPressed,
    );
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Never';
    return DateFormat('MMM dd, HH:mm').format(dt);
  }

  Future<void> _syncAction(BuildContext context, WidgetRef ref, String serverId, String type) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator(color: ApexColors.primary)),
    );
    try {
      final service = ref.read(esslServiceProvider);
      switch (type) {
        case 'attendance': await service.syncAttendance(serverId); break;
        case 'employees': await service.syncEmployees(serverId); break;
        case 'devices': await service.syncDevices(serverId); break;
      }
      if (context.mounted) {
        Navigator.pop(context);
        ref.invalidate(esslDashboardProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$type sync completed'), backgroundColor: ApexColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e'), backgroundColor: ApexColors.error),
        );
      }
    }
  }
}

Color _healthColor(int score) {
  if (score >= 80) return ApexColors.success;
  if (score >= 50) return ApexColors.warning;
  return ApexColors.error;
}

Color _statusColor(String status) {
  switch (status) {
    case 'connected': return ApexColors.success;
    case 'testing': return ApexColors.warning;
    case 'error': return ApexColors.error;
    default: return ApexColors.neutral500;
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case 'connected': return Icons.check_circle;
    case 'testing': return Icons.sync;
    case 'error': return Icons.error;
    default: return Icons.cloud_off;
  }
}

Color _syncStateColor(String? state) {
  switch (state) {
    case 'running': return ApexColors.primary;
    case 'paused': return ApexColors.warning;
    case 'cancelled': return ApexColors.neutral500;
    case 'completed': return ApexColors.success;
    case 'failed': return ApexColors.error;
    default: return ApexColors.neutral500;
  }
}

Color _recoveryColor(String? status) {
  switch (status) {
    case 'ok': return ApexColors.success;
    case 'offline': return ApexColors.error;
    case 'backlog': return ApexColors.warning;
    default: return ApexColors.neutral500;
  }
}
