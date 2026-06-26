import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../widgets/apex_app_bar.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _warning = Color(0xFFF59E0B);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

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
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        title: const Text('Loans & Advances', style: TextStyle(fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/payroll')),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showCreateDialog(context, ref),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Loan'),
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
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
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: _danger))),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.money, size: 64, color: _muted.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No Loans or Advances', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _text)),
          const SizedBox(height: 8),
          const Text('Employee loans and salary advances will appear here', style: TextStyle(fontSize: 13, color: _muted)),
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
            ElevatedButton(
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loan created'), backgroundColor: _success));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: _danger));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
              child: const Text('Create'),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _warning.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.money, size: 20, color: _warning),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_loanTypeName(type), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _text)),
              Text('Started: ${loan['start_date'] ?? '—'}', style: const TextStyle(fontSize: 12, color: _muted)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _text)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(status))),
              ),
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
            backgroundColor: _border,
            color: _success,
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: _muted)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text)),
      ],
    );
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

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return _success;
      case 'closed': return _muted;
      case 'defaulted': return _danger;
      default: return _muted;
    }
  }
}
