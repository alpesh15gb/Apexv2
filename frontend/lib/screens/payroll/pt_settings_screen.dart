import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';

class PTSettingsScreen extends ConsumerStatefulWidget {
  const PTSettingsScreen({super.key});

  @override
  ConsumerState<PTSettingsScreen> createState() => _PTSettingsScreenState();
}

class _PTSettingsScreenState extends ConsumerState<PTSettingsScreen> {
  List<Map<String, dynamic>> _slabs = [];
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
      _slabs = [
        {
          'id': 'PTS001',
          'state': 'Karnataka',
          'min_salary': 15000.0,
          'max_salary': 999999.0,
          'deduction': 200.0,
        },
        {
          'id': 'PTS002',
          'state': 'Maharashtra',
          'min_salary': 10000.0,
          'max_salary': 999999.0,
          'deduction': 200.0,
        },
        {
          'id': 'PTS003',
          'state': 'Tamil Nadu',
          'min_salary': 12000.0,
          'max_salary': 999999.0,
          'deduction': 150.0,
        },
      ];
      _loading = false;
    });
  }

  void _showAddDialog() {
    final stateCtrl = TextEditingController();
    final minCtrl = TextEditingController(text: '15000');
    final maxCtrl = TextEditingController(text: '999999');
    final dedCtrl = TextEditingController(text: '200');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add PT State Slab'),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ApexTextField(label: 'State *', controller: stateCtrl, required: true),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: ApexTextField(label: 'Min Salary *', controller: minCtrl, required: true, keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: ApexTextField(label: 'Max Salary *', controller: maxCtrl, required: true, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              ApexTextField(label: 'Deduction Amount (₹) *', controller: dedCtrl, required: true, keyboardType: TextInputType.number),
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
              if (stateCtrl.text.trim().isEmpty || dedCtrl.text.trim().isEmpty) return;
              setState(() {
                _slabs.insert(0, {
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'state': stateCtrl.text.trim(),
                  'min_salary': double.tryParse(minCtrl.text.trim()) ?? 15000.0,
                  'max_salary': double.tryParse(maxCtrl.text.trim()) ?? 999999.0,
                  'deduction': double.tryParse(dedCtrl.text.trim()) ?? 200.0,
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
        title: 'Professional Tax (PT) Slabs',
        description: 'Configure regional state professional tax calculation slabs and deduction values.',
        actions: [
          ApexButton(
            label: 'Add Slab',
            onPressed: _showAddDialog,
            type: ApexButtonType.primary,
            icon: Icons.add,
          ),
        ],
        isLoading: _loading,
        isEmpty: _slabs.isEmpty && !_loading,
        emptyIcon: Icons.account_balance_outlined,
        emptyTitle: 'No PT Slabs Configured',
        emptySubtitle: 'Define state PT rules for monthly salary deductions.',
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _slabs.length,
          itemBuilder: (context, i) {
            final s = _slabs[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ApexColors.neutral0,
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
                    child: const Icon(Icons.account_balance_wallet, color: ApexColors.primary600, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['state'] as String, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Slab: ₹${s['min_salary']} – ₹${s['max_salary']}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                      ],
                    ),
                  ),
                  Text('₹${s['deduction']}/mo', style: ApexTypography.titleSmall.copyWith(color: ApexColors.error)),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 16, color: ApexColors.neutral500),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    onSelected: (v) {
                      if (v == 'delete') {
                        setState(() {
                          _slabs.removeWhere((x) => x['id'] == s['id']);
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
