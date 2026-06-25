import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../design_system/typography.dart';
import '../../providers/shift_provider.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _warning = Color(0xFFF59E0B);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

class ShiftListScreen extends ConsumerWidget {
  const ShiftListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(shiftListProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: _bg,
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
                    const Icon(Icons.error_outline, size: 40, color: _danger),
                    const SizedBox(height: 12),
                    Text('Error: ${e.toString()}', style: ApexTypography.bodySmall),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(shiftListProvider),
                      child: const Text('Retry'),
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
        backgroundColor: _primary,
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
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Text('Shifts', style: ApexTypography.pageTitle.copyWith(color: _text)),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: shift.isActive ? _border : _muted.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: shift.isNightShift ? _warning.withOpacity(0.1) : _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  shift.isNightShift ? 'NIGHT' : 'DAY',
                  style: ApexTypography.captionSmall.copyWith(
                    color: shift.isNightShift ? _warning : _primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: shift.isActive ? _success.withOpacity(0.1) : _muted.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  shift.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: ApexTypography.captionSmall.copyWith(
                    color: shift.isActive ? _success : _muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(shift.name, style: ApexTypography.titleMedium.copyWith(color: _text)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: _muted),
              const SizedBox(width: 6),
              Text('${shift.startTime} - ${shift.endTime}', style: ApexTypography.bodySmall.copyWith(color: _muted)),
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
        Text(label, style: ApexTypography.captionSmall.copyWith(color: _muted)),
        const SizedBox(width: 4),
        Text(value, style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.w600, color: _text)),
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
            Icon(icon, size: 48, color: _muted),
            const SizedBox(height: 16),
            Text(title, style: ApexTypography.headingMedium.copyWith(color: _text)),
            const SizedBox(height: 8),
            Text(description, style: ApexTypography.bodySmall.copyWith(color: _muted), textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
