import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';

final shiftListProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/shifts/', queryParameters: {'page': 1, 'page_size': 100});
  return res.data['items'] ?? [];
});

class ShiftManagementScreen extends ConsumerWidget {
  const ShiftManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(shiftListProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        title: Text('Shift Management', style: ApexTypography.sectionTitle),
        backgroundColor: Colors.white,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: ApexColors.neutral200)),
        actions: [
          ApexButton(
            label: 'New Shift',
            icon: Icons.add,
            onPressed: () => context.push('/shifts/create'),
          ),
          const SizedBox(width: 8),
          ApexButton(
            label: 'Groups',
            icon: Icons.group_work,
            type: ApexButtonType.ghost,
            onPressed: () => context.push('/shifts/groups'),
          ),
          ApexButton(
            label: 'Rosters',
            icon: Icons.calendar_month,
            type: ApexButtonType.ghost,
            onPressed: () => context.push('/shifts/rosters'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: shiftsAsync.when(
        data: (shifts) {
          if (shifts.isEmpty) return _buildEmptyState(context);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: shifts.length,
            itemBuilder: (context, i) => _ShiftCard(shift: shifts[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: ApexTypography.body.copyWith(color: ApexColors.error))),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, size: 64, color: ApexColors.neutral500.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No Shifts Configured', style: ApexTypography.sectionTitle),
          const SizedBox(height: 8),
          Text('Create shifts to manage employee work schedules', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
          const SizedBox(height: 24),
          ApexButton(
            label: 'Create First Shift',
            icon: Icons.add,
            onPressed: () => context.push('/shifts/create'),
          ),
        ],
      ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  final Map<String, dynamic> shift;
  const _ShiftCard({required this.shift});

  @override
  Widget build(BuildContext context) {
    final name = shift['name'] ?? '';
    final startTime = shift['start_time'] ?? '09:00';
    final endTime = shift['end_time'] ?? '18:00';
    final grace = shift['grace_period_minutes'] ?? 10;
    final isNight = shift['is_night_shift'] == true;
    final isActive = shift['is_active'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ApexCard(
        padding: const EdgeInsets.all(18),
        child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isNight ? ApexColors.info : ApexColors.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(isNight ? Icons.nights_stay : Icons.wb_sunny, color: isNight ? ApexColors.info : ApexColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Row(children: [
                  Text(name, style: ApexTypography.titleMedium.copyWith(color: ApexColors.neutral900)),
                  const SizedBox(width: 8),
                  if (isNight) ApexBadge.info('NIGHT'),
                  const SizedBox(width: 4),
                  isActive ? ApexBadge.success('ACTIVE') : ApexBadge.neutral('INACTIVE'),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  _infoChip(Icons.access_time, '$startTime - $endTime'),
                  const SizedBox(width: 12),
                  _infoChip(Icons.timer, 'Grace: ${grace}min'),
                  if (shift['overtime_threshold_minutes'] != null) ...[
                    const SizedBox(width: 12),
                    _infoChip(Icons.schedule, 'OT: ${shift['overtime_threshold_minutes']}min'),
                  ],
                ]),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 18, color: ApexColors.neutral500),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'assign', child: Text('Assign Employees')),
              const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
              PopupMenuItem(value: 'toggle', child: Text(isActive ? 'Deactivate' : 'Activate')),
            ],
            onSelected: (v) {
              if (v == 'edit') context.push('/shifts/${shift['id']}/edit');
            },
          ),
        ],
      ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: ApexColors.neutral500),
        const SizedBox(width: 4),
        Text(label, style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
      ],
    );
  }
}

