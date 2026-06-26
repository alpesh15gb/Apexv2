import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';

const _bg = Color(0xFF0F172A);
const _surface = Color(0xFF1E293B);
const _border = Color(0xFF334155);
const _primary = Color(0xFF3B82F6);
const _success = Color(0xFF22C55E);
const _warning = Color(0xFFF59E0B);
const _danger = Color(0xFFEF4444);
const _text = Color(0xFFF1F5F9);
const _muted = Color(0xFF94A3B8);

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/admin/dashboard/stats');
  return Map<String, dynamic>.from(res.data);
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        title: const Text('Super Admin Dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/admin/tenants'),
            icon: const Icon(Icons.business, size: 16),
            label: const Text('Tenants'),
            style: TextButton.styleFrom(foregroundColor: _text),
          ),
          TextButton.icon(
            onPressed: () => context.go('/admin/plans'),
            icon: const Icon(Icons.payment, size: 16),
            label: const Text('Plans'),
            style: TextButton.styleFrom(foregroundColor: _text),
          ),
          TextButton.icon(
            onPressed: () => context.go('/admin/features'),
            icon: const Icon(Icons.tune, size: 16),
            label: const Text('Features'),
            style: TextButton.styleFrom(foregroundColor: _text),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Platform Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _text)),
              const SizedBox(height: 20),
              _StatsGrid(stats: stats),
              const SizedBox(height: 32),
              _QuickActions(),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: _primary)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: _danger))),
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
        _StatCard(title: 'Total Tenants', value: '${stats['total_tenants'] ?? 0}', icon: Icons.business, color: _primary),
        _StatCard(title: 'Active Tenants', value: '${stats['active_tenants'] ?? 0}', icon: Icons.check_circle, color: _success),
        _StatCard(title: 'Trial Tenants', value: '${stats['trial_tenants'] ?? 0}', icon: Icons.access_time, color: _warning),
        _StatCard(title: 'Suspended', value: '${stats['suspended_tenants'] ?? 0}', icon: Icons.block, color: _danger),
        _StatCard(title: 'Total Employees', value: '${stats['total_employees'] ?? 0}', icon: Icons.people, color: _primary),
        _StatCard(title: 'Total Users', value: '${stats['total_users'] ?? 0}', icon: Icons.person, color: _success),
        _StatCard(title: 'Active Users', value: '${stats['active_users'] ?? 0}', icon: Icons.verified_user, color: _warning),
        _StatCard(title: 'Expired Subs', value: '${stats['expired_subscriptions'] ?? 0}', icon: Icons.warning, color: _danger),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _text)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ActionChip(icon: Icons.add_business, label: 'Add Tenant', onTap: () => context.go('/admin/tenants')),
            _ActionChip(icon: Icons.payment, label: 'Manage Plans', onTap: () => context.go('/admin/plans')),
            _ActionChip(icon: Icons.tune, label: 'Feature Flags', onTap: () => context.go('/admin/features')),
          ],
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: _text, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
