import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../widgets/page_wrapper.dart';

class IllegalLogsScreen extends ConsumerWidget {
  const IllegalLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Illegal Access Logs',
        description: 'Review security alerts, failed pin trials, card reading mismatches, and access violations.',
        isLoading: false,
        isEmpty: true,
        emptyIcon: Icons.warning_outlined,
        emptyTitle: 'Illegal Logs Not Configured',
        emptySubtitle: 'This feature is not yet configured. Contact your administrator.',
        body: const SizedBox.shrink(),
      ),
    );
  }
}
