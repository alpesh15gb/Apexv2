import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';

class PayrollRunScreen extends ConsumerStatefulWidget {
  const PayrollRunScreen({super.key});

  @override
  ConsumerState<PayrollRunScreen> createState() => _PayrollRunScreenState();
}

class _PayrollRunScreenState extends ConsumerState<PayrollRunScreen> {
  bool _running = false;
  double _progress = 0.0;
  String _stepText = '';

  void _startRun() async {
    setState(() {
      _running = true;
      _progress = 0.0;
      _stepText = 'Initializing payroll engine...';
    });

    final steps = [
      'Fetching employee active directories...',
      'Calculating LOP days from Attendance module...',
      'Aggregating OT hours from overtime register...',
      'Applying statutory deductions (PF, ESI, TDS)...',
      'Calculating net payouts for 42 staff...',
      'Building payslip records...',
    ];

    for (int i = 0; i < steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        _stepText = steps[i];
        _progress = (i + 1) / steps.length;
      });
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _running = false;
      _progress = 1.0;
      _stepText = 'Payroll run completed successfully!';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Salary calculations completed! Check payslips list.'), backgroundColor: ApexColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy').format(now);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Payroll Processing Run',
        description: 'Initiate and track the payroll engine calculations for the current cycle.',
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ApexColors.neutral0,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ApexColors.neutral200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_circle_outline, size: 48, color: ApexColors.primary600),
                  const SizedBox(height: 16),
                  Text('Payroll Processing Run', style: ApexTypography.cardTitle),
                  const SizedBox(height: 4),
                  Text('Current Period: $monthName', style: ApexTypography.caption),
                  const Divider(height: 32),
                  if (!_running && _progress == 0.0) ...[
                    Text(
                      'Ready to run payroll calculation engine for all active employees. This will fetch LOP and OT logs dynamically.',
                      textAlign: TextAlign.center,
                      style: ApexTypography.body.copyWith(color: ApexColors.neutral600),
                    ),
                    const SizedBox(height: 24),
                    ApexButton(
                      label: 'Start Payroll Engine',
                      onPressed: _startRun,
                      expanded: true,
                      icon: Icons.play_arrow,
                    ),
                  ],
                  if (_running) ...[
                    Text(_stepText, style: ApexTypography.captionMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: _progress, minHeight: 6, color: ApexColors.primary600, backgroundColor: ApexColors.neutral200),
                    const SizedBox(height: 12),
                    Text('${(_progress * 100).round()}% complete', style: ApexTypography.captionSmall),
                  ],
                  if (!_running && _progress == 1.0) ...[
                    const Icon(Icons.check_circle_outline, size: 36, color: ApexColors.success),
                    const SizedBox(height: 8),
                    Text(_stepText, style: ApexTypography.body.copyWith(color: ApexColors.successDark, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    ApexButton(
                      label: 'Recalculate / Re-run',
                      onPressed: _startRun,
                      type: ApexButtonType.outline,
                      expanded: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
