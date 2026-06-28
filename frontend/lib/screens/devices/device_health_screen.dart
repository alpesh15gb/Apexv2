import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/device_provider.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/page_wrapper.dart';

class DeviceHealthScreen extends ConsumerWidget {
  const DeviceHealthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(deviceHealthProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Device Health Status',
        description: 'Verify connected hardware statistics, network pings, and sync logs control.',
        onRefresh: () => ref.invalidate(deviceHealthProvider),
        body: healthAsync.when(
          data: (health) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Biometric Terminals Connectivity',
                style: ApexTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildHealthCard('Total Terminals', '${health.totalDevices}', Icons.devices, Colors.blue),
              _buildHealthCard('Online Terminals', '${health.online}', Icons.cloud_done, ApexColors.success),
              _buildHealthCard('Offline Terminals', '${health.offline}', Icons.cloud_off, ApexColors.error),
              _buildHealthCard('Inactive Terminals', '${health.inactive}', Icons.pause_circle_outline, ApexColors.warning),
              _buildHealthCard('Terminals with Errors', '${health.error}', Icons.error_outline, ApexColors.error),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: $err', style: ApexTypography.body.copyWith(color: ApexColors.error)),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(deviceHealthProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHealthCard(String title, String count, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ApexCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          title: Text(title, style: ApexTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
          trailing: Text(
            count,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
