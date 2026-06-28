import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/shift_provider.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';

class ShiftListScreen extends ConsumerWidget {
  const ShiftListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(shiftListProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: Column(
        children: [
          // Header
          _Header(isMobile: isMobile),
          // Content
          Expanded(
            child: shiftsAsync.when(
              data: (shifts) {
                if (shifts.isEmpty) {
                  return _EmptyState(
                    icon: Icons.schedule,
                    title: 'No Shifts Configured',
                    description: 'Create shifts to define work timings and attendance rules.',
                    actionLabel: 'Create Shift',
                    onAction: () => context.push('/shifts/create'),
                  );
                }
                return _ShiftGrid(shifts: shifts, isMobile: isMobile);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 40, color: ApexColors.error),
                    const SizedBox(height: 12),
                    Text('Error: ${e.toString()}', style: ApexTypography.bodySmall),
                    const SizedBox(height: 12),
                    ApexButton(
                      label: 'Retry',
                      onPressed: () => ref.invalidate(shiftListProvider),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/shifts/create'),
        backgroundColor: ApexColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isMobile;
  const _Header({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 20, 12, isMobile ? 16 : 20, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: ApexColors.neutral200)),
      ),
      child: Row(
        children: [
          Text('Shifts', style: ApexTypography.pageTitle.copyWith(color: ApexColors.neutral900)),
          const Spacer(),
          if (!isMobile) ...[
            IconButton(icon: const Icon(Icons.assignment_ind_outlined, size: 18), tooltip: 'Assign Shifts', onPressed: () => context.push('/shifts/assign')),
          ],
        ],
      ),
    );
  }
}

class _ShiftGrid extends StatelessWidget {
  final List<dynamic> shifts;
  final bool isMobile;

  const _ShiftGrid({required this.shifts, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.0,
      ),
      itemCount: shifts.length,
      itemBuilder: (context, index) => _ShiftCard(shift: shifts[index]),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  final dynamic shift;
  const _ShiftCard({required this.shift});

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Row(
            children: [
              shift.isNightShift ? ApexBadge.warning('NIGHT') : ApexBadge.info('DAY'),
              const Spacer(),
              shift.isActive ? ApexBadge.success('ACTIVE') : ApexBadge.neutral('INACTIVE'),
            ],
          ),
          const SizedBox(height: 10),
          Text(shift.name, style: ApexTypography.titleMedium.copyWith(color: ApexColors.neutral900)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: ApexColors.neutral500),
              const SizedBox(width: 6),
              Text('${shift.startTime} - ${shift.endTime}', style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500)),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _Rule(label: 'Grace', value: '${shift.gracePeriodMinutes}m'),
              const SizedBox(width: 12),
              _Rule(label: 'Late', value: '${shift.lateRuleMinutes}m'),
              const SizedBox(width: 12),
              _Rule(label: 'OT', value: '${shift.overtimeThresholdMinutes}m'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  final String label;
  final String value;
  const _Rule({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
        const SizedBox(width: 4),
        Text(value, style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral900)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({required this.icon, required this.title, required this.description, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: ApexColors.neutral500),
            const SizedBox(height: 16),
            Text(title, style: ApexTypography.headingMedium.copyWith(color: ApexColors.neutral900)),
            const SizedBox(height: 8),
            Text(description, style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500), textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ApexButton(
                label: actionLabel!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

