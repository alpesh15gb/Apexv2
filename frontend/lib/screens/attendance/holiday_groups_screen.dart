import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../widgets/page_wrapper.dart';

class HolidayGroupsScreen extends ConsumerWidget {
  const HolidayGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Holiday Groups',
        description: 'Organize and map regional or state-specific holiday calendars to branches.',
        isLoading: false,
        isEmpty: true,
        emptyIcon: Icons.group_work_outlined,
        emptyTitle: 'Holiday Groups Not Configured',
        emptySubtitle: 'This feature is not yet configured. Contact your administrator.',
        body: const SizedBox.shrink(),
      ),
    );
  }
}
