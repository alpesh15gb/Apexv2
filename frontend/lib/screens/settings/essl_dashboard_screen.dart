import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/essl_server.dart';
import '../../providers/essl_provider.dart';
import '../../services/essl_service.dart';
import '../../core/dio_client.dart';

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
      appBar: AppBar(
        title: const Text('eSSL Sync Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(esslDashboardProvider);
              ref.invalidate(enterpriseSyncDashboardProvider(7));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Health Overview', icon: Icon(Icons.monitor_heart)),
            Tab(text: 'Server Details', icon: Icon(Icons.dns)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _EnterpriseTab(),
          _ServerDetailsTab(),
        ],
      ),
    );
  }
}

class _EnterpriseTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enterpriseAsync = ref.watch(enterpriseSyncDashboardProvider(7));
    final theme = Theme.of(context);

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
                const Text('Server Health', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...data.servers.map((s) => _buildServerHealthCard(context, s)),
              ],
              if (data.throughputTrend.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Sync Throughput (7 days)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $err'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(enterpriseSyncDashboardProvider(7)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallHealthCard(BuildContext context, EnterpriseSyncDashboard data) {
    final color = _healthColor(data.overallHealthScore);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
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
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                      Text(
                        '${data.overallHealthScore}',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Overall Sync Health', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        '${data.healthyServers} healthy, ${data.degradedServers} degraded, ${data.downServers} down',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAggregateStats(BuildContext context, EnterpriseSyncDashboard data) {
    return Row(
      children: [
        Expanded(child: _buildMiniStat('Servers', '${data.totalServers}', Icons.dns, Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _buildMiniStat('Pending', '${data.totalPendingRawLogs}', Icons.hourglass_empty, Colors.orange)),
        const SizedBox(width: 8),
        Expanded(child: _buildMiniStat('Syncs Today', '${data.totalSyncsToday}', Icons.sync, Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: _buildMiniStat('Errors', '${data.totalErrorsToday}', Icons.error_outline, Colors.red)),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildServerHealthCard(BuildContext context, ServerSyncHealth server) {
    final color = _healthColor(server.healthScore);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
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
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                      Text('${server.healthScore}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(server.serverName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(server.connectionStatus.toUpperCase(), style: TextStyle(fontSize: 11, color: _statusColor(server.connectionStatus))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (server.throughputPerHour > 0)
                      Text('${server.throughputPerHour.toStringAsFixed(0)}/hr', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    if (server.rawLogBacklog > 0)
                      Text('${server.rawLogBacklog} pending', style: TextStyle(fontSize: 11, color: Colors.orange.shade700)),
                  ],
                ),
              ],
            ),
            if (server.alerts.isNotEmpty) ...[
              const Divider(height: 16),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: server.alerts.map((a) => Chip(
                  label: Text(a, style: const TextStyle(fontSize: 10)),
                  backgroundColor: Colors.red.shade50,
                  labelStyle: TextStyle(color: Colors.red.shade700),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThroughputChart(BuildContext context, List<SyncThroughputPoint> points) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < points.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(DateFormat('MM/dd').format(points[idx].timestamp), style: const TextStyle(fontSize: 10)),
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
                  color: Colors.blue,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
                ),
                LineChartBarData(
                  spots: points.asMap().entries.map((e) =>
                    FlSpot(e.key.toDouble(), e.value.errors.toDouble())
                  ).toList(),
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
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
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.dns_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No eSSL Servers Configured', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Add an eSSL server to start syncing attendance data.'),
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
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $err'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(esslDashboardProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerCard(BuildContext context, WidgetRef ref, EsslSyncDashboardStatus server) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
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
                      Text(server.serverName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Server ID: ${server.serverId.substring(0, 8)}...', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                _buildStatusChip(server.connectionStatus),
              ],
            ),
            const Divider(height: 24),

            if (server.currentSyncState != null) ...[
              _buildSection('Current Sync', [
                _buildRow('State', server.currentSyncState!.toUpperCase(), _syncStateColor(server.currentSyncState)),
                if (server.currentSyncState == 'running' || server.currentSyncState == 'paused')
                  _buildProgressBar(server.currentProgressPercent),
              ]),
              const Divider(height: 16),
            ],

            _buildSection('Connection & Sync', [
              _buildRow('Last Connected', _formatDateTime(server.lastConnectedAt)),
              _buildRow('SOAP Response Time', server.soapResponseTimeMs != null ? '${server.soapResponseTimeMs}ms' : 'N/A'),
              _buildRow('Last Sync Duration', server.lastSyncDurationSeconds != null ? '${server.lastSyncDurationSeconds!.toStringAsFixed(1)}s' : 'N/A'),
              _buildRow('Recovery Status', server.recoveryStatus ?? 'ok', _recoveryColor(server.recoveryStatus)),
            ]),
            const Divider(height: 16),

            _buildSection('Last Successful Sync', [
              _buildRow('Attendance', _formatDateTime(server.lastAttendanceSync)),
              _buildRow('Employees', _formatDateTime(server.lastEmployeeSync)),
              _buildRow('Devices', _formatDateTime(server.lastDeviceSync)),
              _buildRow('Next Scheduled', _formatDateTime(server.nextScheduledSync)),
            ]),
            const Divider(height: 16),

            _buildSection('Data Statistics', [
              Row(
                children: [
                  Expanded(child: _buildStatCard('Devices', '${server.totalDevices}', Icons.devices, Colors.blue)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Employees', '${server.totalEmployeesSynced}', Icons.people, Colors.green)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Today', '${server.recordsDownloadedToday}', Icons.today, Colors.orange)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Pending', '${server.pendingRawLogs}', Icons.hourglass_empty, Colors.purple)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Duplicates', '${server.duplicatePunchesDetected}', Icons.copy, Colors.teal)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Failed', '${server.failedSyncAttempts}', Icons.error, Colors.red)),
                ],
              ),
            ]),
            const Divider(height: 16),

            _buildSection('Cursor & Recovery', [
              _buildRow('Cursor Position', _formatDateTime(server.currentCursorPosition)),
              _buildRow('Consecutive Failures', '${server.consecutiveFailures}', server.consecutiveFailures > 3 ? Colors.red : null),
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
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
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
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor)),
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
          backgroundColor: Colors.grey.shade200,
          minHeight: 8,
        ),
        const SizedBox(height: 4),
        Text('$percent%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _statusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return TextButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
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
      builder: (_) => const Center(child: CircularProgressIndicator()),
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
          SnackBar(content: Text('$type sync completed'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

Color _healthColor(int score) {
  if (score >= 80) return Colors.green;
  if (score >= 50) return Colors.orange;
  return Colors.red;
}

Color _statusColor(String status) {
  switch (status) {
    case 'connected': return Colors.green;
    case 'testing': return Colors.orange;
    case 'error': return Colors.red;
    default: return Colors.grey;
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
    case 'running': return Colors.blue;
    case 'paused': return Colors.orange;
    case 'cancelled': return Colors.grey;
    case 'completed': return Colors.green;
    case 'failed': return Colors.red;
    default: return Colors.grey;
  }
}

Color _recoveryColor(String? status) {
  switch (status) {
    case 'ok': return Colors.green;
    case 'offline': return Colors.red;
    case 'backlog': return Colors.orange;
    default: return Colors.grey;
  }
}
