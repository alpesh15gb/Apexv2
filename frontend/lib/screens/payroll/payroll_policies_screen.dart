import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';
import '../../widgets/apex_dropdown.dart';

class PayrollPoliciesScreen extends ConsumerStatefulWidget {
  const PayrollPoliciesScreen({super.key});

  @override
  ConsumerState<PayrollPoliciesScreen> createState() => _PayrollPoliciesScreenState();
}

class _PayrollPoliciesScreenState extends ConsumerState<PayrollPoliciesScreen> {
  final _lopFormulaCtrl = TextEditingController(text: 'Basic / 30');
  final _roundingLimitCtrl = TextEditingController(text: '1.0');
  String _lopBasis = 'calendar_days'; // calendar_days | working_days

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payroll policies saved successfully'), backgroundColor: ApexColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Payroll Policies',
        description: 'Define Loss-of-Pay (LOP) calculations, net-pay decimal rounding, and final settlement rules.',
        actions: [
          ApexButton(
            label: 'Save Policies',
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
                  Text('Loss-of-Pay (LOP) Deductions', style: ApexTypography.cardTitle),
                  const SizedBox(height: 16),
                  ApexDropdown<String>(
                    label: 'LOP Calculation Basis',
                    value: _lopBasis,
                    items: const [
                      DropdownMenuItem(value: 'calendar_days', child: Text('Total Calendar Days (e.g. 30/31)')),
                      DropdownMenuItem(value: 'working_days', child: Text('Exclude Weekly Offs (e.g. 26)')),
                      DropdownMenuItem(value: 'fixed_30', child: Text('Fixed 30 Days divisor')),
                    ],
                    onChanged: (v) => setState(() => _lopBasis = v!),
                  ),
                  const SizedBox(height: 12),
                  ApexTextField(
                    label: 'LOP Daily Rate Formula',
                    controller: _lopFormulaCtrl,
                    required: true,
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
                  Text('Payslip Rounding Limits', style: ApexTypography.cardTitle),
                  const SizedBox(height: 16),
                  ApexTextField(
                    label: 'Net Pay Decimal Rounding (e.g. to nearest ₹1)',
                    controller: _roundingLimitCtrl,
                    required: true,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
