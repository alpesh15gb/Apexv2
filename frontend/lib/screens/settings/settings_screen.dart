import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & More'),
      ),
      body: user == null
          ? const Center(child: Text('Not logged in.'))
          : ListView(
              children: [
                // User Profile Header
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(color: theme.colorScheme.primary),
                  accountName: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  accountEmail: Text(user.email),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                    child: user.avatarUrl == null ? Text(user.fullName[0].toUpperCase(), style: const TextStyle(fontSize: 24)) : null,
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Device Terminals'),
                  subtitle: const Text('Manage hardware attendance devices'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/devices'),
                ),
                ListTile(
                  leading: const Icon(Icons.dns_outlined),
                  title: const Text('eSSL Servers'),
                  subtitle: const Text('Configure eBioserverNew connections'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/essl'),
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard_outlined),
                  title: const Text('eSSL Sync Dashboard'),
                  subtitle: const Text('Monitor sync status and health'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/essl/dashboard'),
                ),
                ListTile(
                  leading: const Icon(Icons.lock_person_outlined),
                  title: const Text('Access Control Zones'),
                  subtitle: const Text('Configure zones, security doors, grants'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/access/zones'),
                ),
                ListTile(
                  leading: const Icon(Icons.door_sliding_outlined),
                  title: const Text('Access Doors'),
                  subtitle: const Text('Remote lock control & logs'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/access/doors'),
                ),
                ListTile(
                  leading: const Icon(Icons.work_history_outlined),
                  title: const Text('Work Shifts'),
                  subtitle: const Text('Configure office working hours'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/shifts'),
                ),
                ListTile(
                  leading: const Icon(Icons.work_off_outlined),
                  title: const Text('Leave Requests'),
                  subtitle: const Text('My balances & approvals review'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/leaves/requests'),
                ),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Visitor Management'),
                  subtitle: const Text('Passes, check-in, active logs'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/visitors'),
                ),
                ListTile(
                  leading: const Icon(Icons.terminal_outlined),
                  title: const Text('Command Center'),
                  subtitle: const Text('Hardware sync queue'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/commands'),
                ),
                ListTile(
                  leading: const Icon(Icons.assessment_outlined),
                  title: const Text('System Reports'),
                  subtitle: const Text('Daily/monthly attendance sheets'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/reports'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ],
            ),
    );
  }
}
