import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/visitor_provider.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';

class VisitorListScreen extends ConsumerWidget {
  const VisitorListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passesState = ref.watch(visitorPassesProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: ApexAppBar(title: 'Visitors', actions: [
          IconButton(icon: const Icon(Icons.person_add, size: 18), tooltip: 'Register Visitor', onPressed: () => context.push('/visitors/register')),
          IconButton(icon: const Icon(Icons.card_membership, size: 18), tooltip: 'Active Visitors', onPressed: () => context.push('/visitors/active')),
        ]),
      body: passesState.passes.when(
        data: (visitors) {
          if (visitors.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_membership, size: 48, color: ApexColors.neutral400),
                  const SizedBox(height: 16),
                  Text('No Visitors', style: ApexTypography.headingMedium.copyWith(color: ApexColors.neutral900)),
                  const SizedBox(height: 8),
                  Text('Register a visitor to get started', style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500)),
                  const SizedBox(height: 16),
                  ApexButton(
                    label: 'Register Visitor',
                    icon: Icons.person_add,
                    onPressed: () => context.push('/visitors/register'),
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
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ApexCard(
                  padding: const EdgeInsets.all(14),
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
                            Text('${v.visitorName ?? 'Visitor'} • ${v.purpose ?? '—'}', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
                          ],
                        ),
                      ),
                      ApexBadge(label: v.status, type: ApexBadgeType.success),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/visitors/register'),
        backgroundColor: ApexColors.primary600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
