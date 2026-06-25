import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/device_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class DeviceHealthScreen extends ConsumerWidget {
  const DeviceHealthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(deviceHealthProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Health Dashboard'),
      ),
      body: healthAsync.when(
        data: (health) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Biometric Terminals Status',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildHealthCard('Total Terminals', '${health.totalDevices}', Icons.devices, Colors.blue),
              const SizedBox(height: 12),
              _buildHealthCard('Online Terminals', '${health.online}', Icons.cloud_done, Colors.green),
              const SizedBox(height: 12),
              _buildHealthCard('Offline Terminals', '${health.offline}', Icons.cloud_off, Colors.red),
              const SizedBox(height: 12),
              _buildHealthCard('Inactive Terminals', '${health.inactive}', Icons.pause_circle_outline, Colors.orange),
              const SizedBox(height: 12),
              _buildHealthCard('Terminals with Errors', '${health.error}', Icons.error_outline, Colors.redAccent),
            ],
          ),
        ),
        loading: () => const LoadingWidget(count: 3),
        error: (err, stack) => CustomErrorWidget(
          errorMessage: err.toString(),
          onRetry: () => ref.invalidate(deviceHealthProvider),
        ),
      ),
    );
  }

  Widget _buildHealthCard(String title, String count, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Text(
          count,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
