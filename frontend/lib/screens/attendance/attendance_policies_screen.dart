import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_text_field.dart';

class AttendancePoliciesScreen extends ConsumerStatefulWidget {
  const AttendancePoliciesScreen({super.key});

  @override
  ConsumerState<AttendancePoliciesScreen> createState() => _AttendancePoliciesScreenState();
}

class _AttendancePoliciesScreenState extends ConsumerState<AttendancePoliciesScreen> {
  final _lateThresholdCtrl = TextEditingController(text: '15');
  final _halfDayThresholdCtrl = TextEditingController(text: '240');
  final _absentThresholdCtrl = TextEditingController(text: '480');

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance policies updated'), backgroundColor: ApexColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Attendance Policies',
        description: 'Define late thresholds, half-day bounds, and minimum working hours parameters.',
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
                  Text('Late Check-In Rules', style: ApexTypography.cardTitle),
                  const SizedBox(height: 16),
                  ApexTextField(
                    label: 'Late Check-In Threshold (Minutes)',
                    controller: _lateThresholdCtrl,
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
                  Text('Working Hours Slabs', style: ApexTypography.cardTitle),
                  const SizedBox(height: 16),
                  ApexTextField(
                    label: 'Minimum Minutes for Half-Day Credit',
                    controller: _halfDayThresholdCtrl,
                    required: true,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  ApexTextField(
                    label: 'Minimum Minutes for Full-Day Credit',
                    controller: _absentThresholdCtrl,
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
