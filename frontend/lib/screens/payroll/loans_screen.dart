import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';
import '../../design_system/typography.dart';
import '../../design_system/colors.dart';


final loansProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/payroll/loans', queryParameters: {'page': 1, 'page_size': 100});
    return res.data['items'] ?? (res.data is List ? res.data : []);
  } catch (e) {
    return [];
  }
});

class LoansScreen extends ConsumerWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(loansProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        title: Text('Loans & Advances', style: ApexTypography.sectionTitle),
        backgroundColor: Colors.white,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: ApexColors.neutral200)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/payroll')),
        actions: [
          ApexButton(
            label: 'New Loan',
            icon: Icons.add,
            onPressed: () => _showCreateDialog(context, ref),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: loansAsync.when(
        data: (loans) {
          if (loans.isEmpty) return _buildEmptyState(context);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: loans.length,
            itemBuilder: (context, i) => _LoanCard(loan: loans[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: ApexColors.error))),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.money, size: 64, color: ApexColors.neutral500.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No Loans or Advances', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ApexColors.neutral900)),
          const SizedBox(height: 8),
          Text('Employee loans and salary advances will appear here', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final amountCtrl = TextEditingController();
    final emiCtrl = TextEditingController();
    final installmentsCtrl = TextEditingController(text: '12');
    String loanType = 'personal';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Loan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: loanType,
                  decoration: const InputDecoration(labelText: 'Loan Type', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'personal', child: Text('Personal Loan')),
                    DropdownMenuItem(value: 'salary_advance', child: Text('Salary Advance')),
                    DropdownMenuItem(value: 'housing', child: Text('Housing Loan')),
                    DropdownMenuItem(value: 'vehicle', child: Text('Vehicle Loan')),
                    DropdownMenuItem(value: 'education', child: Text('Education Loan')),
                  ],
                  onChanged: (v) => setDialogState(() => loanType = v!),
                ),
                const SizedBox(height: 12),
                TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Loan Amount *', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: emiCtrl, decoration: const InputDecoration(labelText: 'EMI Amount *', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: installmentsCtrl, decoration: const InputDecoration(labelText: 'Total Installments', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ApexButton(
              label: 'Create',
              onPressed: () async {
                try {
                  final dio = ref.read(dioProvider);
                  await dio.post('/payroll/loans', data: {
                    'loan_type': loanType,
                    'amount': double.tryParse(amountCtrl.text) ?? 0,
                    'emi_amount': double.tryParse(emiCtrl.text) ?? 0,
                    'start_date': DateTime.now().toIso8601String().substring(0, 10),
                    'total_installments': int.tryParse(installmentsCtrl.text) ?? 12,
                  });
                  Navigator.pop(ctx);
                  ref.invalidate(loansProvider);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loan created'), backgroundColor: ApexColors.success));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: ApexColors.error));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final Map<String, dynamic> loan;
  const _LoanCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    final type = loan['loan_type'] ?? 'Loan';
    final amount = (loan['amount'] as num?)?.toDouble() ?? 0;
    final emi = (loan['emi_amount'] as num?)?.toDouble() ?? 0;
    final paid = loan['paid_installments'] ?? 0;
    final total = loan['total_installments'] ?? 0;
    final status = loan['status'] ?? 'active';
    final outstanding = amount - (emi * paid);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ApexCard(
        padding: const EdgeInsets.all(18),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: ApexColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.money, size: 20, color: ApexColors.warning),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_loanTypeName(type), style: ApexTypography.cardTitle.copyWith(fontSize: 15)),
              Text('Started: ${loan['start_date'] ?? '—'}', style: ApexTypography.captionSmall),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('₹${amount.toStringAsFixed(0)}', style: ApexTypography.sectionTitle),
              _statusBadge(status),
            ]),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            _infoItem('EMI', '₹${emi.toStringAsFixed(0)}/mo'),
            const SizedBox(width: 24),
            _infoItem('Paid', '$paid/$total installments'),
            const SizedBox(width: 24),
            _infoItem('Outstanding', '₹${outstanding.toStringAsFixed(0)}'),
          ]),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: total > 0 ? paid / total : 0,
            backgroundColor: ApexColors.neutral200,
            color: ApexColors.success,
            minHeight: 6,
          ),
        ],
      ),
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ApexTypography.captionSmall),
        Text(value, style: ApexTypography.titleMedium),
      ],
    );
  }

  Widget _statusBadge(String status) {
    ApexBadgeType type;
    switch (status) {
      case 'active': type = ApexBadgeType.success; break;
      case 'closed': type = ApexBadgeType.neutral; break;
      case 'defaulted': type = ApexBadgeType.danger; break;
      default: type = ApexBadgeType.neutral;
    }
    return ApexBadge(label: status, type: type);
  }

  String _loanTypeName(String type) {
    switch (type) {
      case 'personal': return 'Personal Loan';
      case 'salary_advance': return 'Salary Advance';
      case 'housing': return 'Housing Loan';
      case 'vehicle': return 'Vehicle Loan';
      case 'education': return 'Education Loan';
      default: return type;
    }
  }

}





