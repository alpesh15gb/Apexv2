import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../design_system/typography.dart';
import '../../providers/device_provider.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _warning = Color(0xFFF59E0B);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

class DeviceListScreen extends ConsumerWidget {
  const DeviceListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(deviceListProvider);
    final healthAsync = ref.watch(deviceHealthProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text('Device Operations', style: ApexTypography.sectionTitle.copyWith(color: _text)),
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _border)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, size: 18), tooltip: 'Refresh', onPressed: () {
            ref.invalidate(deviceListProvider);
            ref.invalidate(deviceHealthProvider);
          }),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Health KPIs
            healthAsync.when(
              data: (health) => _buildHealthKpis(health, isMobile),
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
                  return _EmptyState(
                    icon: Icons.biotech,
                    title: 'No Devices',
                    description: 'Register a biometric device to get started.',
                  );
                }
                return _DeviceGrid(devices: devices, isMobile: isMobile);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 40, color: _danger),
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
    );
  }

  Widget _buildHealthKpis(dynamic health, bool isMobile) {
    final total = health.totalDevices;
    final onlinePct = total > 0 ? (health.online / total * 100).round() : 0;

    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.0,
      children: [
        _KpiCard(label: 'Total', value: '$total', color: _muted),
        _KpiCard(label: 'Online', value: '${health.online}', color: _success, subtitle: '$onlinePct% uptime'),
        _KpiCard(label: 'Offline', value: '${health.offline}', color: health.offline > 0 ? _danger : _success),
        _KpiCard(label: 'Inactive', value: '${health.inactive}', color: _warning),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(width: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: ApexTypography.headingMedium.copyWith(color: _text)),
                Text(label, style: ApexTypography.kpiLabel),
                if (subtitle != null)
                  Text(subtitle!, style: ApexTypography.captionSmall.copyWith(color: color)),
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
        childAspectRatio: 2.0,
      ),
      itemCount: devices.length,
      itemBuilder: (context, i) => _DeviceCard(device: devices[i]),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final dynamic device;
  const _DeviceCard({required this.device});

  @override
  Widget build(BuildContext context) {
    final isOnline = device.status == 'online';
    final color = isOnline ? _success : _danger;

    return InkWell(
      onTap: () => context.push('/devices/${device.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      Text(device.status.toUpperCase(), style: ApexTypography.captionSmall.copyWith(color: color, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(device.deviceName, style: ApexTypography.titleSmall.copyWith(color: _text), overflow: TextOverflow.ellipsis),
            Text('S/N: ${device.serialNumber}', style: ApexTypography.captionSmall.copyWith(color: _muted), overflow: TextOverflow.ellipsis),
            if (device.location != null)
              Text(device.location!, style: ApexTypography.captionSmall.copyWith(color: _muted), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _EmptyState({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: _muted),
            const SizedBox(height: 16),
            Text(title, style: ApexTypography.headingMedium.copyWith(color: _text)),
            const SizedBox(height: 8),
            Text(description, style: ApexTypography.bodySmall.copyWith(color: _muted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
