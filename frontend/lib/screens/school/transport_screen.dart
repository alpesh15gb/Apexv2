import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';

final routesProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/school/transport/routes');
  return res.data is List ? res.data : [];
});

class TransportScreen extends ConsumerWidget {
  const TransportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(routesProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: ApexColors.neutral0,
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Transport', style: ApexTypography.pageTitle.copyWith(color: ApexColors.neutral900)),
                const SizedBox(height: 4),
                Text('Manage routes, vehicles, and student transport', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
              ])),
              ElevatedButton.icon(
                onPressed: () => _showCreateRouteDialog(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Route'),
                style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white),
              ),
            ]),
          ),
          Expanded(
            child: routesAsync.when(
              data: (routes) {
                if (routes.isEmpty) return Center(child: Text('No transport routes', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: routes.length,
                  itemBuilder: (context, i) {
                    final r = routes[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: ApexColors.primary600.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.directions_bus, color: ApexColors.primary600),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(r['name'] ?? '', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600)),
                          Text('${r['vehicle_number'] ?? '-'} • ${r['vehicle_type'] ?? ''} • Capacity: ${r['capacity'] ?? 0}', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
                        ])),
                        Icon(Icons.chevron_right, color: ApexColors.neutral400),
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

  void _showCreateRouteDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final vehicleCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '40');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Transport Route'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Route Name')),
          const SizedBox(height: 8),
          TextField(controller: vehicleCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number')),
          const SizedBox(height: 8),
          TextField(controller: capacityCtrl, decoration: const InputDecoration(labelText: 'Capacity'), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final dio = ref.read(dioProvider);
              await dio.post('/school/transport/routes', data: {
                'name': nameCtrl.text, 'vehicle_number': vehicleCtrl.text, 'capacity': int.tryParse(capacityCtrl.text) ?? 40,
              });
              Navigator.pop(ctx);
              ref.invalidate(routesProvider);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
