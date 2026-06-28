import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../core/secure_storage.dart';
import '../../core/constants.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';

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
      backgroundColor: ApexColors.darkBackground,
      appBar: AppBar(
        backgroundColor: ApexColors.darkSurface,
        foregroundColor: ApexColors.darkOnSurface,
        elevation: 0,
        title: Text('Super Admin Dashboard', style: ApexTypography.titleLarge.copyWith(color: ApexColors.darkOnSurface)),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/admin/tenants'),
            icon: const Icon(Icons.business, size: 16),
            label: const Text('Tenants'),
            style: TextButton.styleFrom(foregroundColor: ApexColors.darkOnSurface),
          ),
          TextButton.icon(
            onPressed: () => context.go('/admin/plans'),
            icon: const Icon(Icons.payment, size: 16),
            label: const Text('Plans'),
            style: TextButton.styleFrom(foregroundColor: ApexColors.darkOnSurface),
          ),
          TextButton.icon(
            onPressed: () => context.go('/admin/features'),
            icon: const Icon(Icons.tune, size: 16),
            label: const Text('Features'),
            style: TextButton.styleFrom(foregroundColor: ApexColors.darkOnSurface),
          ),
          TextButton.icon(
            onPressed: () => context.go('/admin/analytics'),
            icon: const Icon(Icons.analytics, size: 16),
            label: const Text('Analytics'),
            style: TextButton.styleFrom(foregroundColor: ApexColors.darkOnSurface),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: ApexColors.darkSurfaceVariant)),
            ),
            padding: const EdgeInsets.only(left: 8),
            child: TextButton.icon(
              onPressed: () async {
                await secureStorage.delete(StorageKeys.accessToken);
                await secureStorage.delete(StorageKeys.refreshToken);
                await secureStorage.delete('is_admin');
                if (context.mounted) context.go('/admin/login');
              },
              icon: Icon(Icons.logout, size: 16, color: ApexColors.error),
              label: Text('Sign Out', style: ApexTypography.body.copyWith(color: ApexColors.error)),
            ),
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
              Text('Platform Overview', style: ApexTypography.sectionTitle.copyWith(color: ApexColors.darkOnSurface)),
              const SizedBox(height: 20),
              _StatsGrid(stats: stats),
              const SizedBox(height: 32),
              _QuickActions(),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: ApexColors.primary500)),
        error: (e, _) => Center(child: Text('Error: $e', style: ApexTypography.body.copyWith(color: ApexColors.error))),
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
        _StatCard(title: 'Total Tenants', value: '${stats['total_tenants'] ?? 0}', icon: Icons.business, color: ApexColors.primary500),
        _StatCard(title: 'Active Tenants', value: '${stats['active_tenants'] ?? 0}', icon: Icons.check_circle, color: ApexColors.success),
        _StatCard(title: 'Trial Tenants', value: '${stats['trial_tenants'] ?? 0}', icon: Icons.access_time, color: ApexColors.warning),
        _StatCard(title: 'Suspended', value: '${stats['suspended_tenants'] ?? 0}', icon: Icons.block, color: ApexColors.error),
        _StatCard(title: 'Total Employees', value: '${stats['total_employees'] ?? 0}', icon: Icons.people, color: ApexColors.primary500),
        _StatCard(title: 'Total Users', value: '${stats['total_users'] ?? 0}', icon: Icons.person, color: ApexColors.success),
        _StatCard(title: 'Active Users', value: '${stats['active_users'] ?? 0}', icon: Icons.verified_user, color: ApexColors.warning),
        _StatCard(title: 'Expired Subs', value: '${stats['expired_subscriptions'] ?? 0}', icon: Icons.warning, color: ApexColors.error),
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
        color: ApexColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ApexColors.darkSurfaceVariant),
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
              Text(value, style: ApexTypography.kpiValue.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: ApexTypography.caption.copyWith(color: ApexColors.darkOnSurfaceVariant)),
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
        Text('Quick Actions', style: ApexTypography.sectionTitle.copyWith(color: ApexColors.darkOnSurface)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ActionChip(icon: Icons.add_business, label: 'Add Tenant', onTap: () => context.go('/admin/tenants')),
            _ActionChip(icon: Icons.payment, label: 'Manage Plans', onTap: () => context.go('/admin/plans')),
            _ActionChip(icon: Icons.tune, label: 'Feature Flags', onTap: () => context.go('/admin/features')),
            _ActionChip(icon: Icons.analytics, label: 'Analytics', onTap: () => context.go('/admin/analytics')),
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
          color: ApexColors.darkSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ApexColors.darkSurfaceVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: ApexColors.primary500),
            const SizedBox(width: 8),
            Text(label, style: ApexTypography.body.copyWith(color: ApexColors.darkOnSurface, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

