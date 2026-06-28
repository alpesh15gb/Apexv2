import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../models/visitor.dart';
import '../../providers/visitor_provider.dart';
import '../../services/visitor_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/apex_button.dart';

final visitorPassDetailProvider = FutureProvider.family<VisitorPass, String>((ref, id) async {
  final service = ref.read(visitorServiceProvider);
  return service.getVisitorPass(id);
});

class VisitorPassScreen extends ConsumerWidget {
  final String passId;

  const VisitorPassScreen({Key? key, required this.passId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(visitorPassDetailProvider(passId));

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: const ApexAppBar(title: 'Visitor Access Pass'),
      body: detailAsync.when(
        data: (pass) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 400,
              child: ApexCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.badge, size: 64, color: ApexColors.primary600),
                    const SizedBox(height: 16),
                    Text(
                      'VISITOR PASS',
                      style: ApexTypography.titleMedium.copyWith(
                        letterSpacing: 2,
                        color: ApexColors.primary600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pass.passNumber,
                      style: ApexTypography.headingMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StatusBadge(status: pass.status),
                    const Divider(height: 32),
                    _buildRow('Visitor Name', pass.visitorName ?? 'N/A'),
                    _buildRow('Host Employee', pass.hostName ?? 'N/A'),
                    _buildRow('Purpose', pass.purpose),
                    _buildRow('Expected Date', DateFormat('MMM dd, yyyy').format(pass.expectedDate)),
                    _buildRow('Check-in', pass.checkInTime != null ? DateFormat('hh:mm a').format(pass.checkInTime!) : '--:--'),
                    _buildRow('Check-out', pass.checkOutTime != null ? DateFormat('hh:mm a').format(pass.checkOutTime!) : '--:--'),
                    const SizedBox(height: 32),
                    if (pass.status == 'scheduled')
                      ApexButton(
                        label: 'Check In',
                        icon: Icons.login,
                        type: ApexButtonType.success,
                        expanded: true,
                        onPressed: () async {
                          await ref.read(visitorPassesProvider.notifier).checkIn(pass.id);
                          ref.invalidate(visitorPassDetailProvider(passId));
                        },
                      )
                    else if (pass.status == 'checked_in')
                      ApexButton(
                        label: 'Check Out',
                        icon: Icons.logout,
                        type: ApexButtonType.danger,
                        expanded: true,
                        onPressed: () async {
                          await ref.read(visitorPassesProvider.notifier).checkOut(pass.id);
                          ref.invalidate(visitorPassDetailProvider(passId));
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        loading: () => const LoadingWidget(count: 1),
        error: (err, stack) => CustomErrorWidget(
          errorMessage: err.toString(),
          onRetry: () => ref.invalidate(visitorPassDetailProvider(passId)),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
          Text(value, style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
