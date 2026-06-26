import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/responsive.dart';
import '../../design_system/typography.dart';
import '../../providers/essl_provider.dart';
import '../../services/essl_service.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _danger = Color(0xFFDC2626);
const _warning = Color(0xFFF59E0B);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

class EsslServerListScreen extends ConsumerWidget {
  const EsslServerListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serversAsync = ref.watch(esslServerListProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('eSSL Servers'),
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _border)),
        actions: [
          IconButton(icon: const Icon(Icons.add, size: 18), tooltip: 'Add Server', onPressed: () => context.push('/settings/essl/create')),
        ],
      ),
      body: serversAsync.when(
        data: (servers) {
          if (servers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.dns, size: 48, color: _muted),
                  const SizedBox(height: 16),
                  Text('No eSSL Servers', style: ApexTypography.headingMedium.copyWith(color: _text)),
                  const SizedBox(height: 8),
                  Text('Connect to your eBioserverNew to start syncing', style: ApexTypography.body.copyWith(color: _muted)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/settings/essl/create'),
                    style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
                    child: const Text('Add Server'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: servers.length,
            itemBuilder: (context, i) {
              final s = servers[i];
              final statusColor = s.status == 'connected' ? _success : s.status == 'error' ? _danger : _muted;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.dns, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: ApexTypography.titleSmall.copyWith(color: _text)),
                          Text(s.serverUrl, style: ApexTypography.caption.copyWith(color: _muted), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(s.status.toUpperCase(), style: ApexTypography.badge.copyWith(color: statusColor)),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'test', child: Text('Test Connection')),
                        const PopupMenuItem(value: 'locations', child: Text('Locations')),
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'sync_attendance', child: Text('Sync Attendance')),
                        const PopupMenuItem(value: 'sync_employees', child: Text('Sync Employees')),
                        const PopupMenuItem(value: 'sync_devices', child: Text('Sync Devices')),
                        const PopupMenuItem(value: 'history', child: Text('Sync History')),
                        const PopupMenuItem(value: 'dashboard', child: Text('Dashboard')),
                      ],
                      onSelected: (v) async {
                        if (v == 'edit') context.push('/settings/essl/${s.id}');
                        if (v == 'locations') context.push('/settings/essl/${s.id}/locations');
                        if (v == 'history') context.push('/settings/essl/${s.id}/history');
                        if (v == 'dashboard') context.push('/settings/essl/dashboard');
                        if (v == 'test') {
                          final service = ref.read(esslServiceProvider);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Testing connection...')));
                          try {
                            final result = await service.testConnection(s.id);
                            if (result.success) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Connected! Server: ${result.serverVersion ?? "OK"} (${result.responseTimeMs}ms)'),
                                backgroundColor: _success,
                              ));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Failed: ${result.error}'),
                                backgroundColor: _danger,
                              ));
                            }
                            ref.read(esslServerListProvider.notifier).fetchServers(isRefresh: true);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: _danger,
                            ));
                          }
                        }
                        if (v == 'sync_attendance' || v == 'sync_employees' || v == 'sync_devices') {
                          final service = ref.read(esslServiceProvider);
                          final label = v == 'sync_attendance' ? 'attendance' : v == 'sync_employees' ? 'employees' : 'devices';
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Starting $label sync...')));
                          try {
                            final result = v == 'sync_attendance'
                                ? await service.syncAttendance(s.id)
                                : v == 'sync_employees'
                                    ? await service.syncEmployees(s.id)
                                    : await service.syncDevices(s.id);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('$label sync completed: ${result.recordsFetched} fetched, ${result.recordsCreated} created'),
                              backgroundColor: _success,
                            ));
                            ref.read(esslServerListProvider.notifier).fetchServers(isRefresh: true);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Sync failed: $e'),
                              backgroundColor: _danger,
                            ));
                          }
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
