import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_badge.dart';

final feePaymentsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/school/fees/payments');
  return res.data is List ? res.data : [];
});

final feeDuesProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/school/fees/reports/dues');
  return res.data is List ? res.data : [];
});

class FeeCollectionScreen extends ConsumerStatefulWidget {
  const FeeCollectionScreen({super.key});

  @override
  ConsumerState<FeeCollectionScreen> createState() => _FeeCollectionScreenState();
}

class _FeeCollectionScreenState extends ConsumerState<FeeCollectionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(feePaymentsProvider);
    final duesAsync = ref.watch(feeDuesProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: ApexColors.neutral0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fee Collection', style: ApexTypography.pageTitle.copyWith(color: ApexColors.neutral900)),
                          const SizedBox(height: 4),
                          Text('Collect fees and track payments', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showCollectDialog(context),
                      icon: const Icon(Icons.payment, size: 16),
                      label: const Text('Collect Fee'),
                      style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabCtrl,
                  labelColor: ApexColors.primary600,
                  unselectedLabelColor: ApexColors.neutral500,
                  indicatorColor: ApexColors.primary600,
                  tabs: const [
                    Tab(text: 'Payments'),
                    Tab(text: 'Pending Dues'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                paymentsAsync.when(
                  data: (payments) {
                    if (payments.isEmpty) return Center(child: Text('No payments recorded', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)));
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: payments.length,
                      itemBuilder: (context, i) {
                        final p = payments[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: ApexColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.payment, size: 20, color: ApexColors.success),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('₹${p['amount'] ?? 0}', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600)),
                              Text('Receipt: ${p['receipt_number'] ?? '-'} • ${p['payment_method'] ?? ''}', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
                            ])),
                            Text(p['payment_date'] ?? '', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                          ]),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
                duesAsync.when(
                  data: (dues) {
                    if (dues.isEmpty) return Center(child: Text('No pending dues', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)));
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: dues.length,
                      itemBuilder: (context, i) {
                        final d = dues[i];
                        final status = d['status'] ?? 'pending';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
                          child: Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(d['student_name'] ?? '', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600)),
                              Text('Adm: ${d['admission_number'] ?? ''}', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
                            ])),
                            Text('₹${d['final_amount'] ?? 0}', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600, color: ApexColors.error)),
                            const SizedBox(width: 8),
                            ApexBadge(
                              label: status,
                              type: status == 'paid' ? ApexBadgeType.success : status == 'partial' ? ApexBadgeType.warning : ApexBadgeType.danger,
                            ),
                          ]),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCollectDialog(BuildContext context) {
    // TODO: Implement fee collection dialog with student search and fee selection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fee collection dialog - coming soon')),
    );
  }
}
