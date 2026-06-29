import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../widgets/page_wrapper.dart';

class LeavePoliciesScreen extends ConsumerWidget {
  const LeavePoliciesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Leave Policies',
        description: 'Configure leave accruals rules, encashment, and carry-forward thresholds.',
        isLoading: false,
        isEmpty: true,
        emptyIcon: Icons.policy_outlined,
        emptyTitle: 'Leave Policies Not Configured',
        emptySubtitle: 'This feature is not yet configured. Contact your administrator.',
        body: const SizedBox.shrink(),
      ),
    );
  }
}
