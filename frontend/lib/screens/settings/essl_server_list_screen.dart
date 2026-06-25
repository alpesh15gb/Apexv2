import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/essl_provider.dart';
import '../../services/essl_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';

class EsslServerListScreen extends ConsumerWidget {
  const EsslServerListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serversAsync = ref.watch(esslServerListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('eSSL Servers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/settings/essl/create'),
          ),
        ],
      ),
      body: serversAsync.when(
        data: (servers) {
          if (servers.isEmpty) {
            return const EmptyState(
              title: 'No eSSL Servers',
              description: 'Add an eSSL eBioserverNew server to start syncing attendance data.',
              icon: Icons.dns_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: servers.length,
            itemBuilder: (context, index) {
              final server = servers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _statusColor(server.status).withOpacity(0.1),
                    child: Icon(
                      _statusIcon(server.status),
                      color: _statusColor(server.status),
                    ),
                  ),
                  title: Text(server.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(server.serverUrl),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusColor(server.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              server.status.toUpperCase(),
                              style: TextStyle(
                                color: _statusColor(server.status),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (server.lastConnectedAt != null)
                            Text(
                              'Last: ${DateFormat('MMM dd, HH:mm').format(server.lastConnectedAt!)}',
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'initial_sync', child: Text('Initial Sync...')),
                      const PopupMenuItem(value: 'sync_attendance', child: Text('Sync Attendance')),
                      const PopupMenuItem(value: 'sync_employees', child: Text('Sync Employees')),
                      const PopupMenuItem(value: 'sync_devices', child: Text('Sync Devices')),
                      const PopupMenuItem(value: 'history', child: Text('Sync History')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                    onSelected: (value) async {
                      switch (value) {
                        case 'edit':
                          context.push('/settings/essl/${server.id}');
                          break;
                        case 'initial_sync':
                          context.push('/settings/essl/${server.id}/initial-sync');
                          break;
                        case 'sync_attendance':
                          await _syncAction(context, ref, server.id, 'attendance');
                          break;
                        case 'sync_employees':
                          await _syncAction(context, ref, server.id, 'employees');
                          break;
                        case 'sync_devices':
                          await _syncAction(context, ref, server.id, 'devices');
                          break;
                        case 'history':
                          context.push('/settings/essl/${server.id}/history');
                          break;
                        case 'delete':
                          await _confirmDelete(context, ref, server.id, server.name);
                          break;
                      }
                    },
                  ),
                  onTap: () => context.push('/settings/essl/${server.id}'),
                ),
              );
            },
          );
        },
        loading: () => const LoadingWidget(count: 3),
        error: (err, stack) => CustomErrorWidget(
          errorMessage: err.toString(),
          onRetry: () => ref.read(esslServerListProvider.notifier).fetchServers(isRefresh: true),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'connected':
        return Colors.green;
      case 'testing':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'connected':
        return Icons.check_circle;
      case 'testing':
        return Icons.sync;
      case 'error':
        return Icons.error;
      default:
        return Icons.cloud_off;
    }
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
        case 'attendance':
          await service.syncAttendance(serverId);
          break;
        case 'employees':
          await service.syncEmployees(serverId);
          break;
        case 'devices':
          await service.syncDevices(serverId);
          break;
      }
      if (context.mounted) {
        Navigator.pop(context);
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Server'),
        content: Text('Delete "$name"? This will remove all sync history and mappings.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(esslServerListProvider.notifier).deleteServer(id);
    }
  }
}
