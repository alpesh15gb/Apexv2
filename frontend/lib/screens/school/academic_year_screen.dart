import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_badge.dart';

final academicYearsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/school/academic-years/');
  return res.data is List ? res.data : [];
});

class AcademicYearScreen extends ConsumerWidget {
  const AcademicYearScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearsAsync = ref.watch(academicYearsProvider);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: ApexColors.neutral0,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Academic Years', style: ApexTypography.pageTitle.copyWith(color: ApexColors.neutral900)),
                      const SizedBox(height: 4),
                      Text('Manage academic sessions and terms', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateDialog(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Academic Year'),
                  style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: yearsAsync.when(
              data: (years) {
                if (years.isEmpty) return Center(child: Text('No academic years', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: years.length,
                  itemBuilder: (context, i) {
                    final y = years[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(y['name'] ?? '', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600)),
                          Text('${y['start_date']} to ${y['end_date']}', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
                        ])),
                        ApexBadge(
                          label: y['status'] ?? 'planning',
                          type: y['is_current'] == true ? ApexBadgeType.success : y['status'] == 'active' ? ApexBadgeType.info : ApexBadgeType.neutral,
                        ),
                        const SizedBox(width: 8),
                        if (y['is_current'] != true)
                          TextButton(
                            onPressed: () => _setCurrent(ref, y['id']),
                            child: const Text('Set Current'),
                          ),
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
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Academic Year'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name (e.g. 2025-2026)')),
          const SizedBox(height: 8),
          TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start Date (YYYY-MM-DD)')),
          const SizedBox(height: 8),
          TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End Date (YYYY-MM-DD)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final dio = ref.read(dioProvider);
              await dio.post('/school/academic-years/', data: {
                'name': nameCtrl.text,
                'start_date': startCtrl.text,
                'end_date': endCtrl.text,
              });
              Navigator.pop(ctx);
              ref.invalidate(academicYearsProvider);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _setCurrent(WidgetRef ref, String id) async {
    final dio = ref.read(dioProvider);
    await dio.post('/school/academic-years/$id/set-current');
    ref.invalidate(academicYearsProvider);
  }
}
