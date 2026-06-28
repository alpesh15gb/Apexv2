import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';

final homeworkListProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/school/homework/');
  return res.data is List ? res.data : [];
});

class HomeworkScreen extends ConsumerWidget {
  const HomeworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeworkAsync = ref.watch(homeworkListProvider);

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
                      Text('Homework', style: ApexTypography.pageTitle.copyWith(color: ApexColors.neutral900)),
                      const SizedBox(height: 4),
                      Text('Create and manage homework assignments', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateDialog(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create Homework'),
                  style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: homeworkAsync.when(
              data: (items) {
                if (items.isEmpty) return const EmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'No Homework Assigned',
                  description: 'Create homework assignments for your students.',
                  actionLabel: 'Create Homework',
                  onActionPressed: null,
                );
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final h = items[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(Icons.assignment, size: 20, color: ApexColors.primary600),
                          const SizedBox(width: 8),
                          Expanded(child: Text(h['title'] ?? '', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600))),
                        ]),
                        if (h['description'] != null) ...[
                          const SizedBox(height: 8),
                          Text(h['description'], style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral600)),
                        ],
                        const SizedBox(height: 8),
                        Row(children: [
                          Icon(Icons.calendar_today, size: 14, color: ApexColors.neutral500),
                          const SizedBox(width: 4),
                          Text('Due: ${h['due_date'] ?? '-'}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                        ]),
                      ]),
                    );
                  },
                );
              },
              loading: () => const LoadingWidget(),
              error: (e, _) => CustomErrorWidget(
                errorMessage: e.toString(),
                onRetry: () => ref.invalidate(homeworkListProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final dueCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Homework'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 8),
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
          const SizedBox(height: 8),
          TextField(controller: dueCtrl, decoration: const InputDecoration(labelText: 'Due Date (YYYY-MM-DD)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              // TODO: need section_id and subject_id selectors
              Navigator.pop(ctx);
              ref.invalidate(homeworkListProvider);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
