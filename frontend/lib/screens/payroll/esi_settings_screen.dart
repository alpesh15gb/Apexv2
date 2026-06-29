import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';

class ESISettingsScreen extends ConsumerStatefulWidget {
  const ESISettingsScreen({super.key});

  @override
  ConsumerState<ESISettingsScreen> createState() => _ESISettingsScreenState();
}

class _ESISettingsScreenState extends ConsumerState<ESISettingsScreen> {
  final _employeeRateCtrl = TextEditingController(text: '0.75');
  final _employerRateCtrl = TextEditingController(text: '3.25');
  final _salaryLimitCtrl = TextEditingController(text: '21000');
  bool _enableESI = true;

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ESI calculation rules updated'), backgroundColor: ApexColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Employee State Insurance (ESI) Rules',
        description: 'Configure ESI percentages and maximum salary eligibility thresholds.',
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
                color: ApexColors.neutral0,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ApexColors.neutral200),
              ),
              child: SwitchListTile(
                title: const Text('Enable ESI Deduction'),
                subtitle: const Text('Enforce ESI contributions for eligible staff salary slips.'),
                value: _enableESI,
                onChanged: (v) => setState(() => _enableESI = v),
              ),
            ),
            if (_enableESI) ...[
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
                    Text('ESI Percentages', style: ApexTypography.cardTitle),
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
                  color: ApexColors.neutral0,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ApexColors.neutral200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Eligibility Slabs', style: ApexTypography.cardTitle),
                    const SizedBox(height: 16),
                    ApexTextField(
                      label: 'Maximum Salary Limit for ESI Coverage (₹/month)',
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
