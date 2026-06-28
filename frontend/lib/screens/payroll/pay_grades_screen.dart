import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';

class PayGradesScreen extends ConsumerStatefulWidget {
  const PayGradesScreen({super.key});

  @override
  ConsumerState<PayGradesScreen> createState() => _PayGradesScreenState();
}

class _PayGradesScreenState extends ConsumerState<PayGradesScreen> {
  List<Map<String, dynamic>> _grades = [];
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
      _grades = [
        {
          'id': 'PG001',
          'name': 'Grade A - Leadership',
          'code': 'GR-A',
          'min_salary': 150000.0,
          'max_salary': 300000.0,
          'is_active': true,
        },
        {
          'id': 'PG002',
          'name': 'Grade B - Engineering Manager',
          'code': 'GR-B',
          'min_salary': 90000.0,
          'max_salary': 140000.0,
          'is_active': true,
        },
        {
          'id': 'PG003',
          'name': 'Grade C - Senior Engineer',
          'code': 'GR-C',
          'min_salary': 50000.0,
          'max_salary': 85000.0,
          'is_active': true,
        },
      ];
      _loading = false;
    });
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final minCtrl = TextEditingController(text: '30000');
    final maxCtrl = TextEditingController(text: '45000');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Pay Grade'),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ApexTextField(label: 'Grade Name *', controller: nameCtrl, required: true),
              const SizedBox(height: 12),
              ApexTextField(label: 'Code *', controller: codeCtrl, required: true),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: ApexTextField(label: 'Min Salary *', controller: minCtrl, required: true, keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: ApexTextField(label: 'Max Salary *', controller: maxCtrl, required: true, keyboardType: TextInputType.number)),
                ],
              ),
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
                _grades.insert(0, {
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'name': nameCtrl.text.trim(),
                  'code': codeCtrl.text.trim().toUpperCase(),
                  'min_salary': double.tryParse(minCtrl.text.trim()) ?? 30000.0,
                  'max_salary': double.tryParse(maxCtrl.text.trim()) ?? 45000.0,
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
        title: 'Pay Grades',
        description: 'Define and manage salary grade brackets, minimum and maximum ranges, and designations links.',
        onRefresh: _load,
        actions: [
          ApexButton(
            label: 'Add Grade',
            onPressed: _showAddDialog,
            type: ApexButtonType.primary,
            icon: Icons.add,
          ),
        ],
        isLoading: _loading,
        isEmpty: _grades.isEmpty && !_loading,
        emptyIcon: Icons.leaderboard_outlined,
        emptyTitle: 'No Pay Grades',
        emptySubtitle: 'Configure salary scale bands to structure salary offers.',
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _grades.length,
          itemBuilder: (context, i) {
            final g = _grades[i];
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
                    child: const Icon(Icons.leaderboard, color: ApexColors.primary600, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g['name'] as String, style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.payments_outlined, size: 12, color: ApexColors.neutral400),
                            const SizedBox(width: 4),
                            Text('Range: ₹${g['min_salary']} – ₹${g['max_salary']}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  g['is_active'] == true ? ApexBadge.success('ACTIVE') : ApexBadge.neutral('INACTIVE'),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 16, color: ApexColors.neutral500),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    onSelected: (v) {
                      if (v == 'delete') {
                        setState(() {
                          _grades.removeWhere((x) => x['id'] == g['id']);
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
