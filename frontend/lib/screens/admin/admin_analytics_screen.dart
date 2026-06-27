import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../core/responsive.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _warning = Color(0xFFF59E0B);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

final customerSuccessProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/admin/analytics/customer-success');
    return Map<String, dynamic>.from(res.data);
  } catch (e) {
    return {};
  }
});

final analyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/admin/analytics/overview');
    return Map<String, dynamic>.from(res.data);
  } catch (e) {
    return {};
  }
});

final subscriptionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/admin/billing/subscriptions');
    return res.data is List ? res.data : [];
  } catch (e) {
    return [];
  }
});

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final csAsync = ref.watch(customerSuccessProvider);
    final analyticsAsync = ref.watch(analyticsProvider);
    final subsAsync = ref.watch(subscriptionsProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        title: const Text('Platform Analytics', style: TextStyle(fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/admin/dashboard')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Customer Success', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
            const SizedBox(height: 8),
            csAsync.when(
              data: (cs) => _StatsRow(
                stats: [
                  _StatData('Active Customers', '${cs['active_customers'] ?? 0}', Icons.check_circle, _success),
                  _StatData('Trial Customers', '${cs['trial_customers'] ?? 0}', Icons.access_time, _warning),
                  _StatData('Expiring Soon', '${cs['expiring_soon'] ?? 0}', Icons.warning, _danger),
                  _StatData('Churn Risk', '${cs['churn_risk'] ?? 0}', Icons.trending_down, _danger),
                  _StatData('Total Employees', '${cs['total_employees'] ?? 0}', Icons.people, _primary),
                  _StatData('Total Users', '${cs['total_users'] ?? 0}', Icons.person, _primary),
                ],
                isMobile: isMobile,
              ),
              loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),
            const Text('Platform Growth', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
            const SizedBox(height: 8),
            analyticsAsync.when(
              data: (analytics) {
                final tenants = analytics['tenants'] ?? {};
                final employees = analytics['employees'] ?? {};
                final users = analytics['users'] ?? {};
                return _StatsRow(
                  stats: [
                    _StatData('Total Tenants', '${tenants['total'] ?? 0}', Icons.business, _primary),
                    _StatData('New (30d)', '${tenants['new_30d'] ?? 0}', Icons.add_business, _success),
                    _StatData('Total Employees', '${employees['total'] ?? 0}', Icons.people, _primary),
                    _StatData('New (30d)', '${employees['new_30d'] ?? 0}', Icons.person_add, _success),
                    _StatData('Active Users (30d)', '${users['active_30d'] ?? 0}', Icons.verified_user, _warning),
                  ],
                  isMobile: isMobile,
                );
              },
              loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),
            const Text('Active Subscriptions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
            const SizedBox(height: 8),
            subsAsync.when(
              data: (subs) {
                if (subs.isEmpty) return const Text('No active subscriptions', style: TextStyle(color: _muted));
                return Column(
                  children: subs.map((s) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s['tenant_name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
                        Text('${s['plan_name'] ?? ''} • ${s['billing_cycle'] ?? ''}', style: const TextStyle(fontSize: 12, color: _muted)),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(s['status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text((s['status'] ?? '').toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(s['status']))),
                      ),
                    ]),
                  )).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'active': return _success;
      case 'trial': return _warning;
      case 'suspended': return _danger;
      case 'expired': return _danger;
      default: return _muted;
    }
  }
}

class _StatsRow extends StatelessWidget {
  final List<_StatData> stats;
  final bool isMobile;

  const _StatsRow({required this.stats, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: stats.map((s) => SizedBox(
        width: isMobile ? double.infinity : (MediaQuery.of(context).size.width - 80) / stats.length,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: s.color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Icon(s.icon, size: 14, color: s.color),
                ),
                const Spacer(),
                Text(s.value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: s.color)),
              ]),
              const SizedBox(height: 6),
              Text(s.label, style: const TextStyle(fontSize: 11, color: _muted)),
            ],
          ),
        ),
      )).toList(),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _StatData(this.label, this.value, this.icon, this.color);
}
