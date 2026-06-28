import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';

class LeavePoliciesScreen extends ConsumerStatefulWidget {
  const LeavePoliciesScreen({super.key});

  @override
  ConsumerState<LeavePoliciesScreen> createState() => _LeavePoliciesScreenState();
}

class _LeavePoliciesScreenState extends ConsumerState<LeavePoliciesScreen> {
  List<Map<String, dynamic>> _policies = [];
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
      _policies = [
        {
          'id': 'LP001',
          'name': 'Standard Corporate Policy',
          'type': 'Casual/Sick Combo',
          'accrual_rate': '1.5 days per month',
          'carry_forward_max': '6 days',
          'encashable': 'Yes',
          'is_active': true,
        },
        {
          'id': 'LP002',
          'name': 'Factory Labour Policy',
          'type': 'Earned Leaves Only',
          'accrual_rate': '1 day per 20 working days',
          'carry_forward_max': '30 days',
          'encashable': 'Yes (on exit)',
          'is_active': true,
        },
        {
          'id': 'LP003',
          'name': 'Probationer/Intern Policy',
          'type': 'Unpaid Leave Policy',
          'accrual_rate': 'No paid accrual',
          'carry_forward_max': '0 days',
          'encashable': 'No',
          'is_active': true,
        },
      ];
      _loading = false;
    });
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final typeCtrl = TextEditingController();
    final rateCtrl = TextEditingController(text: '1.5 days per month');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Leave Policy'),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ApexTextField(label: 'Policy Name *', controller: nameCtrl, required: true),
              const SizedBox(height: 12),
              ApexTextField(label: 'Policy Type *', controller: typeCtrl, required: true),
              const SizedBox(height: 12),
              ApexTextField(label: 'Accrual Rate', controller: rateCtrl),
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
              if (nameCtrl.text.trim().isEmpty || typeCtrl.text.trim().isEmpty) return;
              setState(() {
                _policies.insert(0, {
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'name': nameCtrl.text.trim(),
                  'type': typeCtrl.text.trim(),
                  'accrual_rate': rateCtrl.text.trim(),
                  'carry_forward_max': '0 days',
                  'encashable': 'No',
                  'is_active': true,
                });
              });
              Navigator.pop(ctx);
            },
            type: ApexButtonType.primary,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Leave Policies',
        description: 'Configure leave accruals rules, encashment, and carry-forward thresholds.',
        onRefresh: _load,
        actions: [
          ApexButton(
            label: 'Add Policy',
            onPressed: _showAddDialog,
            type: ApexButtonType.primary,
            icon: Icons.policy_outlined,
          ),
        ],
        isLoading: _loading,
        isEmpty: _policies.isEmpty && !_loading,
        emptyIcon: Icons.policy_outlined,
        emptyTitle: 'No Leave Policies',
        emptySubtitle: 'Define leave policies to enforce accrual constraints.',
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _policies.length,
          itemBuilder: (context, i) {
            final p = _policies[i];
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
                    child: const Icon(Icons.policy, color: ApexColors.primary600, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['name'] as String, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.rate_review, size: 12, color: ApexColors.neutral400),
                            const SizedBox(width: 4),
                            Text('Accrual: ${p['accrual_rate']}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                            const SizedBox(width: 12),
                            Icon(Icons.call_missed_outgoing, size: 12, color: ApexColors.neutral400),
                            const SizedBox(width: 4),
                            Text('Carry Forward Max: ${p['carry_forward_max']}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  p['is_active'] == true ? ApexBadge.success('ACTIVE') : ApexBadge.neutral('INACTIVE'),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 16, color: ApexColors.neutral500),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    onSelected: (v) {
                      if (v == 'delete') {
                        setState(() {
                          _policies.removeWhere((x) => x['id'] == p['id']);
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
