import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

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

class ExpenseClaim {
  final String id;
  final String? employeeId;
  final String? categoryName;
  final double amount;
  final String date;
  final String? description;
  final String status;

  ExpenseClaim({required this.id, this.employeeId, this.categoryName, required this.amount, required this.date, this.description, this.status = 'draft'});

  factory ExpenseClaim.fromJson(Map<String, dynamic> json) => ExpenseClaim(
    id: json['id'] as String,
    employeeId: json['employee_id'] as String?,
    categoryName: json['category_name'] as String?,
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    date: json['date'] as String? ?? '',
    description: json['description'] as String?,
    status: json['status'] as String? ?? 'draft',
  );
}

final expenseListProvider = FutureProvider<List<ExpenseClaim>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/finance/expense-claims');
  final data = res.data;
  if (data is List) return data.map((e) => ExpenseClaim.fromJson(e)).toList();
  return [];
});

class ExpenseScreen extends ConsumerStatefulWidget {
  const ExpenseScreen({super.key});

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  @override
  Widget build(BuildContext context) {
    final claimsAsync = ref.watch(expenseListProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: ApexAppBar(
        title: 'Expenses',
        actions: [
          IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => _showCreateDialog(context)),
        ],
      ),
      body: claimsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: _muted.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  const Text('No Expense Claims', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
                  const SizedBox(height: 4),
                  const Text('Submit an expense claim to get started', style: TextStyle(fontSize: 13, color: _muted)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final claim = items[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.receipt, color: _primary, size: 20),
                  ),
                  title: Text(claim.categoryName ?? 'Expense', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
                  subtitle: Text('${claim.date}  •  ₹${claim.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: _muted)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(claim.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(claim.status.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(claim.status))),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: ${e.toString()}', style: const TextStyle(color: _danger))),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved': return _success;
      case 'rejected': return _danger;
      case 'submitted': return _warning;
      default: return _muted;
    }
  }

  void _showCreateDialog(BuildContext context) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedCategory = 'Travel';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Expense Claim', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: ['Travel', 'Food', 'Accommodation', 'Transport', 'Office Supplies', 'Other']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => selectedCategory = v ?? selectedCategory,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amountCtrl,
              decoration: InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descCtrl,
              decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final dio = context.read(dioProvider);
                await dio.post('/finance/expense-claims', data: {
                  'amount': double.tryParse(amountCtrl.text) ?? 0,
                  'date': DateTime.now().toIso8601String().substring(0, 10),
                  'description': descCtrl.text.trim(),
                });
                Navigator.pop(ctx);
                ref.invalidate(expenseListProvider);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: _danger));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
