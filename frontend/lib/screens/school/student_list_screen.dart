import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_badge.dart';

final studentListProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final dio = ref.read(dioProvider);
  final queryParams = <String, dynamic>{'page': params['page'] ?? 1, 'page_size': params['page_size'] ?? 50};
  if (params['grade_id'] != null) queryParams['grade_id'] = params['grade_id'];
  if (params['section_id'] != null) queryParams['section_id'] = params['section_id'];
  if (params['search'] != null && params['search'].isNotEmpty) queryParams['search'] = params['search'];
  final res = await dio.get('/school/students/', queryParameters: queryParams);
  return List<Map<String, dynamic>>.from(res.data['items'] ?? []);
});

class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key});

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  String _search = '';
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentListProvider({'page': _page, 'search': _search}));

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
                      Text('Students', style: ApexTypography.pageTitle.copyWith(color: ApexColors.neutral900)),
                      const SizedBox(height: 4),
                      Text('Manage student records', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search students...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ApexColors.neutral200)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (v) => setState(() { _search = v; _page = 1; }),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => context.go('/school/students/create'),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Student'),
                  style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: studentsAsync.when(
              data: (students) {
                if (students.isEmpty) {
                  return Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school, size: 64, color: ApexColors.neutral300),
                      const SizedBox(height: 16),
                      Text('No students found', style: ApexTypography.sectionTitle.copyWith(color: ApexColors.neutral500)),
                      const SizedBox(height: 8),
                      Text('Add your first student to get started', style: ApexTypography.body.copyWith(color: ApexColors.neutral400)),
                    ],
                  ));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final s = students[i];
                    final status = s['status'] ?? 'active';
                    return Container(
                      decoration: BoxDecoration(
                        color: ApexColors.neutral0,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: ApexColors.neutral200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: ApexColors.primary600.withOpacity(0.1),
                          child: Text(
                            (s['first_name'] ?? '?')[0].toUpperCase(),
                            style: ApexTypography.titleLarge.copyWith(color: ApexColors.primary600),
                          ),
                        ),
                        title: Text('${s['first_name'] ?? ''} ${s['last_name'] ?? ''}', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600)),
                        subtitle: Text('Adm: ${s['admission_number'] ?? ''} • Roll: ${s['roll_number'] ?? '-'} • ${s['gender'] ?? ''}', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ApexBadge(
                              label: status,
                              type: status == 'active' ? ApexBadgeType.success : status == 'transferred' ? ApexBadgeType.warning : ApexBadgeType.danger,
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.chevron_right, color: ApexColors.neutral400),
                          ],
                        ),
                        onTap: () => context.go('/school/students/${s['id']}'),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e', style: ApexTypography.body.copyWith(color: ApexColors.error))),
            ),
          ),
        ],
      ),
    );
  }
}
