import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';

class OvertimeRulesScreen extends ConsumerStatefulWidget {
  const OvertimeRulesScreen({super.key});

  @override
  ConsumerState<OvertimeRulesScreen> createState() => _OvertimeRulesScreenState();
}

class _OvertimeRulesScreenState extends ConsumerState<OvertimeRulesScreen> {
  final _minOtMinutesCtrl = TextEditingController(text: '60');
  final _rateMultiplierCtrl = TextEditingController(text: '1.5');
  final _holidayMultiplierCtrl = TextEditingController(text: '2.0');
  bool _requireApproval = true;

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Overtime rules updated successfully'), backgroundColor: ApexColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Overtime Rules',
        description: 'Define minimum OT windows, hourly multipliers, and holiday rate factors.',
        actions: [
          ApexButton(
            label: 'Save Rules',
            onPressed: _save,
            type: ApexButtonType.primary,
            icon: Icons.save_outlined,
          ),
        ],
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ApexColors.neutral0,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ApexColors.neutral200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('OT Accrual Windows', style: ApexTypography.cardTitle),
                  const SizedBox(height: 16),
                  ApexTextField(
                    label: 'Minimum OT Minutes to Accrue',
                    controller: _minOtMinutesCtrl,
                    required: true,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ApexColors.neutral0,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ApexColors.neutral200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hourly Rate Multipliers', style: ApexTypography.cardTitle),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ApexTextField(
                          label: 'Standard Overtime Rate (e.g. 1.5x)',
                          controller: _rateMultiplierCtrl,
                          required: true,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ApexTextField(
                          label: 'Holiday/Weekend Overtime (e.g. 2.0x)',
                          controller: _holidayMultiplierCtrl,
                          required: true,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ApexColors.neutral0,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ApexColors.neutral200),
              ),
              child: SwitchListTile(
                title: const Text('Require Manager Approval for OT Credit'),
                subtitle: const Text('Unapproved overtime hours will not calculate in payroll.'),
                value: _requireApproval,
                onChanged: (v) => setState(() => _requireApproval = v),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
