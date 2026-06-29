import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../widgets/page_wrapper.dart';

class PayrollRunScreen extends ConsumerWidget {
  const PayrollRunScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Payroll Processing Run',
        description: 'Initiate and track the payroll engine calculations for the current cycle.',
        isLoading: false,
        isEmpty: true,
        emptyIcon: Icons.play_circle_outline,
        emptyTitle: 'Payroll Run Not Configured',
        emptySubtitle: 'This feature is not yet configured. Contact your administrator.',
        body: const SizedBox.shrink(),
      ),
    );
  }
}
