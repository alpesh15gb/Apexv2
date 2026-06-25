import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/border_radius.dart';
import '../../design_system/components/apex_stat_card.dart';
import '../../design_system/components/apex_badge.dart';
import '../../design_system/components/apex_card.dart';
import '../../design_system/components/apex_empty_state.dart';
import '../../design_system/components/apex_loading_skeleton.dart';
import '../../providers/device_provider.dart';

class DeviceListScreen extends ConsumerWidget {
  const DeviceListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(deviceListProvider);
    final healthAsync = ref.watch(deviceHealthProvider);
    final padding = Responsive.isMobile(context) ? 16.0 : 24.0;
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Operations'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, size: 20), tooltip: 'Refresh', onPressed: () {
            ref.invalidate(deviceListProvider);
            ref.invalidate(deviceHealthProvider);
          }),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Health summary
            healthAsync.when(
              data: (health) => _buildHealthSummary(context, health, isMobile),
              loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 16),

            // Device grid
            Text('ALL DEVICES', style: ApexTypography.sectionHeader),
            const SizedBox(height: 8),
            devicesAsync.when(
              data: (devices) {
                if (devices.isEmpty) {
                  return const ApexEmptyState(
                    icon: Icons.biotech_outlined,
                    title: 'No Devices',
                    description: 'Register a biometric device to get started.',
                  );
                }
                return _buildDeviceGrid(context, devices, isMobile);
              },
              loading: () => const ApexLoadingSkeleton(count: 6, type: ApexSkeletonType.card),
              error: (err, stack) => Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 40, color: ApexColors.error),
                    const SizedBox(height: 12),
                    Text('Error: ${err.toString()}', style: ApexTypography.bodySmall),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: () => ref.invalidate(deviceListProvider), child: const Text('Retry')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthSummary(BuildContext context, dynamic health, bool isMobile) {
    final total = health.totalDevices;
    final onlinePct = total > 0 ? (health.online / total * 100).round() : 0;

    return Row(
      children: [
        Expanded(child: ApexStatCard(
          title: 'Total',
          value: '$total',
          icon: Icons.devices,
          color: ApexColors.neutral600,
        )),
        const SizedBox(width: 8),
        Expanded(child: ApexStatCard(
          title: 'Online',
          value: '${health.online}',
          icon: Icons.check_circle_outline,
          color: ApexColors.success,
          subtitle: '$onlinePct% uptime',
        )),
        const SizedBox(width: 8),
        Expanded(child: ApexStatCard(
          title: 'Offline',
          value: '${health.offline}',
          icon: Icons.cloud_off_outlined,
          color: health.offline > 0 ? ApexColors.error : ApexColors.success,
        )),
        const SizedBox(width: 8),
        Expanded(child: ApexStatCard(
          title: 'Inactive',
          value: '${health.inactive}',
          icon: Icons.pause_circle_outline,
          color: ApexColors.warning,
        )),
      ],
    );
  }

  Widget _buildDeviceGrid(BuildContext context, List<dynamic> devices, bool isMobile) {
    final columns = isMobile ? 1 : (Responsive.isDesktop(context) ? 3 : 2);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.0,
      ),
      itemCount: devices.length,
      itemBuilder: (context, index) => _buildDeviceCard(context, devices[index]),
    );
  }

  Widget _buildDeviceCard(BuildContext context, dynamic device) {
    final isOnline = device.status == 'online';
    final color = isOnline ? ApexColors.success : ApexColors.error;

    return InkWell(
      onTap: () => context.push('/devices/${device.id}'),
      borderRadius: ApexRadius.mdAll,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: ApexRadius.mdAll,
          color: isOnline ? ApexColors.successLight.withOpacity(0.3) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.biotech, color: color, size: 20),
                ApexBadge(status: device.status, category: 'device', dot: true),
              ],
            ),
            const Spacer(),
            Text(device.deviceName, style: ApexTypography.titleSmall, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
              'S/N: ${device.serialNumber}',
              style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500),
              overflow: TextOverflow.ellipsis,
            ),
            if (device.location != null) ...[
              const SizedBox(height: 2),
              Text(
                device.location!,
                style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral400),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
