import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../widgets/page_wrapper.dart';

class VisitorBlacklistScreen extends ConsumerWidget {
  const VisitorBlacklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Visitor Blacklist',
        description: 'Manage blocked guest profiles to prevent unauthorized access check-in.',
        isLoading: false,
        isEmpty: true,
        emptyIcon: Icons.block_outlined,
        emptyTitle: 'Visitor Blacklist Not Configured',
        emptySubtitle: 'This feature is not yet configured. Contact your administrator.',
        body: const SizedBox.shrink(),
      ),
    );
  }
}
