import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/apex_text_field.dart';

final leaveTypesProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/leaves/types');
    return res.data is List ? res.data : [];
  } catch (e) {
    return [];
  }
});

class LeaveTypesScreen extends ConsumerWidget {
  const LeaveTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(leaveTypesProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        title: Text('Leave Types', style: ApexTypography.sectionTitle),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/leaves')),
        actions: [
          ApexButton(
            label: 'New Type',
            icon: Icons.add,
            onPressed: () => _showCreateDialog(context, ref),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: typesAsync.when(
        data: (types) {
          if (types.isEmpty) return _buildEmptyState(context, ref);
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: types.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LeaveTypeCard(type: types[i], ref: ref),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 40, color: ApexColors.error),
              const SizedBox(height: 16),
              Text('Failed to load leave types', style: ApexTypography.body.copyWith(color: ApexColors.neutral600)),
              const SizedBox(height: 16),
              ApexButton(
                label: 'Retry',
                type: ApexButtonType.outline,
                onPressed: () => ref.invalidate(leaveTypesProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category, size: 48, color: ApexColors.neutral300),
          const SizedBox(height: 16),
          Text('No Leave Types Configured', style: ApexTypography.cardTitle.copyWith(color: ApexColors.neutral900)),
          const SizedBox(height: 8),
          Text('Create leave types for your organization', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
          const SizedBox(height: 24),
          ApexButton(
            label: 'Create Leave Type',
            icon: Icons.add,
            onPressed: () => _showCreateDialog(context, ref),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final daysCtrl = TextEditingController(text: '12');
    bool carryForward = false;
    bool halfDay = true;
    bool isActive = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Create Leave Type', style: ApexTypography.sectionTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ApexTextField(label: 'Leave Type Name', controller: nameCtrl, required: true),
                const SizedBox(height: 16),
                ApexTextField(label: 'Code', controller: codeCtrl, required: true),
                const SizedBox(height: 16),
                ApexTextField(label: 'Annual Days', controller: daysCtrl, required: true, keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text('Carry Forward', style: ApexTypography.body),
                  value: carryForward,
                  onChanged: (v) => setDialogState(() => carryForward = v),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: Text('Half Day Allowed', style: ApexTypography.body),
                  value: halfDay,
                  onChanged: (v) => setDialogState(() => halfDay = v),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: Text('Active', style: ApexTypography.body),
                  value: isActive,
                  onChanged: (v) => setDialogState(() => isActive = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            ApexButton(label: 'Cancel', type: ApexButtonType.ghost, onPressed: () => Navigator.pop(ctx)),
            ApexButton(
              label: 'Create',
              onPressed: () async {
                try {
                  final dio = ref.read(dioProvider);
                  await dio.post('/leaves/types', data: {
                    'name': nameCtrl.text.trim(),
                    'code': codeCtrl.text.trim().toUpperCase(),
                    'max_days_per_year': int.tryParse(daysCtrl.text) ?? 12,
                    'is_active': isActive,
                  });
                  Navigator.pop(ctx);
                  ref.invalidate(leaveTypesProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Leave type created'), backgroundColor: ApexColors.success),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: ApexColors.error),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaveTypeCard extends StatelessWidget {
  final Map<String, dynamic> type;
  final WidgetRef ref;

  const _LeaveTypeCard({required this.type, required this.ref});

  @override
  Widget build(BuildContext context) {
    final name = type['name'] ?? '';
    final code = type['code'] ?? '';
    final days = type['max_days_per_year'] ?? 0;
    final isActive = type['is_active'] == true;

    return ApexCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ApexColors.primary50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                code.isNotEmpty ? code.substring(0, 2) : 'LT',
                style: ApexTypography.titleSmall.copyWith(color: ApexColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(name, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                  const SizedBox(width: 8),
                  isActive ? ApexBadge.success('ACTIVE') : ApexBadge(label: 'INACTIVE'),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  _infoChip(Icons.calendar_today, '$days days/year'),
                  const SizedBox(width: 16),
                  _infoChip(Icons.repeat, type['carry_forward'] == true ? 'Carry forward' : 'No carry forward'),
                  const SizedBox(width: 16),
                  _infoChip(Icons.access_time, type['half_day_allowed'] == true ? 'Half day OK' : 'Full day only'),
                ]),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 18, color: ApexColors.neutral500),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'toggle', child: Text(isActive ? 'Deactivate' : 'Activate')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
            onSelected: (v) async {
              if (v == 'toggle') {
                final dio = ref.read(dioProvider);
                await dio.put('/leaves/types/${type['id']}', data: {'is_active': !isActive});
                ref.invalidate(leaveTypesProvider);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: ApexColors.neutral400),
        const SizedBox(width: 4),
        Text(label, style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
      ],
    );
  }
}
