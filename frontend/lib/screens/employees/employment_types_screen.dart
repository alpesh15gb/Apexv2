import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';

class EmploymentTypesScreen extends ConsumerStatefulWidget {
  const EmploymentTypesScreen({super.key});

  @override
  ConsumerState<EmploymentTypesScreen> createState() => _EmploymentTypesScreenState();
}

class _EmploymentTypesScreenState extends ConsumerState<EmploymentTypesScreen> {
  List<Map<String, dynamic>> _types = [];
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
      _types = [
        {
          'id': 'permanent',
          'name': 'Permanent Staff',
          'code': 'PERM',
          'count': 42,
          'leave_policy': 'Standard Policy',
          'is_active': true,
        },
        {
          'id': 'contract',
          'name': 'Contractor',
          'code': 'CONT',
          'count': 18,
          'leave_policy': 'Pro-rata Policy',
          'is_active': true,
        },
        {
          'id': 'intern',
          'name': 'Intern',
          'code': 'INTN',
          'count': 5,
          'leave_policy': 'Internship Policy',
          'is_active': true,
        },
        {
          'id': 'consultant',
          'name': 'Consultant',
          'code': 'CONS',
          'count': 2,
          'leave_policy': 'No Paid Leaves',
          'is_active': true,
        },
      ];
      _loading = false;
    });
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final policyCtrl = TextEditingController(text: 'Standard Policy');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Employment Type'),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ApexTextField(label: 'Type Name *', controller: nameCtrl, required: true),
              const SizedBox(height: 12),
              ApexTextField(label: 'Code *', controller: codeCtrl, required: true),
              const SizedBox(height: 12),
              ApexTextField(label: 'Leave Policy Template', controller: policyCtrl),
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
              if (nameCtrl.text.trim().isEmpty || codeCtrl.text.trim().isEmpty) return;
              setState(() {
                _types.insert(0, {
                  'id': nameCtrl.text.trim().toLowerCase().replaceAll(' ', '_'),
                  'name': nameCtrl.text.trim(),
                  'code': codeCtrl.text.trim().toUpperCase(),
                  'count': 0,
                  'leave_policy': policyCtrl.text.trim(),
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
        title: 'Employment Types',
        description: 'Define employment categories and leave policy configurations.',
        onRefresh: _load,
        actions: [
          ApexButton(
            label: 'Add Type',
            onPressed: _showAddDialog,
            type: ApexButtonType.primary,
            icon: Icons.add_circle_outline,
          ),
        ],
        isLoading: _loading,
        isEmpty: _types.isEmpty && !_loading,
        emptyIcon: Icons.category_outlined,
        emptyTitle: 'No Employment Types',
        emptySubtitle: 'Add standard or customized employment categories.',
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _types.length,
          itemBuilder: (context, i) {
            final t = _types[i];
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
                    child: const Icon(Icons.category, color: ApexColors.primary600, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t['name'] as String, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.people_outline, size: 12, color: ApexColors.neutral400),
                            const SizedBox(width: 4),
                            Text('${t['count']} Employees', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                            const SizedBox(width: 12),
                            Icon(Icons.policy_outlined, size: 12, color: ApexColors.neutral400),
                            const SizedBox(width: 4),
                            Text('Policy: ${t['leave_policy']}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  t['is_active'] == true ? ApexBadge.success('ACTIVE') : ApexBadge.neutral('INACTIVE'),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 16, color: ApexColors.neutral500),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    onSelected: (v) {
                      if (v == 'delete') {
                        setState(() {
                          _types.removeWhere((x) => x['id'] == t['id']);
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
