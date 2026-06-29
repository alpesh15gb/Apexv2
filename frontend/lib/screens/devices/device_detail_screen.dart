import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../models/device.dart';
import '../../providers/device_provider.dart';
import '../../services/device_service.dart';
import '../../core/dio_client.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/page_wrapper.dart';

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
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Device Details',
        description: 'Verify connected hardware statistics, sync events, and trigger commands.',
        onRefresh: () {
          ref.invalidate(deviceDetailProvider(deviceId));
          ref.invalidate(deviceLogsProvider(deviceId));
        },
        body: detailAsync.when(
          data: (device) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
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
                                  style: ApexTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text('S/N: ${device.serialNumber}', style: TextStyle(color: ApexColors.neutral500, fontSize: 12)),
                              ],
                            ),
                          ),
                          _StatusBadge(status: device.status),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildDetailRow('IP Address', device.ipAddress ?? 'N/A'),
                      _buildDetailRow('Port', '${device.port ?? 'N/A'}'),
                      _buildDetailRow('Location', device.location ?? 'N/A'),
                      _buildDetailRow('Model', device.model ?? 'N/A'),
                      _buildDetailRow('Firmware', device.firmwareVersion ?? 'N/A'),
                      _buildDetailRow('Last Sync', device.lastSync != null ? DateFormat('MMM dd, hh:mm a').format(device.lastSync!) : 'Never'),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Reboot Device'),
                                  content: Text('Are you sure you want to reboot device "${device.deviceName}"? This will interrupt attendance log collection temporarily.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reboot', style: TextStyle(color: ApexColors.error))),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                try {
                                  await ref.read(dioProvider).post('/commands/', data: {
                                    'device_id': device.id,
                                    'command_type': 'reboot',
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reboot command successfully queued'), backgroundColor: ApexColors.success));
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: ApexColors.error));
                                }
                              }
                            },
                            icon: const Icon(Icons.power_settings_new, size: 16),
                            label: const Text('Reboot Terminal'),
                            style: OutlinedButton.styleFrom(foregroundColor: ApexColors.error),
                          ),
                          const SizedBox(width: 12),
                          ApexButton(
                            label: 'Sync Now',
                            icon: Icons.sync,
                            type: ApexButtonType.primary,
                            onPressed: () async {
                              try {
                                await ref.read(deviceListProvider.notifier).syncDevice(device.id);
                                ref.invalidate(deviceDetailProvider(deviceId));
                                ref.invalidate(deviceLogsProvider(deviceId));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device sync triggered successfully'), backgroundColor: ApexColors.success));
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync failed: $e'), backgroundColor: ApexColors.error));
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Device Activity Logs', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                logsAsync.when(
                  data: (data) {
                    final list = data['items'] as List;
                    if (list.isEmpty) {
                      return Container(
                        height: 100,
                        decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
                        child: const Center(child: Text('No activity logs found.')),
                      );
                    }
                    return Container(
                      decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: list.length,
                        separatorBuilder: (context, idx) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final logMap = list[idx] as Map<String, dynamic>;
                          final time = DateTime.parse(logMap['created_at']);
                          return ListTile(
                            title: Text(logMap['message'] ?? logMap['log_type'] ?? 'Log Event', style: ApexTypography.body),
                            subtitle: Text(DateFormat('MMM dd, hh:mm a').format(time), style: ApexTypography.captionSmall),
                            leading: const Icon(Icons.list_alt_outlined),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Failed to load logs: ${err.toString()}')),
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: ApexColors.neutral400)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'online': return ApexBadge.success('ONLINE');
      case 'offline': return ApexBadge.danger('OFFLINE');
      default: return ApexBadge.neutral(status.toUpperCase());
    }
  }
}
