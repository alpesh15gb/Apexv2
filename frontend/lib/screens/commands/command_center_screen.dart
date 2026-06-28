import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../services/command_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_card.dart';

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
      backgroundColor: ApexColors.neutral50,
      appBar: const ApexAppBar(title: 'Device Command Queue'),
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
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ApexCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: ApexColors.neutral100,
                          child: Icon(Icons.terminal, color: ApexColors.neutral700),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cmd['command_type'].toString().toUpperCase(), style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600)),
                              Text('Requested: ${DateFormat('MMM dd, hh:mm a').format(requestedAt)}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                            ],
                          ),
                        ),
                        StatusBadge(status: cmd['status']),
                        if (cmd['status'] == 'pending') ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.play_arrow, size: 20, color: ApexColors.success),
                            tooltip: 'Execute',
                            onPressed: () async {
                              try {
                                final service = ref.read(commandServiceProvider);
                                await service.executeCommand(cmd['id']);
                                ref.invalidate(commandsListProvider);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Command execution triggered'), backgroundColor: ApexColors.success),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Execution failed: ${e.toString()}'), backgroundColor: ApexColors.error),
                                );
                              }
                            },
                          ),
                        ],
                      ],
                    ),
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
