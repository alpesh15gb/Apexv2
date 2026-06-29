import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../widgets/page_wrapper.dart';

class DeviceGroupsScreen extends ConsumerWidget {
  const DeviceGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Device Groups',
        description: 'Define groups of terminals to route command queues and sync requests.',
        isLoading: false,
        isEmpty: true,
        emptyIcon: Icons.device_hub_outlined,
        emptyTitle: 'Device Groups Not Configured',
        emptySubtitle: 'This feature is not yet configured. Contact your administrator.',
        body: const SizedBox.shrink(),
      ),
    );
  }
}
