import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../widgets/page_wrapper.dart';

class VisitorCardsScreen extends ConsumerWidget {
  const VisitorCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Visitor Cards',
        description: 'Manage guest credentials, temporary RFID tags, and QR barcodes allocation.',
        isLoading: false,
        isEmpty: true,
        emptyIcon: Icons.credit_card_outlined,
        emptyTitle: 'Visitor Cards Not Configured',
        emptySubtitle: 'This feature is not yet configured. Contact your administrator.',
        body: const SizedBox.shrink(),
      ),
    );
  }
}
