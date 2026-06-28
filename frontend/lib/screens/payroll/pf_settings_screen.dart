import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';

class PFSettingsScreen extends ConsumerStatefulWidget {
  const PFSettingsScreen({super.key});

  @override
  ConsumerState<PFSettingsScreen> createState() => _PFSettingsScreenState();
}

class _PFSettingsScreenState extends ConsumerState<PFSettingsScreen> {
  final _employeeRateCtrl = TextEditingController(text: '12.0');
  final _employerRateCtrl = TextEditingController(text: '12.0');
  final _salaryLimitCtrl = TextEditingController(text: '15000');
  bool _enablePF = true;

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Provident Fund rules updated'), backgroundColor: ApexColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Provident Fund (PF) Rules',
        description: 'Configure employee and employer PF percentages and statutory salary thresholds.',
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ApexColors.neutral200),
              ),
              child: SwitchListTile(
                title: const Text('Enable Provident Fund Deduction'),
                subtitle: const Text('Enforce PF contributions for active employees salary structures.'),
                value: _enablePF,
                onChanged: (v) => setState(() => _enablePF = v),
              ),
            ),
            if (_enablePF) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ApexColors.neutral200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contribution Percentages', style: ApexTypography.cardTitle),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ApexTextField(
                            label: 'Employee Share (%)',
                            controller: _employeeRateCtrl,
                            required: true,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ApexTextField(
                            label: 'Employer Share (%)',
                            controller: _employerRateCtrl,
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ApexColors.neutral200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Statutory Threshold Caps', style: ApexTypography.cardTitle),
                    const SizedBox(height: 16),
                    ApexTextField(
                      label: 'Maximum Statutory Salary Limit (₹/month)',
                      controller: _salaryLimitCtrl,
                      required: true,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
