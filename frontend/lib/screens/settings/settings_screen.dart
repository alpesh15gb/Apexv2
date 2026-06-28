import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        title: const Text('Administration'),
        backgroundColor: Colors.white,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: ApexColors.neutral200)),
      ),
      body: user == null
          ? Center(child: Text('Not logged in', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileCard(user: user),
                  const SizedBox(height: 20),
                  Text('SYSTEM', style: ApexTypography.sectionHeader),
                  const SizedBox(height: 8),
                  _SettingsGroup(items: [
                    _SettingsItem(icon: Icons.biotech, label: 'Devices', subtitle: 'Manage biometric devices', onTap: () => context.push('/devices')),
                    _SettingsItem(icon: Icons.dns, label: 'eSSL Servers', subtitle: 'Configure eBioserverNew', onTap: () => context.push('/settings/essl')),
                    _SettingsItem(icon: Icons.sync, label: 'Sync Dashboard', subtitle: 'Monitor sync health', onTap: () => context.push('/settings/essl/dashboard')),
                    _SettingsItem(icon: Icons.terminal, label: 'Command Center', subtitle: 'Device commands', onTap: () => context.push('/commands')),
                  ]),
                  const SizedBox(height: 20),
                  Text('ORGANIZATION', style: ApexTypography.sectionHeader),
                  const SizedBox(height: 8),
                  _SettingsGroup(items: [
                    _SettingsItem(icon: Icons.business, label: 'Departments', subtitle: 'Manage departments', onTap: () => context.push('/departments')),
                    _SettingsItem(icon: Icons.work_outline, label: 'Designations', subtitle: 'Job roles', onTap: () => context.push('/designations')),
                    _SettingsItem(icon: Icons.store, label: 'Branches', subtitle: 'Manage branches', onTap: () => context.push('/branches')),
                    _SettingsItem(icon: Icons.schedule, label: 'Shifts', subtitle: 'Work schedules', onTap: () => context.push('/shifts')),
                    _SettingsItem(icon: Icons.group_work, label: 'Shift Groups', subtitle: 'Bundle shifts into groups', onTap: () => context.push('/shift-groups')),
                    _SettingsItem(icon: Icons.calendar_month, label: 'Shift Rosters', subtitle: 'Rotation patterns', onTap: () => context.push('/shift-rosters')),
                    _SettingsItem(icon: Icons.swap_horiz, label: 'Department Shifts', subtitle: 'Assign shifts to departments', onTap: () => context.push('/department-shifts')),
                  ]),
                  const SizedBox(height: 20),
                  Text('ATTENDANCE', style: ApexTypography.sectionHeader),
                  const SizedBox(height: 8),
                  _SettingsGroup(items: [
                    _SettingsItem(icon: Icons.category, label: 'Categories', subtitle: 'Attendance rules & OT formulas', onTap: () => context.push('/settings/categories')),
                    _SettingsItem(icon: Icons.tune, label: 'Attendance Settings', subtitle: 'Master attendance configuration', onTap: () => context.push('/settings/tenant-settings')),
                    _SettingsItem(icon: Icons.work_outline, label: 'Work Codes', subtitle: 'Project/task codes', onTap: () => context.push('/settings/work-codes')),
                  ]),
                  const SizedBox(height: 20),
                  Text('HR', style: ApexTypography.sectionHeader),
                  const SizedBox(height: 8),
                  _SettingsGroup(items: [
                    _SettingsItem(icon: Icons.description, label: 'Documents', subtitle: 'Employee document storage', onTap: () => context.push('/documents')),
                    _SettingsItem(icon: Icons.exit_to_app, label: 'Exit Requests', subtitle: 'Employee exit workflow', onTap: () => context.push('/exit-requests')),
                    _SettingsItem(icon: Icons.inventory_2, label: 'Company Assets', subtitle: 'Track company assets', onTap: () => context.push('/assets')),
                    _SettingsItem(icon: Icons.flight, label: 'Travel Requests', subtitle: 'Travel management', onTap: () => context.push('/travel')),
                    _SettingsItem(icon: Icons.campaign, label: 'Announcements', subtitle: 'Company announcements', onTap: () => context.push('/announcements')),
                  ]),
                  const SizedBox(height: 20),
                  Text('FINANCE', style: ApexTypography.sectionHeader),
                  const SizedBox(height: 8),
                  _SettingsGroup(items: [
                    _SettingsItem(icon: Icons.receipt_long, label: 'Expense Claims', subtitle: 'Employee expense management', onTap: () => context.push('/expenses')),
                  ]),
                  const SizedBox(height: 20),
                  Text('SECURITY', style: ApexTypography.sectionHeader),
                  const SizedBox(height: 8),
                  _SettingsGroup(items: [
                    _SettingsItem(icon: Icons.lock, label: 'Access Control', subtitle: 'Zones, doors, grants', onTap: () => context.push('/access/zones')),
                    _SettingsItem(icon: Icons.lock_open, label: 'Access Doors', subtitle: 'Door management', onTap: () => context.push('/access/doors')),
                    _SettingsItem(icon: Icons.history, label: 'Access Logs', subtitle: 'Access history', onTap: () => context.push('/access/logs')),
                  ]),
                  const SizedBox(height: 20),
                  ApexButton(
                    label: 'Log Out',
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                    type: ApexButtonType.danger,
                    icon: Icons.logout,
                    expanded: true,
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final dynamic user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: ApexColors.primary.withValues(alpha: 0.1),
            child: Text(user.fullName[0].toUpperCase(), style: ApexTypography.titleLarge.copyWith(color: ApexColors.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName, style: ApexTypography.titleMedium.copyWith(color: ApexColors.neutral900)),
                Text(user.email, style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500)),
              ],
            ),
          ),
          ApexBadge.info('ADMIN'),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsItem> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ApexColors.neutral200),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Icon(item.icon, size: 20, color: ApexColors.primary),
                title: Text(item.label, style: ApexTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(item.subtitle, style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
                trailing: Icon(Icons.chevron_right, size: 18, color: ApexColors.neutral500),
                onTap: item.onTap,
                dense: true,
              ),
              if (i < items.length - 1) Divider(height: 1, color: ApexColors.neutral200),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsItem({required this.icon, required this.label, required this.subtitle, required this.onTap});
}
