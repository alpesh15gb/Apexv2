import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/apex_text_field.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';

final essLeavesProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/ess/leaves');
  return res.data is List ? res.data : [];
});

final essBalanceProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/ess/leaves/balance');
  return res.data is List ? res.data : [];
});

class EssLeaveScreen extends ConsumerStatefulWidget {
  const EssLeaveScreen({super.key});
  @override
  ConsumerState<EssLeaveScreen> createState() => _EssLeaveScreenState();
}

class _EssLeaveScreenState extends ConsumerState<EssLeaveScreen> {
  @override
  Widget build(BuildContext context) {
    final leavesAsync = ref.watch(essLeavesProvider);
    final balanceAsync = ref.watch(essBalanceProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        title: Text('My Leaves', style: ApexTypography.cardTitle),
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: ApexColors.neutral200)),
        actions: [
          ApexButton(label: 'Apply', onPressed: () => _showApplyDialog(context), type: ApexButtonType.primary, icon: Icons.add),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Leave Balance', style: ApexTypography.titleMedium),
          const SizedBox(height: 8),
          balanceAsync.when(
            data: (balances) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: balances.map((b) => SizedBox(
                width: 140,
                child: ApexCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(b['type'] ?? '', style: ApexTypography.titleMedium),
                    const SizedBox(height: 4),
                    Text('${(b['available'] ?? 0).toInt()} days left', style: ApexTypography.titleMedium.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: ApexColors.primary600)),
                    Text('${(b['used'] ?? 0).toInt()} used of ${(b['total'] ?? 0).toInt()}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                  ]),
                ),
              )).toList(),
            ),
            loading: () => const SizedBox(height: 60, child: Center(child: LoadingWidget(useShimmer: false))),
            error: (e, _) => CustomErrorWidget(
              errorMessage: e.toString(),
              onRetry: () => ref.invalidate(essBalanceProvider),
            ),
          ),
          const SizedBox(height: 24),
          Text('Leave History', style: ApexTypography.titleMedium),
          const SizedBox(height: 8),
          leavesAsync.when(
            data: (leaves) {
              if (leaves.isEmpty) return const Padding(padding: EdgeInsets.all(32), child: EmptyState(
                icon: Icons.event_busy_outlined,
                title: 'No Leave Requests',
                description: 'Apply for leave and your requests will appear here.',
                actionLabel: 'Apply Leave',
                onActionPressed: null,
              ));
              return Column(children: leaves.map((l) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                child: ApexCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${l['start_date']} → ${l['end_date']}', style: ApexTypography.titleMedium),
                      Text(l['reason'] ?? '', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                    _leaveStatusBadge(l['status']),
                  ]),
                ),
              )).toList());
            },
            loading: () => const LoadingWidget(),
            error: (e, _) => CustomErrorWidget(
              errorMessage: e.toString(),
              onRetry: () => ref.invalidate(essLeavesProvider),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _leaveStatusBadge(String? status) {
    final s = (status ?? '').toLowerCase();
    if (s == 'approved') return ApexBadge.success(s.toUpperCase());
    if (s == 'rejected') return ApexBadge.danger(s.toUpperCase());
    if (s == 'pending') return ApexBadge.warning(s.toUpperCase());
    return ApexBadge(label: (status ?? '').toUpperCase(), type: ApexBadgeType.neutral);
  }

  void _showApplyDialog(BuildContext context) {
    final reasonCtrl = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Apply Leave', style: ApexTypography.sectionTitle),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              title: Text('Start Date', style: ApexTypography.body),
              subtitle: Text('${startDate.toLocal()}'.split(' ')[0], style: ApexTypography.caption),
              trailing: Icon(Icons.calendar_today, size: 18, color: ApexColors.neutral500),
              onTap: () async {
                final picked = await showDatePicker(context: ctx, initialDate: startDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (picked != null) setDialogState(() => startDate = picked);
              },
            ),
            ListTile(
              title: Text('End Date', style: ApexTypography.body),
              subtitle: Text('${endDate.toLocal()}'.split(' ')[0], style: ApexTypography.caption),
              trailing: Icon(Icons.calendar_today, size: 18, color: ApexColors.neutral500),
              onTap: () async {
                final picked = await showDatePicker(context: ctx, initialDate: endDate, firstDate: startDate, lastDate: DateTime.now().add(const Duration(days: 365)));
                if (picked != null) setDialogState(() => endDate = picked);
              },
            ),
            const SizedBox(height: 8),
            ApexTextField(label: 'Reason', controller: reasonCtrl, maxLines: 2),
          ])),
          actions: [
            ApexButton(label: 'Cancel', onPressed: () => Navigator.pop(ctx), type: ApexButtonType.outline),
            ApexButton(
              label: 'Submit',
              onPressed: () async {
                try {
                  final dio = ref.read(dioProvider);
                  await dio.post('/ess/leaves', data: {
                    'start_date': startDate.toIso8601String().substring(0, 10),
                    'end_date': endDate.toIso8601String().substring(0, 10),
                    'reason': reasonCtrl.text.trim(),
                  });
                  Navigator.pop(ctx);
                  ref.invalidate(essLeavesProvider);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Leave applied!'), backgroundColor: ApexColors.success));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: ApexColors.error));
                }
              },
              type: ApexButtonType.primary,
            ),
          ],
        ),
      ),
    );
  }
}
