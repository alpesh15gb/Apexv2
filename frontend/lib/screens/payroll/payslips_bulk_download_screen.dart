import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/colors.dart';
import '../../widgets/page_wrapper.dart';

class PayslipsBulkDownloadScreen extends ConsumerWidget {
  const PayslipsBulkDownloadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Bulk Download Payslips',
        description: 'Batch export generated payslip PDFs for local records or distribution.',
        isLoading: false,
        isEmpty: true,
        emptyIcon: Icons.download_for_offline_outlined,
        emptyTitle: 'Bulk Download Not Configured',
        emptySubtitle: 'This feature is not yet configured. Contact your administrator.',
        body: const SizedBox.shrink(),
      ),
    );
  }
}
