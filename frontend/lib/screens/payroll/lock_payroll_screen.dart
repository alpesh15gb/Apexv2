import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';

class LockPayrollScreen extends ConsumerStatefulWidget {
  const LockPayrollScreen({super.key});

  @override
  ConsumerState<LockPayrollScreen> createState() => _LockPayrollScreenState();
}

class _LockPayrollScreenState extends ConsumerState<LockPayrollScreen> {
  bool _locked = false;

  void _toggleLock() {
    setState(() {
      _locked = !_locked;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_locked ? 'Payroll period locked' : 'Payroll period unlocked'),
        backgroundColor: _locked ? ApexColors.success : ApexColors.warning,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy').format(now);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Lock Payroll Period',
        description: 'Freeze salary sheets calculations to prevent modifications during bank transfers.',
        actions: [
          ApexButton(
            label: _locked ? 'Unlock Period' : 'Lock Period',
            onPressed: _toggleLock,
            type: _locked ? ApexButtonType.outline : ApexButtonType.danger,
            icon: _locked ? Icons.lock_open : Icons.lock_outline,
          ),
        ],
        body: Center(
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
                Icon(
                  _locked ? Icons.lock : Icons.lock_open,
                  size: 48,
                  color: _locked ? ApexColors.error : ApexColors.success,
                ),
                const SizedBox(height: 16),
                Text(
                  _locked ? 'Payroll Period is LOCKED' : 'Payroll Period is ACTIVE',
                  style: ApexTypography.cardTitle,
                ),
                const SizedBox(height: 4),
                Text('Active Period: $monthName', style: ApexTypography.caption),
                const Divider(height: 32),
                Text(
                  _locked
                      ? 'No edits, recalculations, LOP adjustments, or manual overrides can be entered for this month. Unlock to modify.'
                      : 'Closing a payroll period prevents accidental changes after payouts are processed. Ensure bank advices match.',
                  textAlign: TextAlign.center,
                  style: ApexTypography.body.copyWith(color: ApexColors.neutral600),
                ),
                const SizedBox(height: 24),
                ApexButton(
                  label: _locked ? 'Unlock Calculations' : 'Lock Calculations',
                  onPressed: _toggleLock,
                  type: _locked ? ApexButtonType.outline : ApexButtonType.danger,
                  expanded: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
