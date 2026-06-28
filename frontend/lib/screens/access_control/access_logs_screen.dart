import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../services/access_control_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_card.dart';

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
      backgroundColor: ApexColors.neutral50,
      appBar: const ApexAppBar(title: 'Access Attempt Logs'),
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
                final granted = log['granted'] as bool;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ApexCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: granted ? ApexColors.successLight : ApexColors.errorLight,
                          child: Icon(
                            granted ? Icons.lock_open : Icons.lock,
                            color: granted ? ApexColors.success : ApexColors.error,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                granted ? 'Access Granted' : 'Access Denied',
                                style: ApexTypography.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: granted ? ApexColors.successDark : ApexColors.errorDark,
                                ),
                              ),
                              Text('Door: ${log['door_name'] ?? 'N/A'}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                              Text('Time: ${DateFormat('MMM dd, hh:mm a').format(time)}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                            ],
                          ),
                        ),
                        if (log['denial_reason'] != null)
                          Tooltip(
                            message: log['denial_reason'],
                            child: Icon(Icons.info_outline, color: ApexColors.warning, size: 20),
                          ),
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
            onRetry: () => ref.invalidate(accessLogsProvider),
          ),
        ),
      ),
    );
  }
}
