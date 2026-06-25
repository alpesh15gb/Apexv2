import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../services/access_control_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';

final accessLogsProvider = FutureProvider((ref) async {
  final service = ref.read(accessControlServiceProvider);
  final data = await service.getAccessLogs(page: 1, pageSize: 100);
  return data['items'] as List;
});

class AccessLogsScreen extends ConsumerWidget {
  const AccessLogsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(accessLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Access Attempt Logs')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(accessLogsProvider),
        child: logsAsync.when(
          data: (logs) {
            if (logs.isEmpty) {
              return const EmptyState(
                title: 'No Access Logs',
                description: 'Door swipe attempts and check-ins will show up here.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, idx) {
                final log = logs[idx];
                final time = DateTime.parse(log['access_time']);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: log['granted'] ? Colors.green.shade50 : Colors.red.shade50,
                      child: Icon(
                        log['granted'] ? Icons.lock_open : Icons.lock,
                        color: log['granted'] ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(
                      log['granted'] ? 'Access Granted' : 'Access Denied',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: log['granted'] ? Colors.green.shade900 : Colors.red.shade900,
                      ),
                    ),
                    subtitle: Text('Door: ${log['door_name'] ?? 'N/A'}\nTime: ${DateFormat('MMM dd, hh:mm a').format(time)}'),
                    trailing: log['denial_reason'] != null ? Tooltip(message: log['denial_reason'], child: const Icon(Icons.info_outline, color: Colors.orange)) : null,
                  ),
                );
              },
            );
          },
          loading: () => const LoadingWidget(count: 4),
          error: (err, stack) => CustomErrorWidget(
            errorMessage: err.toString(),
            onRetry: () => ref.invalidate(accessLogsProvider),
          ),
        ),
      ),
    );
  }
}
