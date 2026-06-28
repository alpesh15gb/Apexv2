import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';

final examsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/school/exams');
  return res.data is List ? res.data : [];
});

class ExamListScreen extends ConsumerWidget {
  const ExamListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(examsProvider);

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
                      Text('Examinations', style: ApexTypography.pageTitle.copyWith(color: ApexColors.neutral900)),
                      const SizedBox(height: 4),
                      Text('Manage exams, schedules, and marks entry', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateDialog(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create Exam'),
                  style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: examsAsync.when(
              data: (exams) {
                if (exams.isEmpty) return const EmptyState(
                  icon: Icons.quiz_outlined,
                  title: 'No Exams Created',
                  description: 'Create exams to manage schedules and marks entry.',
                  actionLabel: 'Create Exam',
                  onActionPressed: null,
                );
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: exams.length,
                  itemBuilder: (context, i) {
                    final e = exams[i];
                    final status = e['status'] ?? 'draft';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e['name'] ?? '', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600)),
                          Text('${e['start_date']} to ${e['end_date']}', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
                        ])),
                        ApexBadge(
                          label: status,
                          type: status == 'results_published' ? ApexBadgeType.success : status == 'completed' ? ApexBadgeType.info : ApexBadgeType.neutral,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.edit, size: 16, color: ApexColors.neutral500),
                          onPressed: () => context.go('/school/exams'),
                        ),
                      ]),
                    );
                  },
                );
              },
              loading: () => const LoadingWidget(),
              error: (e, _) => CustomErrorWidget(
                errorMessage: e.toString(),
                onRetry: () => ref.invalidate(examsProvider),
              ),
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
        title: const Text('Create Exam'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Exam Name')),
          const SizedBox(height: 8),
          TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start Date (YYYY-MM-DD)')),
          const SizedBox(height: 8),
          TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End Date (YYYY-MM-DD)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              // TODO: need exam_type_id and academic_year_id selectors
              Navigator.pop(ctx);
              ref.invalidate(examsProvider);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
