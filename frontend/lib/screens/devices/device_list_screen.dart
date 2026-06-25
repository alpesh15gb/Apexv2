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
import '../../design_system/components/apex_button.dart';
import '../../providers/device_provider.dart';

class DeviceListScreen extends ConsumerWidget {
  const DeviceListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(deviceListProvider);
    final healthAsync = ref.watch(deviceHealthProvider);
    final padding = Responsive.contentPadding(context);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Operations Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.health_and_safety_outlined),
            tooltip: 'Device Health',
            onPressed: () => context.push('/devices/health'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(deviceListProvider);
              ref.invalidate(deviceHealthProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Operations Dashboard
            healthAsync.when(
              data: (health) => _buildOperationsDashboard(context, health, isMobile),
              loading: () => const ApexLoadingSkeleton(count: 4, type: ApexSkeletonType.stat),
              error: (err, stack) => const SizedBox(),
            ),
            SizedBox(height: isMobile ? 16 : 24),

            // Device Grid
            Text('All Devices', style: ApexTypography.headingSmall),
            const SizedBox(height: 16),
            devicesAsync.when(
              data: (devices) {
                if (devices.isEmpty) {
                  return const ApexEmptyState(
                    icon: Icons.biotech_outlined,
                    title: 'No Devices Registered',
                    description: 'Biometric fingerprint or face scan devices will show up here.',
                    actionLabel: 'Register Device',
                  );
                }
                return _buildDeviceGrid(context, devices, isMobile);
              },
              loading: () => const ApexLoadingSkeleton(count: 6, type: ApexSkeletonType.card),
              error: (err, stack) => Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: ApexColors.error),
                    const SizedBox(height: 16),
                    Text('Error: ${err.toString()}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(deviceListProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsDashboard(BuildContext context, dynamic health, bool isMobile) {
    final columns = Responsive.gridColumns(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Health Summary
        GridView.count(
          crossAxisCount: isMobile ? 2 : (columns > 4 ? 4 : columns),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isMobile ? 1.3 : 1.5,
          children: [
            ApexStatCard(
              title: 'Total Devices',
              value: '${health.totalDevices}',
              icon: Icons.devices,
              color: ApexColors.neutral600,
            ),
            ApexStatCard(
              title: 'Online',
              value: '${health.online}',
              icon: Icons.check_circle_outline,
              color: ApexColors.success,
              subtitle: '${health.totalDevices > 0 ? (health.online / health.totalDevices * 100).toStringAsFixed(0) : 0}% uptime',
            ),
            ApexStatCard(
              title: 'Offline',
              value: '${health.offline}',
              icon: Icons.cloud_off_outlined,
              color: health.offline > 0 ? ApexColors.error : ApexColors.success,
            ),
            ApexStatCard(
              title: 'Inactive',
              value: '${health.inactive}',
              icon: Icons.pause_circle_outline,
              color: ApexColors.warning,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Health Bar
        ApexCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Device Health', style: ApexTypography.titleMedium),
                  Text(
                    '${health.totalDevices > 0 ? (health.online / health.totalDevices * 100).toStringAsFixed(1) : 0}%',
                    style: ApexTypography.titleLarge.copyWith(
                      color: health.online > 0 ? ApexColors.success : ApexColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: ApexRadius.xsAll,
                child: LinearProgressIndicator(
                  value: health.totalDevices > 0 ? health.online / health.totalDevices : 0,
                  backgroundColor: ApexColors.neutral100,
                  color: health.online > 0 ? ApexColors.success : ApexColors.error,
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHealthLegend('Online', ApexColors.success, health.online),
                  _buildHealthLegend('Offline', ApexColors.error, health.offline),
                  _buildHealthLegend('Inactive', ApexColors.warning, health.inactive),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthLegend(String label, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: ApexRadius.xsAll,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500),
        ),
      ],
    );
  }

  Widget _buildDeviceGrid(BuildContext context, List<dynamic> devices, bool isMobile) {
    final columns = Responsive.gridColumns(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : (columns > 3 ? 3 : columns),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isMobile ? 2.5 : 1.8,
      ),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return _buildDeviceCard(context, device);
      },
    );
  }

  Widget _buildDeviceCard(BuildContext context, dynamic device) {
    final isOnline = device.status == 'online';
    final isError = device.status == 'error';

    return InkWell(
      onTap: () => context.push('/devices/${device.id}'),
      borderRadius: ApexRadius.lgAll,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isOnline
                ? ApexColors.success.withOpacity(0.3)
                : isError
                    ? ApexColors.error.withOpacity(0.3)
                    : ApexColors.neutral200,
          ),
          borderRadius: ApexRadius.lgAll,
          color: isOnline
              ? ApexColors.successLight.withOpacity(0.3)
              : isError
                  ? ApexColors.errorLight.withOpacity(0.3)
                  : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isOnline
                        ? ApexColors.success.withOpacity(0.1)
                        : isError
                            ? ApexColors.error.withOpacity(0.1)
                            : ApexColors.neutral100,
                    borderRadius: ApexRadius.mdAll,
                  ),
                  child: Icon(
                    Icons.biotech,
                    color: isOnline
                        ? ApexColors.success
                        : isError
                            ? ApexColors.error
                            : ApexColors.neutral400,
                    size: 20,
                  ),
                ),
                ApexBadge(
                  status: device.status,
                  category: 'device',
                  dot: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              device.deviceName,
              style: ApexTypography.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'S/N: ${device.serialNumber}',
              style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500),
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                if (device.location != null) ...[
                  const Icon(Icons.location_on, size: 14, color: ApexColors.neutral400),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      device.location!,
                      style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const Spacer(),
                // Quick actions
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (value) {
                    switch (value) {
                      case 'sync':
                        // TODO: Trigger sync
                        break;
                      case 'reboot':
                        // TODO: Reboot device
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'sync', child: Text('Sync')),
                    const PopupMenuItem(value: 'reboot', child: Text('Reboot')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
