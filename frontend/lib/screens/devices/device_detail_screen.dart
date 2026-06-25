import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/device.dart';
import '../../providers/device_provider.dart';
import '../../services/device_service.dart';
import '../../widgets/loading_widget.dart';
import '../../core/dio_client.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/status_badge.dart';

final deviceDetailProvider = FutureProvider.family<Device, String>((ref, id) async {
  final service = ref.read(deviceServiceProvider);
  return await service.getDevice(id);
});

final deviceLogsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final service = ref.read(deviceServiceProvider);
  return await service.getDeviceLogs(id, page: 1, pageSize: 50);
});

class DeviceDetailScreen extends ConsumerWidget {
  final String deviceId;

  const DeviceDetailScreen({Key? key, required this.deviceId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(deviceDetailProvider(deviceId));
    final logsAsync = ref.watch(deviceLogsProvider(deviceId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Details'),
      ),
      body: detailAsync.when(
        data: (device) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  device.deviceName,
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text('S/N: ${device.serialNumber}', style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                          StatusBadge(status: device.status),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildDetailRow('IP Address', device.ipAddress ?? 'N/A'),
                      _buildDetailRow('Port', '${device.port ?? 'N/A'}'),
                      _buildDetailRow('Location', device.location ?? 'N/A'),
                      _buildDetailRow('Model', device.model ?? 'N/A'),
                      _buildDetailRow('Firmware', device.firmwareVersion ?? 'N/A'),
                      _buildDetailRow('Last Sync', device.lastSync != null ? DateFormat('MMM dd, hh:mm a').format(device.lastSync!) : 'Never'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await ref.read(deviceListProvider.notifier).syncDevice(device.id);
                                ref.invalidate(deviceDetailProvider(deviceId));
                                ref.invalidate(deviceLogsProvider(deviceId));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Device sync triggered'), backgroundColor: Colors.green),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Sync failed: ${e.toString()}'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.sync),
                            label: const Text('Sync'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                final service = ref.read(deviceServiceProvider);
                                // Queue a reboot command via dio
                                await ref.read(dioProvider).post('/commands/', data: {
                                  'device_id': device.id,
                                  'command_type': 'reboot',
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Reboot command queued'), backgroundColor: Colors.green),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.power_settings_new),
                            label: const Text('Reboot'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Device Activity Logs', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              logsAsync.when(
                data: (data) {
                  final list = data['items'] as List;
                  if (list.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(child: Text('No activity logs found.')),
                      ),
                    );
                  }
                  return Card(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: list.length,
                      separatorBuilder: (context, idx) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final logMap = list[idx] as Map<String, dynamic>;
                        final time = DateTime.parse(logMap['created_at']);
                        return ListTile(
                          title: Text(logMap['message'] ?? logMap['log_type'] ?? 'Log Event'),
                          subtitle: Text(DateFormat('MMM dd, hh:mm a').format(time)),
                          leading: const Icon(Icons.list_alt_outlined),
                        );
                      },
                    ),
                  );
                },
                loading: () => const LoadingWidget(count: 3),
                error: (err, stack) => Center(child: Text('Failed to load logs: ${err.toString()}')),
              ),
            ],
          ),
        ),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) => Scaffold(
          body: CustomErrorWidget(
            errorMessage: err.toString(),
            onRetry: () => ref.invalidate(deviceDetailProvider(deviceId)),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
