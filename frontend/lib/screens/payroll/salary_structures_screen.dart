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
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

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
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        title: const Text('Salary Structures', style: TextStyle(fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/payroll')),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showCreateDialog(context, ref),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Structure'),
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
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
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: _danger))),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance, size: 64, color: _muted.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No Salary Structures', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _text)),
          const SizedBox(height: 8),
          const Text('Create salary templates for your organization', style: TextStyle(fontSize: 13, color: _muted)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Create Structure'),
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
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
              const Text('Earnings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
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
          ElevatedButton(
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salary structure created'), backgroundColor: _success));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: _danger));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
            child: const Text('Create'),
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
              decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.account_balance, size: 20, color: _primary),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _text)),
              Text('Effective: ${structure['effective_from'] ?? '—'}', style: const TextStyle(fontSize: 12, color: _muted)),
            ])),
            Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _success)),
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
    );
  }

  Widget _componentChip(String label, dynamic amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(6)),
      child: Text('$label: ₹${(amount as num).toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: _text)),
    );
  }
}
