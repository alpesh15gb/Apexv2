import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../widgets/page_wrapper.dart';

class PayslipsEmailScreen extends ConsumerWidget {
  const PayslipsEmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Email Payslips',
        description: 'Distribute generated payslips directly to employee registered email addresses.',
        isLoading: false,
        isEmpty: true,
        emptyIcon: Icons.mail_outline,
        emptyTitle: 'Payslip Email Not Configured',
        emptySubtitle: 'This feature is not yet configured. Contact your administrator.',
        body: const SizedBox.shrink(),
      ),
    );
  }
}
