import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../widgets/page_wrapper.dart';

class VisitorDesksScreen extends ConsumerWidget {
  const VisitorDesksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Visitor Desks',
        description: 'Configure reception check-in desks and security gate portals.',
        isLoading: false,
        isEmpty: true,
        emptyIcon: Icons.desk_outlined,
        emptyTitle: 'Visitor Desks Not Configured',
        emptySubtitle: 'This feature is not yet configured. Contact your administrator.',
        body: const SizedBox.shrink(),
      ),
    );
  }
}
