import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/essl_provider.dart';
import '../../widgets/page_wrapper.dart';

class EsslSyncHistoryScreen extends ConsumerWidget {
  final String serverId;
  const EsslSyncHistoryScreen({Key? key, required this.serverId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(esslSyncHistoryProvider(serverId));

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Sync History',
        description: 'Verify connected hardware statistics, sync events, and trigger commands.',
        onRefresh: () => ref.invalidate(esslSyncHistoryProvider(serverId)),
        body: historyAsync.when(
          data: (history) {
            if (history.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sync, size: 48, color: ApexColors.neutral400),
                    const SizedBox(height: 16),
                    Text('No Sync History', style: ApexTypography.cardTitle.copyWith(color: ApexColors.neutral900)),
                    const SizedBox(height: 8),
                    Text('Sync history will appear here after the first sync', style: ApexTypography.caption.copyWith(color: ApexColors.neutral500)),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, i) {
                final h = history[i];
                final statusColor = h.status == 'completed' ? ApexColors.success : h.status == 'failed' ? ApexColors.error : ApexColors.warning;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ApexColors.neutral200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          h.status == 'completed' ? Icons.check_circle : h.status == 'failed' ? Icons.error : Icons.sync,
                          color: statusColor,
                          size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${h.syncType.toUpperCase()} Sync', style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                          Text(
                            '${DateFormat('MMM dd, HH:mm').format(h.startedAt)} • ${h.recordsFetched} records',
                            style: ApexTypography.caption.copyWith(color: ApexColors.neutral500),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(h.status.toUpperCase(), style: ApexTypography.badge.copyWith(color: statusColor, fontSize: 10)),
                        ),
                        if (h.durationSeconds != null)
                          Text('${h.durationSeconds!.toStringAsFixed(1)}s', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: ApexTypography.body.copyWith(color: ApexColors.error))),
      ),
    ),
  );
}
}
