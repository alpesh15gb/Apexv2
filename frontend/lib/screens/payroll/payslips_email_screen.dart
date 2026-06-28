import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_button.dart';

class PayslipsEmailScreen extends ConsumerStatefulWidget {
  const PayslipsEmailScreen({super.key});

  @override
  ConsumerState<PayslipsEmailScreen> createState() => _PayslipsEmailScreenState();
}

class _PayslipsEmailScreenState extends ConsumerState<PayslipsEmailScreen> {
  bool _sending = false;
  double _progress = 0.0;
  String _statusText = '';

  void _send() async {
    setState(() {
      _sending = true;
      _progress = 0.0;
      _statusText = 'Initializing mail server...';
    });

    final steps = [
      'Packaging payslips PDFs...',
      'Queueing emails for Head Office staff...',
      'Queueing emails for Factory Gate staff...',
      'Dispatching 42 payslips...',
    ];

    for (int i = 0; i < steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        _statusText = steps[i];
        _progress = (i + 1) / steps.length;
      });
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _sending = false;
      _progress = 1.0;
      _statusText = 'All emails dispatched successfully!';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payslips emailed to 42 employees'), backgroundColor: ApexColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy').format(now);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Email Payslips',
        description: 'Distribute generated payslips directly to employee registered email addresses.',
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ApexColors.neutral200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mail_outline, size: 48, color: ApexColors.primary600),
                  const SizedBox(height: 16),
                  Text('Email Distribution', style: ApexTypography.cardTitle),
                  const SizedBox(height: 4),
                  Text('Active Period: $monthName', style: ApexTypography.caption),
                  const Divider(height: 32),
                  if (!_sending && _progress == 0.0) ...[
                    Text(
                      'Ready to email payslips to 42 active employees. Employees will receive a secure PDF attachment.',
                      textAlign: TextAlign.center,
                      style: ApexTypography.body.copyWith(color: ApexColors.neutral600),
                    ),
                    const SizedBox(height: 24),
                    ApexButton(
                      label: 'Start Email Dispatch',
                      onPressed: _send,
                      expanded: true,
                      icon: Icons.send_outlined,
                    ),
                  ],
                  if (_sending) ...[
                    Text(_statusText, style: ApexTypography.captionMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: _progress, minHeight: 6, color: ApexColors.primary600, backgroundColor: ApexColors.neutral200),
                    const SizedBox(height: 12),
                    Text('${(_progress * 100).round()}% complete', style: ApexTypography.captionSmall),
                  ],
                  if (!_sending && _progress == 1.0) ...[
                    const Icon(Icons.check_circle_outline, size: 36, color: ApexColors.success),
                    const SizedBox(height: 8),
                    Text(_statusText, style: ApexTypography.body.copyWith(color: ApexColors.successDark, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    ApexButton(
                      label: 'Re-send Emails',
                      onPressed: _send,
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
