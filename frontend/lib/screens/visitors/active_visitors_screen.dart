import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/visitor_provider.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';

class ActiveVisitorsScreen extends ConsumerWidget {
  const ActiveVisitorsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeVisitorsProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Active Visitors',
        description: 'Real-time overview of checked-in guests inside the office building.',
        onRefresh: () => ref.invalidate(activeVisitorsProvider),
        body: activeAsync.when(
          data: (passes) {
            if (passes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.badge_outlined, size: 48, color: ApexColors.neutral400),
                    const SizedBox(height: 16),
                    Text('No Active Visitors', style: ApexTypography.cardTitle),
                    const SizedBox(height: 8),
                    Text('There are no checked-in visitors in the workspace currently.', style: ApexTypography.caption),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: passes.length,
              itemBuilder: (context, idx) {
                final pass = passes[idx];
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
                          backgroundColor: ApexColors.primary100,
                          child: const Icon(Icons.badge, color: ApexColors.primary600),
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
