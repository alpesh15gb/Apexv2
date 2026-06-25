import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../services/command_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

final commandsListProvider = FutureProvider((ref) async {
  final service = ref.read(commandServiceProvider);
  final data = await service.getCommands(page: 1, pageSize: 50);
  return data['items'] as List;
});

class CommandCenterScreen extends ConsumerWidget {
  const CommandCenterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commandsAsync = ref.watch(commandsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Device Command Queue')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(commandsListProvider),
        child: commandsAsync.when(
          data: (commands) {
            if (commands.isEmpty) {
              return const EmptyState(
                title: 'Command Queue Empty',
                description: 'No reboot, clear logs, or user sync commands are queued currently.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: commands.length,
              itemBuilder: (context, idx) {
                final cmd = commands[idx];
                final requestedAt = DateTime.parse(cmd['requested_at']);
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.terminal)),
                    title: Text(cmd['command_type'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Requested: ${DateFormat('MMM dd, hh:mm a').format(requestedAt)}'),
                    trailing: StatusBadge(status: cmd['status']),
                    onTap: cmd['status'] == 'pending' ? () async {
                      try {
                        final service = ref.read(commandServiceProvider);
                        await service.executeCommand(cmd['id']);
                        ref.invalidate(commandsListProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Command execution triggered'), backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Execution failed: ${e.toString()}'), backgroundColor: Colors.red),
                        );
                      }
                    } : null,
                  ),
                );
              },
            );
          },
          loading: () => const LoadingWidget(count: 4),
          error: (err, stack) => CustomErrorWidget(
            errorMessage: err.toString(),
            onRetry: () => ref.invalidate(commandsListProvider),
          ),
        ),
      ),
    );
  }
}
