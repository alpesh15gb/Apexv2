import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../widgets/page_wrapper.dart';

class PTSettingsScreen extends ConsumerWidget {
  const PTSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Professional Tax (PT) Slabs',
        description: 'Configure regional state professional tax calculation slabs and deduction values.',
        isLoading: false,
        isEmpty: true,
        emptyIcon: Icons.account_balance_outlined,
        emptyTitle: 'PT Slabs Not Configured',
        emptySubtitle: 'This feature is not yet configured. Contact your administrator.',
        body: const SizedBox.shrink(),
      ),
    );
  }
}
