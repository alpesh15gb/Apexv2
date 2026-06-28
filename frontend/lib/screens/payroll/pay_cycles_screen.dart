import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';
import '../../widgets/apex_dropdown.dart';

class PayCyclesScreen extends ConsumerStatefulWidget {
  const PayCyclesScreen({super.key});

  @override
  ConsumerState<PayCyclesScreen> createState() => _PayCyclesScreenState();
}

class _PayCyclesScreenState extends ConsumerState<PayCyclesScreen> {
  List<Map<String, dynamic>> _cycles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _cycles = [
        {
          'id': 'PCY001',
          'name': 'Standard Monthly Cycle',
          'frequency': 'Monthly',
          'start_day': 1,
          'payout_day': 30,
          'is_active': true,
        },
        {
          'id': 'PCY002',
          'name': 'Contractors Weekly Cycle',
          'frequency': 'Weekly',
          'start_day': 1, // Monday
          'payout_day': 5, // Friday
          'is_active': true,
        },
      ];
      _loading = false;
    });
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    String freq = 'monthly';
    final payoutCtrl = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Pay Cycle'),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ApexTextField(label: 'Cycle Name *', controller: nameCtrl, required: true),
                const SizedBox(height: 12),
                ApexDropdown<String>(
                  label: 'Frequency',
                  value: freq,
                  items: const [
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'biweekly', child: Text('Bi-Weekly')),
                  ],
                  onChanged: (v) => setDialogState(() => freq = v!),
                ),
                const SizedBox(height: 12),
                ApexTextField(label: 'Payout Day of Month / Week *', controller: payoutCtrl, required: true, keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            ApexButton(
              label: 'Cancel',
              onPressed: () => Navigator.pop(ctx),
              type: ApexButtonType.outline,
            ),
            ApexButton(
              label: 'Add',
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || payoutCtrl.text.trim().isEmpty) return;
                setState(() {
                  _cycles.insert(0, {
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'name': nameCtrl.text.trim(),
                    'frequency': freq.toUpperCase(),
                    'start_day': 1,
                    'payout_day': int.tryParse(payoutCtrl.text.trim()) ?? 30,
                    'is_active': true,
                  });
                });
                Navigator.pop(ctx);
              },
              type: ApexButtonType.primary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Pay Cycles Settings',
        description: 'Define weekly, bi-weekly, or monthly salary cycle schedules.',
        onRefresh: _load,
        actions: [
          ApexButton(
            label: 'Add Cycle',
            onPressed: _showAddDialog,
            type: ApexButtonType.primary,
            icon: Icons.add,
          ),
        ],
        isLoading: _loading,
        isEmpty: _cycles.isEmpty && !_loading,
        emptyIcon: Icons.loop_outlined,
        emptyTitle: 'No Pay Cycles',
        emptySubtitle: 'Configure cycles to define start/end calculation parameters.',
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _cycles.length,
          itemBuilder: (context, i) {
            final c = _cycles[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ApexColors.neutral200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ApexColors.primary600.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.loop, color: ApexColors.primary600, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['name'] as String, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            ApexBadge.neutral((c['frequency'] as String).toUpperCase()),
                            const SizedBox(width: 8),
                            Text('Cycle Start: Day ${c['start_day']} • Payout: Day ${c['payout_day']}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  c['is_active'] == true ? ApexBadge.success('ACTIVE') : ApexBadge.neutral('INACTIVE'),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 16, color: ApexColors.neutral500),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    onSelected: (v) {
                      if (v == 'delete') {
                        setState(() {
                          _cycles.removeWhere((x) => x['id'] == c['id']);
                        });
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
