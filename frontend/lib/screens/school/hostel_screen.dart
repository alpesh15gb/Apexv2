import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';

final hostelsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/school/hostel/');
  return res.data is List ? res.data : [];
});

class HostelScreen extends ConsumerWidget {
  const HostelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hostelsAsync = ref.watch(hostelsProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: ApexColors.neutral0,
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hostel', style: ApexTypography.pageTitle.copyWith(color: ApexColors.neutral900)),
                const SizedBox(height: 4),
                Text('Manage hostels, rooms, and allocations', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
              ])),
              ElevatedButton.icon(
                onPressed: () => _showCreateDialog(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Hostel'),
                style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white),
              ),
            ]),
          ),
          Expanded(
            child: hostelsAsync.when(
              data: (hostels) {
                if (hostels.isEmpty) return Center(child: Text('No hostels configured', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: hostels.length,
                  itemBuilder: (context, i) {
                    final h = hostels[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: ApexColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.home_work, color: ApexColors.warning),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(h['name'] ?? '', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600)),
                          Text('${h['hostel_type'] ?? ''} • Capacity: ${h['capacity'] ?? 0}', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
                        ])),
                      ]),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '100');
    String type = 'boys';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Hostel'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Hostel Name')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'boys', child: Text('Boys')),
                DropdownMenuItem(value: 'girls', child: Text('Girls')),
                DropdownMenuItem(value: 'staff', child: Text('Staff')),
              ],
              onChanged: (v) => setDialogState(() => type = v ?? 'boys'),
            ),
            const SizedBox(height: 8),
            TextField(controller: capacityCtrl, decoration: const InputDecoration(labelText: 'Capacity'), keyboardType: TextInputType.number),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final dio = ref.read(dioProvider);
                await dio.post('/school/hostel/', data: {'name': nameCtrl.text, 'hostel_type': type, 'capacity': int.tryParse(capacityCtrl.text) ?? 100});
                Navigator.pop(ctx);
                ref.invalidate(hostelsProvider);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
