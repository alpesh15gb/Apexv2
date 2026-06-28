import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';

class AutoShiftScreen extends ConsumerStatefulWidget {
  const AutoShiftScreen({super.key});

  @override
  ConsumerState<AutoShiftScreen> createState() => _AutoShiftScreenState();
}

class _AutoShiftScreenState extends ConsumerState<AutoShiftScreen> {
  final _punchWindowCtrl = TextEditingController(text: '45');
  final _matchingToleranceCtrl = TextEditingController(text: '15');
  bool _enableAutoShift = true;

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Auto-shift parameters updated successfully'), backgroundColor: ApexColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Auto Shift Settings',
        description: 'Define matching boundaries and punch window parameters for automatic shift detection.',
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
                title: const Text('Enable Auto-Shift Assignment'),
                subtitle: const Text('Automatically assign shifts based on check-in punch timestamp.'),
                value: _enableAutoShift,
                onChanged: (v) => setState(() => _enableAutoShift = v),
              ),
            ),
            if (_enableAutoShift) ...[
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
                    Text('Auto-Shift Parameters', style: ApexTypography.cardTitle),
                    const SizedBox(height: 16),
                    ApexTextField(
                      label: 'Punch Matching Window (Minutes)',
                      controller: _punchWindowCtrl,
                      required: true,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    ApexTextField(
                      label: 'Threshold Matching Tolerance (Minutes)',
                      controller: _matchingToleranceCtrl,
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
