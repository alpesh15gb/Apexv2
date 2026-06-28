import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../core/dio_client.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_text_field.dart';
import '../../widgets/apex_dropdown.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/apex_badge.dart';

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

ApexBadgeType _statusBadge(String status) {
  switch (status) {
    case 'approved': return ApexBadgeType.success;
    case 'rejected': return ApexBadgeType.danger;
    case 'submitted': return ApexBadgeType.warning;
    default: return ApexBadgeType.neutral;
  }
}

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
      backgroundColor: ApexColors.neutral50,
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
                  Icon(Icons.receipt_long_outlined, size: 48, color: ApexColors.neutral400),
                  const SizedBox(height: 12),
                  Text('No Expense Claims', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral900)),
                  const SizedBox(height: 4),
                  Text('Submit an expense claim to get started', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final claim = items[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ApexCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: ApexColors.primary600.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.receipt, color: ApexColors.primary600, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(claim.categoryName ?? 'Expense', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral900)),
                            Text('${claim.date}  •  ₹${claim.amount.toStringAsFixed(0)}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                          ],
                        ),
                      ),
                      ApexBadge(label: claim.status, type: _statusBadge(claim.status)),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: ${e.toString()}', style: TextStyle(color: ApexColors.error))),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedCategory = 'Travel';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('New Expense Claim', style: ApexTypography.sectionTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ApexDropdown<String>(
              label: 'Category',
              value: selectedCategory,
              items: ['Travel', 'Food', 'Accommodation', 'Transport', 'Office Supplies', 'Other']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => selectedCategory = v ?? selectedCategory,
            ),
            const SizedBox(height: 12),
            ApexTextField(
              label: 'Amount (₹)',
              controller: amountCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            ApexTextField(
              label: 'Description',
              controller: descCtrl,
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          ApexButton(label: 'Cancel', type: ApexButtonType.ghost, onPressed: () => Navigator.pop(ctx)),
          ApexButton(
            label: 'Submit',
            onPressed: () async {
              try {
                final dio = ref.read(dioProvider);
                await dio.post('/finance/expense-claims', data: {
                  'amount': double.tryParse(amountCtrl.text) ?? 0,
                  'date': DateTime.now().toIso8601String().substring(0, 10),
                  'description': descCtrl.text.trim(),
                });
                Navigator.pop(ctx);
                ref.invalidate(expenseListProvider);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: ApexColors.error));
              }
            },
          ),
        ],
      ),
    );
  }
}
