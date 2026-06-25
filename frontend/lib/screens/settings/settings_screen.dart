import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../design_system/typography.dart';
import '../../providers/auth_provider.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Administration'),
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _border)),
      ),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User profile card
                  _ProfileCard(user: user),
                  const SizedBox(height: 20),
                  // System section
                  Text('SYSTEM', style: ApexTypography.sectionHeader),
                  const SizedBox(height: 8),
                  _SettingsGroup(items: [
                    _SettingsItem(icon: Icons.biotech, label: 'Devices', subtitle: 'Manage biometric devices', onTap: () => context.push('/devices')),
                    _SettingsItem(icon: Icons.dns, label: 'eSSL Servers', subtitle: 'Configure eBioserverNew', onTap: () => context.push('/settings/essl')),
                    _SettingsItem(icon: Icons.sync, label: 'Sync Dashboard', subtitle: 'Monitor sync health', onTap: () => context.push('/settings/essl/dashboard')),
                    _SettingsItem(icon: Icons.terminal, label: 'Command Center', subtitle: 'Device commands', onTap: () => context.push('/commands')),
                  ]),
                  const SizedBox(height: 20),
                  // Organization section
                  Text('ORGANIZATION', style: ApexTypography.sectionHeader),
                  const SizedBox(height: 8),
                  _SettingsGroup(items: [
                    _SettingsItem(icon: Icons.business, label: 'Departments', subtitle: 'Manage departments', onTap: () => context.push('/departments')),
                    _SettingsItem(icon: Icons.store, label: 'Branches', subtitle: 'Manage branches', onTap: () => context.push('/branches')),
                    _SettingsItem(icon: Icons.schedule, label: 'Shifts', subtitle: 'Work schedules', onTap: () => context.push('/shifts')),
                  ]),
                  const SizedBox(height: 20),
                  // Security section
                  Text('SECURITY', style: ApexTypography.sectionHeader),
                  const SizedBox(height: 8),
                  _SettingsGroup(items: [
                    _SettingsItem(icon: Icons.lock, label: 'Access Control', subtitle: 'Zones, doors, grants', onTap: () => context.push('/access/zones')),
                    _SettingsItem(icon: Icons.lock_open, label: 'Access Doors', subtitle: 'Door management', onTap: () => context.push('/access/doors')),
                    _SettingsItem(icon: Icons.history, label: 'Access Logs', subtitle: 'Access history', onTap: () => context.push('/access/logs'),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                      icon: const Icon(Icons.logout, size: 18, color: _danger),
                      label: const Text('Log Out', style: TextStyle(color: _danger)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _danger),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _primary.withOpacity(0.1),
            child: Text(user.fullName[0].toUpperCase(), style: ApexTypography.titleLarge.copyWith(color: _primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName, style: ApexTypography.titleMedium.copyWith(color: _text)),
                Text(user.email, style: ApexTypography.bodySmall.copyWith(color: _muted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('ADMIN', style: ApexTypography.captionSmall.copyWith(color: _primary, fontWeight: FontWeight.w600)),
          ),
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
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Icon(item.icon, size: 20, color: _primary),
                title: Text(item.label, style: ApexTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(item.subtitle, style: ApexTypography.captionMedium.copyWith(color: _muted)),
                trailing: const Icon(Icons.chevron_right, size: 18, color: _muted),
                onTap: item.onTap,
                dense: true,
              ),
              if (i < items.length - 1) const Divider(height: 1, color: _border),
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
