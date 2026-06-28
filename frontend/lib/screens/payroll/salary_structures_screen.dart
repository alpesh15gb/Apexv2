import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';
import '../../design_system/typography.dart';
import '../../design_system/colors.dart';


final salaryStructuresProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/payroll/salary-structures', queryParameters: {'page': 1, 'page_size': 100});
    return res.data['items'] ?? (res.data is List ? res.data : []);
  } catch (e) {
    return [];
  }
});

class SalaryStructuresScreen extends ConsumerWidget {
  const SalaryStructuresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final structuresAsync = ref.watch(salaryStructuresProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        title: Text('Salary Structures', style: ApexTypography.sectionTitle),
        backgroundColor: Colors.white,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: ApexColors.neutral200)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/payroll')),
        actions: [
          ApexButton(
            label: 'New Structure',
            icon: Icons.add,
            onPressed: () => _showCreateDialog(context, ref),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: structuresAsync.when(
        data: (structures) {
          if (structures.isEmpty) return _buildEmptyState(context, ref);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: structures.length,
            itemBuilder: (context, i) => _StructureCard(structure: structures[i], ref: ref),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: ApexTypography.body.copyWith(color: ApexColors.error))),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance, size: 64, color: ApexColors.neutral500.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No Salary Structures', style: ApexTypography.sectionTitle),
          const SizedBox(height: 8),
          Text('Create salary templates for your organization', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
          const SizedBox(height: 24),
          ApexButton(
            label: 'Create Structure',
            icon: Icons.add,
            onPressed: () => _showCreateDialog(context, ref),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final basicCtrl = TextEditingController(text: '0');
    final hraCtrl = TextEditingController(text: '0');
    final daCtrl = TextEditingController(text: '0');
    final conveyanceCtrl = TextEditingController(text: '0');
    final medicalCtrl = TextEditingController(text: '0');
    final specialCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Salary Structure'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Structure Name *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Text('Earnings', style: ApexTypography.cardTitle.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: basicCtrl, decoration: const InputDecoration(labelText: 'Basic', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: hraCtrl, decoration: const InputDecoration(labelText: 'HRA', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: daCtrl, decoration: const InputDecoration(labelText: 'DA', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: conveyanceCtrl, decoration: const InputDecoration(labelText: 'Conveyance', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: medicalCtrl, decoration: const InputDecoration(labelText: 'Medical', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: specialCtrl, decoration: const InputDecoration(labelText: 'Special', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              ]),
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
                await dio.post('/payroll/salary-structures', data: {
                  'name': nameCtrl.text.trim(),
                  'basic': double.tryParse(basicCtrl.text) ?? 0,
                  'hra': double.tryParse(hraCtrl.text) ?? 0,
                  'da': double.tryParse(daCtrl.text) ?? 0,
                  'conveyance': double.tryParse(conveyanceCtrl.text) ?? 0,
                  'medical': double.tryParse(medicalCtrl.text) ?? 0,
                  'special': double.tryParse(specialCtrl.text) ?? 0,
                  'effective_from': DateTime.now().toIso8601String().substring(0, 10),
                });
                Navigator.pop(ctx);
                ref.invalidate(salaryStructuresProvider);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salary structure created'), backgroundColor: ApexColors.success));
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

class _StructureCard extends StatelessWidget {
  final Map<String, dynamic> structure;
  final WidgetRef ref;

  const _StructureCard({required this.structure, required this.ref});

  @override
  Widget build(BuildContext context) {
    final name = structure['name'] ?? structure['employee_name'] ?? 'Structure';
    final basic = structure['basic'] ?? 0;
    final hra = structure['hra'] ?? 0;
    final da = structure['da'] ?? 0;
    final total = (basic as num) + (hra as num) + (da as num);

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
              decoration: BoxDecoration(color: ApexColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.account_balance, size: 20, color: ApexColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: ApexTypography.cardTitle.copyWith(fontSize: 15)),
              Text('Effective: ${structure['effective_from'] ?? '—'}', style: ApexTypography.captionSmall),
            ])),
            Text('₹${total.toStringAsFixed(0)}', style: ApexTypography.sectionTitle.copyWith(color: ApexColors.success)),
          ]),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _componentChip('Basic', basic),
              _componentChip('HRA', hra),
              _componentChip('DA', da),
              if (structure['conveyance'] != null && structure['conveyance'] > 0) _componentChip('Conveyance', structure['conveyance']),
              if (structure['medical'] != null && structure['medical'] > 0) _componentChip('Medical', structure['medical']),
              if (structure['special'] != null && structure['special'] > 0) _componentChip('Special', structure['special']),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _componentChip(String label, dynamic amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: ApexColors.neutral50, borderRadius: BorderRadius.circular(6)),
      child: Text('$label: ₹${(amount as num).toStringAsFixed(0)}', style: ApexTypography.captionMedium),
    );
  }
}





