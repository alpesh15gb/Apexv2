import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/visitor_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/apex_button.dart';

class ActiveVisitorsScreen extends ConsumerWidget {
  const ActiveVisitorsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeVisitorsProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: const ApexAppBar(title: 'Active Visitors (Inside)'),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(activeVisitorsProvider),
        child: activeAsync.when(
          data: (passes) {
            if (passes.isEmpty) {
              return const EmptyState(
                title: 'No Active Visitors',
                description: 'There are no checked-in visitors in the workspace currently.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: passes.length,
              itemBuilder: (context, idx) {
                final pass = passes[idx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ApexCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: ApexColors.primary100,
                          child: Icon(Icons.badge, color: ApexColors.primary600),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pass.visitorName ?? 'Visitor', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('Host: ${pass.hostName ?? 'N/A'}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                              Text('Checked-in: ${pass.checkInTime != null ? DateFormat('hh:mm a').format(pass.checkInTime!) : ''}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                            ],
                          ),
                        ),
                        ApexButton(
                          label: 'Check Out',
                          type: ApexButtonType.danger,
                          onPressed: () async {
                            await ref.read(visitorPassesProvider.notifier).checkOut(pass.id);
                            ref.invalidate(activeVisitorsProvider);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const LoadingWidget(count: 3),
          error: (err, stack) => CustomErrorWidget(
            errorMessage: err.toString(),
            onRetry: () => ref.invalidate(activeVisitorsProvider),
          ),
        ),
      ),
    );
  }
}
