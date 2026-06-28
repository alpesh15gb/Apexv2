import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';

final adminPlansProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/admin/plans/');
  return res.data is List ? res.data : [];
});

class AdminPlanScreen extends ConsumerWidget {
  const AdminPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(adminPlansProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        backgroundColor: ApexColors.neutral0,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        title: const Text('Subscription Plans', style: TextStyle(fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/admin/dashboard')),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showPlanDialog(context, ref, null),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Plan'),
            style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: plansAsync.when(
        data: (plans) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: plans.length,
          itemBuilder: (context, i) {
            final p = plans[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(12), border: Border.all(color: ApexColors.neutral200)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p['name'] ?? '', style: ApexTypography.cardTitle.copyWith(color: ApexColors.neutral900)),
                    Text(p['description'] ?? '', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: (p['is_active'] == true ? ApexColors.successDark : ApexColors.neutral500).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text(p['is_active'] == true ? 'ACTIVE' : 'INACTIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p['is_active'] == true ? ApexColors.successDark : ApexColors.neutral500)),
                  ),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  _priceCol('Monthly', '₹${p['price_monthly'] ?? 0}'),
                  _priceCol('Quarterly', '₹${p['price_quarterly'] ?? 0}'),
                  _priceCol('Annual', '₹${p['price_annual'] ?? 0}'),
                  _priceCol('Lifetime', '₹${p['price_lifetime'] ?? 0}'),
                ]),
                const SizedBox(height: 12),
                Wrap(spacing: 16, runSpacing: 8, children: [
                  _limitChip(Icons.people, '${p['max_employees']} employees'),
                  _limitChip(Icons.business, '${p['max_branches']} branches'),
                  _limitChip(Icons.device_hub, '${p['max_devices']} devices'),
                  _limitChip(Icons.storage, '${p['max_storage_mb']} MB'),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  TextButton.icon(onPressed: () => _showPlanDialog(context, ref, p), icon: const Icon(Icons.edit, size: 14), label: const Text('Edit')),
                  TextButton.icon(onPressed: () => _clonePlan(context, ref, p), icon: const Icon(Icons.copy, size: 14), label: const Text('Clone')),
                  TextButton.icon(
                    onPressed: () => _togglePlan(context, ref, p),
                    icon: Icon(p['is_active'] == true ? Icons.archive : Icons.unarchive, size: 14),
                    label: Text(p['is_active'] == true ? 'Archive' : 'Activate'),
                  ),
                ]),
              ]),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _priceCol(String label, String price) {
    return Expanded(child: Column(children: [
      Text(label, style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
      const SizedBox(height: 4),
      Text(price, style: ApexTypography.cardTitle.copyWith(color: ApexColors.neutral900)),
    ]));
  }

  Widget _limitChip(IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: ApexColors.neutral500),
      const SizedBox(width: 4),
      Text(label, style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
    ]);
  }

  void _showPlanDialog(BuildContext context, WidgetRef ref, Map<String, dynamic>? existing) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final codeCtrl = TextEditingController(text: existing?['code'] ?? '');
    final monthlyCtrl = TextEditingController(text: '${existing?['price_monthly'] ?? 0}');
    final annualCtrl = TextEditingController(text: '${existing?['price_annual'] ?? 0}');
    final empCtrl = TextEditingController(text: '${existing?['max_employees'] ?? 50}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing != null ? 'Edit Plan' : 'New Plan'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Plan Name')),
          const SizedBox(height: 8),
          TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code'), enabled: existing == null),
          const SizedBox(height: 8),
          TextField(controller: monthlyCtrl, decoration: const InputDecoration(labelText: 'Monthly Price'), keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          TextField(controller: annualCtrl, decoration: const InputDecoration(labelText: 'Annual Price'), keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          TextField(controller: empCtrl, decoration: const InputDecoration(labelText: 'Max Employees'), keyboardType: TextInputType.number),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final dio = ref.read(dioProvider);
              final data = {
                'name': nameCtrl.text,
                'code': codeCtrl.text,
                'price_monthly': double.tryParse(monthlyCtrl.text) ?? 0,
                'price_annual': double.tryParse(annualCtrl.text) ?? 0,
                'max_employees': int.tryParse(empCtrl.text) ?? 50,
              };
              if (existing != null) {
                await dio.put('/admin/plans/${existing['id']}', data: data);
              } else {
                await dio.post('/admin/plans/', data: data);
              }
              Navigator.pop(ctx);
              ref.invalidate(adminPlansProvider);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _clonePlan(BuildContext context, WidgetRef ref, Map<String, dynamic> plan) async {
    final dio = ref.read(dioProvider);
    await dio.post('/admin/plans/', data: {
      'name': '${plan['name']} (Copy)',
      'code': '${plan['code']}_copy',
      'price_monthly': plan['price_monthly'],
      'price_annual': plan['price_annual'],
      'max_employees': plan['max_employees'],
      'max_branches': plan['max_branches'],
      'max_devices': plan['max_devices'],
      'max_storage_mb': plan['max_storage_mb'],
      'features': plan['features'],
    });
    ref.invalidate(adminPlansProvider);
  }

  void _togglePlan(BuildContext context, WidgetRef ref, Map<String, dynamic> plan) async {
    final dio = ref.read(dioProvider);
    await dio.put('/admin/plans/${plan['id']}', data: {'is_active': plan['is_active'] != true});
    ref.invalidate(adminPlansProvider);
  }
}
