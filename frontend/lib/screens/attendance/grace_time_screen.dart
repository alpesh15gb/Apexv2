import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';

class GraceTimeScreen extends ConsumerStatefulWidget {
  const GraceTimeScreen({super.key});

  @override
  ConsumerState<GraceTimeScreen> createState() => _GraceTimeScreenState();
}

class _GraceTimeScreenState extends ConsumerState<GraceTimeScreen> {
  final _checkInGraceCtrl = TextEditingController(text: '10');
  final _checkOutGraceCtrl = TextEditingController(text: '10');
  final _allowedOccurrencesCtrl = TextEditingController(text: '3');

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Grace time settings updated successfully'), backgroundColor: ApexColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Grace Time Settings',
        description: 'Configure standard check-in and check-out grace minutes before late marks apply.',
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
                  Text('Shift Grace Minutes', style: ApexTypography.cardTitle),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ApexTextField(
                          label: 'Check-In Grace (Minutes)',
                          controller: _checkInGraceCtrl,
                          required: true,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ApexTextField(
                          label: 'Check-Out Grace (Minutes)',
                          controller: _checkOutGraceCtrl,
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
                  Text('Late Check-In Tolerances', style: ApexTypography.cardTitle),
                  const SizedBox(height: 16),
                  ApexTextField(
                    label: 'Max Allowed Grace Occurrences per Month',
                    controller: _allowedOccurrencesCtrl,
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
