import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_card.dart';

final healthProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/system/health');
    return Map<String, dynamic>.from(res.data);
  } catch (e) {
    return {'status': 'error', 'database': 'disconnected'};
  }
});

final metricsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/system/metrics');
    return Map<String, dynamic>.from(res.data);
  } catch (e) {
    return {};
  }
});

final usageProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/system/tenant-usage');
    return Map<String, dynamic>.from(res.data);
  } catch (e) {
    return {};
  }
});

class HealthDashboardScreen extends ConsumerWidget {
  const HealthDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(healthProvider);
    final metricsAsync = ref.watch(metricsProvider);
    final usageAsync = ref.watch(usageProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: const ApexAppBar(title: 'System Health'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            healthAsync.when(
              data: (health) => _HealthStatusCard(health: health),
              loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text('Error: $e', style: ApexTypography.body.copyWith(color: ApexColors.error)),
            ),
            const SizedBox(height: 16),
            Text('System Metrics', style: ApexTypography.cardTitle),
            const SizedBox(height: 8),
            metricsAsync.when(
              data: (metrics) => _MetricsGrid(metrics: metrics),
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text('Error: $e', style: ApexTypography.body.copyWith(color: ApexColors.error)),
            ),
            const SizedBox(height: 16),
            Text('Resource Usage', style: ApexTypography.cardTitle),
            const SizedBox(height: 8),
            usageAsync.when(
              data: (usage) => _UsageCard(usage: usage),
              loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text('Error: $e', style: ApexTypography.body.copyWith(color: ApexColors.error)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthStatusCard extends StatelessWidget {
  final Map<String, dynamic> health;
  const _HealthStatusCard({required this.health});

  @override
  Widget build(BuildContext context) {
    final status = health['status'] ?? 'unknown';
    final dbStatus = health['database'] ?? 'unknown';
    final isHealthy = status == 'healthy';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isHealthy ? ApexColors.success : ApexColors.error),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isHealthy ? ApexColors.success : ApexColors.error).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isHealthy ? Icons.check_circle : Icons.error,
              size: 28,
              color: isHealthy ? ApexColors.success : ApexColors.error,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHealthy ? 'System Healthy' : 'System Degraded',
                  style: ApexTypography.headingLarge.copyWith(color: isHealthy ? ApexColors.success : ApexColors.error),
                ),
                const SizedBox(height: 4),
                Text('Database: $dbStatus', style: ApexTypography.caption.copyWith(color: ApexColors.neutral500)),
                Text('Last check: ${health['timestamp'] ?? '—'}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: ApexColors.neutral500),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final Map<String, dynamic> metrics;
  const _MetricsGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final employees = metrics['employees'] ?? {};
    final attendance = metrics['attendance'] ?? {};
    final leaves = metrics['leaves'] ?? {};
    final notifications = metrics['notifications'] ?? {};

    final cards = [
      _MetricCard(title: 'Total Employees', value: '${employees['total'] ?? 0}', icon: Icons.people, color: ApexColors.primary600),
      _MetricCard(title: 'Active Employees', value: '${employees['active'] ?? 0}', icon: Icons.person, color: ApexColors.success),
      _MetricCard(title: 'Today Attendance', value: '${attendance['today'] ?? 0}', icon: Icons.fingerprint, color: ApexColors.primary600),
      _MetricCard(title: 'Pending Leaves', value: '${leaves['pending'] ?? 0}', icon: Icons.event_busy, color: ApexColors.warning),
      _MetricCard(title: 'Unread Notifications', value: '${notifications['unread'] ?? 0}', icon: Icons.notifications, color: ApexColors.primary600),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards.map((c) => SizedBox(
        width: (MediaQuery.of(context).size.width - 56) / 3,
        child: c,
      )).toList(),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: ApexColors.neutral200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: color),
            const Spacer(),
            Text(value, style: ApexTypography.headingLarge.copyWith(fontSize: 20, color: color)),
          ]),
          const SizedBox(height: 6),
          Text(title, style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
        ],
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  final Map<String, dynamic> usage;
  const _UsageCard({required this.usage});

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _usageRow('Employees', usage['employees'] ?? 0, 50),
          const SizedBox(height: 12),
          _usageRow('Users', usage['users'] ?? 0, 10),
        ],
      ),
    );
  }

  Widget _usageRow(String label, int current, int max) {
    final pct = max > 0 ? (current / max * 100).round() : 0;
    final isWarning = pct >= 80;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label, style: ApexTypography.body),
          const Spacer(),
          Text('$current / $max', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600, color: isWarning ? ApexColors.warning : ApexColors.neutral900)),
        ]),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: pct / 100,
          backgroundColor: ApexColors.neutral200,
          color: isWarning ? ApexColors.warning : ApexColors.primary,
          minHeight: 6,
        ),
      ],
    );
  }
}
