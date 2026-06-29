import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';
import '../../widgets/apex_dropdown.dart';

class BiometricSettingsScreen extends ConsumerStatefulWidget {
  const BiometricSettingsScreen({super.key});

  @override
  ConsumerState<BiometricSettingsScreen> createState() => _BiometricSettingsScreenState();
}

class _BiometricSettingsScreenState extends ConsumerState<BiometricSettingsScreen> {
  final _faceQualityCtrl = TextEditingController(text: '75');
  final _fingerprintQualityCtrl = TextEditingController(text: '60');
  String _matchingEngine = 'ZKTeco v10.0';

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Biometric verification matching rules updated'), backgroundColor: ApexColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Biometric Settings',
        description: 'Configure matching engines, face quality thresholds, and template sync limits.',
        actions: [
          ApexButton(
            label: 'Save Settings',
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
                  Text('Biometric Engines', style: ApexTypography.cardTitle),
                  const SizedBox(height: 16),
                  ApexDropdown<String>(
                    label: 'Active Verification Engine',
                    value: _matchingEngine,
                    items: const [
                      DropdownMenuItem(value: 'ZKTeco v10.0', child: Text('ZKTeco matching engine v10.0')),
                      DropdownMenuItem(value: 'eBioServer v3.1', child: Text('eBioServer matching engine v3.1')),
                      DropdownMenuItem(value: 'Local Face Matcher v1.0', child: Text('Local Face Matcher v1.0')),
                    ],
                    onChanged: (v) => setState(() => _matchingEngine = v ?? 'ZKTeco v10.0'),
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
                  Text('Quality Threshold Limits', style: ApexTypography.cardTitle),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ApexTextField(
                          label: 'Face Matching Quality (%)',
                          controller: _faceQualityCtrl,
                          required: true,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ApexTextField(
                          label: 'Fingerprint Match Quality (%)',
                          controller: _fingerprintQualityCtrl,
                          required: true,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
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
