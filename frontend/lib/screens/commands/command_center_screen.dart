import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../services/command_service.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_button.dart';

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
      body: ApexPageWrapper(
        title: 'Device Command Queue',
        description: 'Verify connected hardware statistics, sync events, and trigger commands.',
        onRefresh: () => ref.invalidate(commandsListProvider),
        body: commandsAsync.when(
          data: (commands) {
            if (commands.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.terminal, size: 48, color: ApexColors.neutral400),
                    const SizedBox(height: 16),
                    Text('Command Queue Empty', style: ApexTypography.cardTitle),
                    const SizedBox(height: 8),
                    Text('No reboot, clear logs, or user sync commands are queued currently.', style: ApexTypography.caption),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: commands.length,
              itemBuilder: (context, idx) {
                final cmd = commands[idx];
                final requestedAt = DateTime.parse(cmd['requested_at']);
                final status = cmd['status'] ?? 'pending';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ApexColors.neutral200),
                    ),
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
                        _StatusBadge(status: status),
                        if (status == 'pending') ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.play_arrow, size: 20, color: ApexColors.success),
                            tooltip: 'Execute',
                            onPressed: () async {
                              try {
                                final service = ref.read(commandServiceProvider);
                                await service.executeCommand(cmd['id']);
                                ref.invalidate(commandsListProvider);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Command execution triggered'), backgroundColor: ApexColors.success),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed: $e'), backgroundColor: ApexColors.error),
                                  );
                                }
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: $err', style: ApexTypography.body.copyWith(color: ApexColors.error)),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(commandsListProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
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
      case 'success':
      case 'executed':
        return ApexBadge.success('EXECUTED');
      case 'pending':
        return ApexBadge.warning('PENDING');
      case 'failed':
        return ApexBadge.danger('FAILED');
      default:
        return ApexBadge.neutral(status.toUpperCase());
    }
  }
}
