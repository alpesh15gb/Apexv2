import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';

class PayComponentsScreen extends ConsumerStatefulWidget {
  const PayComponentsScreen({super.key});

  @override
  ConsumerState<PayComponentsScreen> createState() => _PayComponentsScreenState();
}

class _PayComponentsScreenState extends ConsumerState<PayComponentsScreen> {
  List<Map<String, dynamic>> _components = [];
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
      _components = [
        {
          'id': 'PC001',
          'name': 'Basic Salary',
          'type': 'earning',
          'calculation_type': 'Fixed',
          'is_taxable': true,
          'is_active': true,
        },
        {
          'id': 'PC002',
          'name': 'House Rent Allowance (HRA)',
          'type': 'earning',
          'calculation_type': '40% of Basic',
          'is_taxable': true,
          'is_active': true,
        },
        {
          'id': 'PC003',
          'name': 'Provident Fund (PF) Employee',
          'type': 'deduction',
          'calculation_type': '12% of Basic',
          'is_taxable': false,
          'is_active': true,
        },
      ];
      _loading = false;
    });
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final typeCtrl = TextEditingController(text: 'earning');
    final calcCtrl = TextEditingController(text: 'Fixed');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Pay Component'),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ApexTextField(label: 'Component Name *', controller: nameCtrl, required: true),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: typeCtrl.text,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'earning', child: Text('Earning')),
                    DropdownMenuItem(value: 'deduction', child: Text('Deduction')),
                  ],
                  onChanged: (v) => setDialogState(() => typeCtrl.text = v!),
                ),
                const SizedBox(height: 12),
                ApexTextField(label: 'Calculation Basis', controller: calcCtrl),
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
                if (nameCtrl.text.trim().isEmpty) return;
                setState(() {
                  _components.insert(0, {
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'name': nameCtrl.text.trim(),
                    'type': typeCtrl.text,
                    'calculation_type': calcCtrl.text.trim(),
                    'is_taxable': true,
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
        title: 'Pay Components',
        description: 'Define and configure salary earnings, allowances, pre-tax deductions, and bonuses.',
        onRefresh: _load,
        actions: [
          ApexButton(
            label: 'Add Component',
            onPressed: _showAddDialog,
            type: ApexButtonType.primary,
            icon: Icons.add,
          ),
        ],
        isLoading: _loading,
        isEmpty: _components.isEmpty && !_loading,
        emptyIcon: Icons.extension_outlined,
        emptyTitle: 'No Pay Components',
        emptySubtitle: 'Configure earnings and deductions for salary sheets calculations.',
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _components.length,
          itemBuilder: (context, i) {
            final c = _components[i];
            final statusColor = c['type'] == 'earning' ? ApexColors.success : ApexColors.error;
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
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(c['type'] == 'earning' ? Icons.add_circle_outline : Icons.remove_circle_outline, color: statusColor, size: 20),
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
                            ApexBadge.neutral((c['type'] as String).toUpperCase()),
                            const SizedBox(width: 8),
                            Text('Basis: ${c['calculation_type']}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
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
                          _components.removeWhere((x) => x['id'] == c['id']);
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
