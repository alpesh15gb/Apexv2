import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/visitor_provider.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/page_wrapper.dart';

class VisitorListScreen extends ConsumerWidget {
  const VisitorListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passesState = ref.watch(visitorPassesProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Visitor Logs',
        description: 'Verify checks, register guest credentials, and monitor active passes.',
        onRefresh: () => ref.invalidate(visitorPassesProvider),
        actions: [
          ApexButton(
            label: 'Register Visitor',
            onPressed: () => context.push('/visitors/register'),
            type: ApexButtonType.primary,
            icon: Icons.person_add,
          ),
        ],
        body: passesState.passes.when(
          data: (visitors) {
            if (visitors.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.card_membership, size: 48, color: ApexColors.neutral400),
                    const SizedBox(height: 16),
                    Text('No Visitors Logs', style: ApexTypography.cardTitle),
                    const SizedBox(height: 8),
                    Text('Register a visitor to get started', style: ApexTypography.caption),
                    const SizedBox(height: 16),
                    ApexButton(
                      label: 'Register Visitor',
                      icon: Icons.person_add,
                      onPressed: () => context.push('/visitors/register'),
                      type: ApexButtonType.primary,
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: visitors.length,
              itemBuilder: (context, i) {
                final v = visitors[i];
                final status = v.status ?? 'active';
                final isCheckedIn = status == 'active' || status == 'checked_in';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ApexColors.neutral200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: ApexColors.primary600.withOpacity(0.1),
                          child: Text((v.visitorName ?? 'V')[0].toUpperCase(), style: ApexTypography.titleSmall.copyWith(color: ApexColors.primary600)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v.visitorName ?? 'Visitor', style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                              Text('${v.visitorName ?? 'Visitor'} • ${v.purpose ?? '—'}', style: ApexTypography.caption.copyWith(color: ApexColors.neutral500)),
                            ],
                          ),
                        ),
                        _StatusBadge(status: status),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.qr_code_scanner, size: 18, color: ApexColors.primary),
                          tooltip: 'View Pass',
                          onPressed: () => context.push('/visitors/passes?passId=${v.id}'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
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
      case 'active':
      case 'checked_in':
        return ApexBadge.success('CHECKED IN');
      case 'completed':
      case 'checked_out':
        return ApexBadge.neutral('CHECKED OUT');
      default:
        return ApexBadge.neutral(status.toUpperCase());
    }
  }
}
