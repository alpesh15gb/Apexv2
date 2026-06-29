import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_button.dart';

class WeeklyOffScreen extends ConsumerStatefulWidget {
  const WeeklyOffScreen({super.key});

  @override
  ConsumerState<WeeklyOffScreen> createState() => _WeeklyOffScreenState();
}

class _WeeklyOffScreenState extends ConsumerState<WeeklyOffScreen> {
  final Map<String, bool> _days = {
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': true,
    'Sunday': true,
  };
  String _policyType = 'standard'; // standard | rotating

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Weekly off settings saved successfully'), backgroundColor: ApexColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Weekly Off Settings',
        description: 'Configure standard or rotating weekly off-days for your employee shifts.',
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ApexColors.neutral0,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ApexColors.neutral200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Off-Day Policy Type', style: ApexTypography.cardTitle),
                  const SizedBox(height: 12),
                  RadioListTile<String>(
                    title: Text('Standard Weekly Off', style: ApexTypography.body.copyWith(color: ApexColors.neutral900)),
                    subtitle: Text('Fixed off-days every week (e.g. Saturday and Sunday)', style: ApexTypography.caption.copyWith(color: ApexColors.neutral600)),
                    value: 'standard',
                    groupValue: _policyType,
                    onChanged: (v) => setState(() => _policyType = v!),
                  ),
                  RadioListTile<String>(
                    title: Text('Rotating Off-Days', style: ApexTypography.body.copyWith(color: ApexColors.neutral900)),
                    subtitle: Text('Configured dynamically via roster patterns', style: ApexTypography.caption.copyWith(color: ApexColors.neutral600)),
                    value: 'rotating',
                    groupValue: _policyType,
                    onChanged: (v) => setState(() => _policyType = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_policyType == 'standard')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ApexColors.neutral0,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ApexColors.neutral200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Fixed Off-Days', style: ApexTypography.cardTitle),
                    const SizedBox(height: 12),
                    ..._days.keys.map((day) => CheckboxListTile(
                          title: Text(day, style: ApexTypography.body.copyWith(color: ApexColors.neutral900)),
                          value: _days[day],
                          onChanged: (v) => setState(() => _days[day] = v ?? false),
                        )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
