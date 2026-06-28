import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';

final feePaymentsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/school/fees/payments');
  final data = res.data;
  if (data is Map && data['items'] is List) return data['items'];
  return data is List ? data : [];
});

final feeDuesProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/school/fees/reports/dues');
  final data = res.data;
  if (data is Map && data['items'] is List) return data['items'];
  return data is List ? data : [];
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
                    if (payments.isEmpty) return const EmptyState(
                      icon: Icons.payment_outlined,
                      title: 'No Payments Recorded',
                      description: 'Fee payments will appear here once collected.',
                    );
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
                  loading: () => const LoadingWidget(),
                  error: (e, _) => CustomErrorWidget(
                    errorMessage: e.toString(),
                    onRetry: () => ref.invalidate(feePaymentsProvider),
                  ),
                ),
                duesAsync.when(
                  data: (dues) {
                    if (dues.isEmpty) return const EmptyState(
                      icon: Icons.check_circle_outline,
                      title: 'No Pending Dues',
                      description: 'All student fees have been paid.',
                    );
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
                  loading: () => const LoadingWidget(),
                  error: (e, _) => CustomErrorWidget(
                    errorMessage: e.toString(),
                    onRetry: () => ref.invalidate(feeDuesProvider),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCollectDialog(BuildContext context) {
    final searchCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();

    int step = 0;
    List<dynamic> searchResults = [];
    dynamic selectedStudent;
    List<dynamic> studentFees = [];
    dynamic selectedFee;
    String paymentMethod = 'cash';
    bool loading = false;
    String? error;
    String? receiptNumber;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(
            step == 4 ? 'Payment Successful' : 'Collect Fee',
            style: ApexTypography.sectionTitle,
          ),
          content: SizedBox(
            width: 480,
            child: step == 4
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ApexColors.successLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.check_circle, size: 48, color: ApexColors.success),
                      ),
                      const SizedBox(height: 16),
                      Text('Payment recorded successfully', style: ApexTypography.cardTitle),
                      const SizedBox(height: 8),
                      Text('Receipt: $receiptNumber', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
                      const SizedBox(height: 4),
                      Text('Amount: ₹${amountCtrl.text}', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600, color: ApexColors.success)),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: ['Search', 'Select Fee', 'Payment', 'Confirm'].asMap().entries.map((e) {
                          final isActive = e.key == step;
                          final isDone = e.key < step;
                          return Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: isActive ? ApexColors.primary600 : isDone ? ApexColors.success : ApexColors.neutral200,
                                    width: isActive ? 2 : 1,
                                  ),
                                ),
                              ),
                              child: Text(
                                '${e.key + 1}. ${e.value}',
                                textAlign: TextAlign.center,
                                style: ApexTypography.captionMedium.copyWith(
                                  color: isActive ? ApexColors.primary600 : isDone ? ApexColors.success : ApexColors.neutral500,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      if (error != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: ApexColors.errorLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(children: [
                            Icon(Icons.error_outline, size: 16, color: ApexColors.error),
                            const SizedBox(width: 8),
                            Expanded(child: Text(error!, style: ApexTypography.captionMedium.copyWith(color: ApexColors.error))),
                          ]),
                        ),
                      if (step == 0) ...[
                        TextField(
                          controller: searchCtrl,
                          decoration: InputDecoration(
                            labelText: 'Search by name or admission number',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.search, size: 18),
                              onPressed: () async {
                                final q = searchCtrl.text.trim();
                                if (q.isEmpty) return;
                                setS(() { loading = true; error = null; });
                                try {
                                  final dio = ref.read(dioProvider);
                                  final res = await dio.get('/school/students/', queryParameters: {'search': q, 'page_size': 20});
                                  setS(() {
                                    searchResults = res.data['items'] ?? [];
                                    loading = false;
                                    if (searchResults.isEmpty) error = 'No students found';
                                  });
                                } catch (e) {
                                  setS(() { loading = false; error = 'Search failed: $e'; });
                                }
                              },
                            ),
                          ),
                          onSubmitted: (_) async {
                            final q = searchCtrl.text.trim();
                            if (q.isEmpty) return;
                            setS(() { loading = true; error = null; });
                            try {
                              final dio = ref.read(dioProvider);
                              final res = await dio.get('/school/students/', queryParameters: {'search': q, 'page_size': 20});
                              setS(() {
                                searchResults = res.data['items'] ?? [];
                                loading = false;
                                if (searchResults.isEmpty) error = 'No students found';
                              });
                            } catch (e) {
                              setS(() { loading = false; error = 'Search failed: $e'; });
                            }
                          },
                        ),
                        if (loading) const Padding(padding: EdgeInsets.only(top: 16), child: CircularProgressIndicator()),
                        if (searchResults.isNotEmpty)
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: ApexColors.neutral200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: searchResults.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: ApexColors.neutral100),
                              itemBuilder: (_, i) {
                                final s = searchResults[i];
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: ApexColors.primary50,
                                    child: Text(
                                      (s['first_name'] ?? '?')[0].toUpperCase(),
                                      style: ApexTypography.captionMedium.copyWith(color: ApexColors.primary600),
                                    ),
                                  ),
                                  title: Text('${s['first_name'] ?? ''} ${s['last_name'] ?? ''}', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w500)),
                                  subtitle: Text('Adm: ${s['admission_number'] ?? '-'}', style: ApexTypography.captionSmall),
                                  onTap: () async {
                                    selectedStudent = s;
                                    setS(() { loading = true; error = null; });
                                    try {
                                      final dio = ref.read(dioProvider);
                                      final res = await dio.get('/school/fees/students/${s['id']}');
                                      final allFees = res.data is List ? res.data : [];
                                      studentFees = allFees.where((f) => f['status'] != 'paid' && f['status'] != 'waived').toList();
                                      setS(() {
                                        loading = false;
                                        if (studentFees.isEmpty) {
                                          error = 'No outstanding fees for this student';
                                        } else {
                                          step = 1;
                                        }
                                      });
                                    } catch (e) {
                                      setS(() { loading = false; error = 'Failed to load fees: $e'; });
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                      if (step == 1) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${selectedStudent['first_name']} ${selectedStudent['last_name']} • ${selectedStudent['admission_number']}',
                            style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (loading) const CircularProgressIndicator(),
                        if (!loading)
                          Container(
                            constraints: const BoxConstraints(maxHeight: 250),
                            decoration: BoxDecoration(
                              border: Border.all(color: ApexColors.neutral200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: studentFees.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: ApexColors.neutral100),
                              itemBuilder: (_, i) {
                                final f = studentFees[i];
                                final isSelected = selectedFee == f;
                                final status = f['status'] ?? 'pending';
                                return ListTile(
                                  dense: true,
                                  selected: isSelected,
                                  selectedTileColor: ApexColors.primary50,
                                  leading: Icon(
                                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                    color: isSelected ? ApexColors.primary600 : ApexColors.neutral400,
                                    size: 20,
                                  ),
                                  title: Text('₹${f['final_amount'] ?? 0}', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600)),
                                  subtitle: Text(
                                    'Due: ${f['due_date'] ?? '-'} • ${f['discount_amount'] != null && f['discount_amount'] > 0 ? 'Discount: ₹${f['discount_amount']} • ' : ''}Status: $status',
                                    style: ApexTypography.captionSmall,
                                  ),
                                  trailing: ApexBadge(
                                    label: status,
                                    type: status == 'partial' ? ApexBadgeType.warning : ApexBadgeType.danger,
                                  ),
                                  onTap: () => setS(() {
                                    selectedFee = f;
                                    amountCtrl.text = (f['final_amount'] ?? 0).toString();
                                  }),
                                );
                              },
                            ),
                          ),
                      ],
                      if (step == 2) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${selectedStudent['first_name']} ${selectedStudent['last_name']} • Fee: ₹${selectedFee['final_amount']}',
                            style: ApexTypography.body.copyWith(fontWeight: FontWeight.w500, color: ApexColors.neutral600),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: amountCtrl,
                          decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: paymentMethod,
                          decoration: const InputDecoration(labelText: 'Payment Method'),
                          items: const [
                            DropdownMenuItem(value: 'cash', child: Text('Cash')),
                            DropdownMenuItem(value: 'card', child: Text('Card')),
                            DropdownMenuItem(value: 'upi', child: Text('UPI')),
                            DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                            DropdownMenuItem(value: 'neft', child: Text('NEFT')),
                            DropdownMenuItem(value: 'online', child: Text('Online')),
                          ],
                          onChanged: (v) => setS(() { if (v != null) paymentMethod = v; }),
                        ),
                        if (paymentMethod != 'cash') ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: refCtrl,
                            decoration: InputDecoration(
                              labelText: paymentMethod == 'cheque' ? 'Cheque Number' : 'Reference / Transaction ID',
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        TextField(
                          controller: remarksCtrl,
                          decoration: const InputDecoration(labelText: 'Remarks (optional)'),
                          maxLines: 2,
                        ),
                      ],
                      if (step == 3) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ApexColors.neutral50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ApexColors.neutral200),
                          ),
                          child: Column(
                            children: [
                              _confirmRow('Student', '${selectedStudent['first_name']} ${selectedStudent['last_name']}'),
                              _confirmRow('Admission No', selectedStudent['admission_number'] ?? '-'),
                              _confirmRow('Fee Amount', '₹${selectedFee['final_amount']}'),
                              const Divider(),
                              _confirmRow('Paying', '₹${amountCtrl.text}', highlight: true),
                              _confirmRow('Method', paymentMethod.toUpperCase()),
                              if (refCtrl.text.isNotEmpty) _confirmRow('Reference', refCtrl.text),
                              if (remarksCtrl.text.isNotEmpty) _confirmRow('Remarks', remarksCtrl.text),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          actions: [
            if (step < 4)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            if (step == 0)
              TextButton(
                onPressed: searchResults.isNotEmpty
                    ? () => setS(() { searchResults = []; searchCtrl.clear(); error = null; })
                    : null,
                child: const Text('Clear'),
              ),
            if (step == 1)
              TextButton(
                onPressed: () => setS(() { step = 0; selectedStudent = null; studentFees = []; selectedFee = null; error = null; }),
                child: const Text('Back'),
              ),
            if (step == 1)
              ElevatedButton(
                onPressed: selectedFee != null ? () => setS(() { step = 2; error = null; }) : null,
                style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white),
                child: const Text('Next'),
              ),
            if (step == 2) ...[
              TextButton(
                onPressed: () => setS(() { step = 1; error = null; }),
                child: const Text('Back'),
              ),
              ElevatedButton(
                onPressed: () {
                  final amt = double.tryParse(amountCtrl.text);
                  if (amt == null || amt <= 0) {
                    setS(() { error = 'Enter a valid amount'; });
                    return;
                  }
                  setS(() { step = 3; error = null; });
                },
                style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white),
                child: const Text('Review'),
              ),
            ],
            if (step == 3) ...[
              TextButton(
                onPressed: () => setS(() { step = 2; error = null; }),
                child: const Text('Back'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  setS(() { loading = true; error = null; });
                  try {
                    final dio = ref.read(dioProvider);
                    final res = await dio.post('/school/fees/payments', data: {
                      'student_id': selectedStudent['id'],
                      'student_fee_id': selectedFee['id'],
                      'amount': double.parse(amountCtrl.text),
                      'payment_date': DateTime.now().toIso8601String().split('T')[0],
                      'payment_method': paymentMethod,
                      'reference_number': refCtrl.text.isNotEmpty ? refCtrl.text : null,
                      'remarks': remarksCtrl.text.isNotEmpty ? remarksCtrl.text : null,
                    });
                    receiptNumber = res.data['receipt_number'] ?? '-';
                    setS(() { loading = false; step = 4; });
                    ref.invalidate(feePaymentsProvider);
                    ref.invalidate(feeDuesProvider);
                  } catch (e) {
                    setS(() { loading = false; error = 'Payment failed: $e'; });
                  }
                },
                icon: loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.payment, size: 16),
                label: Text(loading ? 'Processing...' : 'Confirm Payment'),
                style: ElevatedButton.styleFrom(backgroundColor: ApexColors.success, foregroundColor: Colors.white),
              ),
            ],
            if (step == 4)
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white),
                child: const Text('Done'),
              ),
          ],
        ),
      ),
    );
  }

  static Widget _confirmRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
          Text(value, style: ApexTypography.body.copyWith(
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            color: highlight ? ApexColors.success : ApexColors.neutral800,
          )),
        ],
      ),
    );
  }
}
