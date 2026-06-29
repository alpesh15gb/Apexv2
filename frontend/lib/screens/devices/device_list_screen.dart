import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/device_provider.dart';
import '../../providers/essl_provider.dart';
import '../../services/essl_service.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_button.dart';

class DeviceListScreen extends ConsumerWidget {
  const DeviceListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(deviceListProvider);
    final healthAsync = ref.watch(deviceHealthProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Device List',
        description: 'Biometric terminals status, network pings, and sync logs control.',
        onRefresh: () {
          ref.invalidate(deviceListProvider);
          ref.invalidate(deviceHealthProvider);
        },
        actions: [
          ApexButton(
            label: 'Add Device',
            onPressed: () => context.push('/devices/add'),
            type: ApexButtonType.primary,
            icon: Icons.add,
          ),
        ],
        body: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Health KPIs
              healthAsync.when(
                data: (health) => _buildHealthKpis(health, isMobile, context),
                loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 24),
              // Device grid
              Text('CONNECTED TERMINALS', style: ApexTypography.sectionHeader),
              const SizedBox(height: 12),
              devicesAsync.when(
                data: (devices) {
                  if (devices.isEmpty) {
                    return const _EmptyDeviceState();
                  }
                  return _DeviceGrid(devices: devices, isMobile: isMobile);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 40, color: ApexColors.error),
                      const SizedBox(height: 12),
                      Text('Error: ${e.toString()}', style: ApexTypography.bodySmall),
                      const SizedBox(height: 12),
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
      ),
    );
  }

  Widget _buildHealthKpis(dynamic health, bool isMobile, BuildContext context) {
    final total = health.totalDevices;
    final onlinePct = total > 0 ? (health.online / total * 100).round() : 0;

    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: [
        _KpiCard(label: 'Total Devices', value: '$total', color: ApexColors.neutral500),
        _KpiCard(label: 'Online', value: '${health.online}', color: ApexColors.success, subtitle: '$onlinePct% active'),
        _KpiCard(label: 'Offline', value: '${health.offline}', color: health.offline > 0 ? ApexColors.error : ApexColors.success),
        _KpiCard(label: 'Inactive', value: '${health.inactive}', color: ApexColors.warning),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String? subtitle;

  const _KpiCard({required this.label, required this.value, required this.color, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(width: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: ApexTypography.cardTitle.copyWith(fontWeight: FontWeight.w700, color: ApexColors.neutral900)),
                Text(label, style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                if (subtitle != null)
                  Text(subtitle!, style: ApexTypography.captionSmall.copyWith(color: color, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceGrid extends StatelessWidget {
  final List<dynamic> devices;
  final bool isMobile;

  const _DeviceGrid({required this.devices, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.2,
      ),
      itemCount: devices.length,
      itemBuilder: (context, i) => _DeviceCard(device: devices[i]),
    );
  }
}

class _EmptyDeviceState extends ConsumerStatefulWidget {
  const _EmptyDeviceState();

  @override
  ConsumerState<_EmptyDeviceState> createState() => _EmptyDeviceStateState();
}

class _EmptyDeviceStateState extends ConsumerState<_EmptyDeviceState> {
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(esslServerListProvider.notifier).fetchServers();
    });
  }

  Future<void> _syncAllServers() async {
    setState(() => _syncing = true);
    try {
      final serversAsync = ref.read(esslServerListProvider);
      final servers = serversAsync.valueOrNull ?? [];
      final esslService = ref.read(esslServiceProvider);

      if (servers.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No eSSL servers configured. Add one in Settings > eSSL Servers.')),
          );
        }
        return;
      }

      for (final server in servers) {
        await esslService.syncDevices(server.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync triggered for ${servers.length} server(s). Refreshing...')),
        );
        ref.invalidate(deviceListProvider);
        ref.invalidate(deviceHealthProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sync_disabled, size: 48, color: ApexColors.neutral400),
          const SizedBox(height: 16),
          Text('No Devices Found', style: ApexTypography.cardTitle),
          const SizedBox(height: 8),
          Text(
            'Devices are synced from your eSSL biometric servers.\nTrigger a sync to pull device data.',
            style: ApexTypography.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ApexButton(
                label: _syncing ? 'Syncing...' : 'Sync from eSSL',
                onPressed: _syncing ? null : _syncAllServers,
                type: ApexButtonType.primary,
                icon: Icons.sync,
              ),
              const SizedBox(width: 12),
              ApexButton(
                label: 'Add Manually',
                onPressed: () => context.push('/devices/add'),
                type: ApexButtonType.secondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.push('/settings/essl'),
            child: Text(
              'Manage eSSL Servers',
              style: ApexTypography.caption.copyWith(color: ApexColors.primary500),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final dynamic device;
  const _DeviceCard({required this.device});

  @override
  Widget build(BuildContext context) {
    final isOnline = device.status == 'online';
    final color = isOnline ? ApexColors.success : ApexColors.error;

    return ApexCard(
      onTap: () => context.push('/devices/${device.id}'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.biotech, color: color, size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(device.status.toUpperCase(), style: ApexTypography.captionSmall.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(device.deviceName, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900), overflow: TextOverflow.ellipsis),
          Text('S/N: ${device.serialNumber}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500), overflow: TextOverflow.ellipsis),
          if (device.location != null)
            Text(device.location!, style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500), overflow: TextOverflow.ellipsis),
          if (device.lastSync != null)
            Text(
              'Synced: ${DateFormat('MMM d, h:mm a').format(device.lastSync!)}',
              style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral400, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
