import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';

final gradesProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/school/grades');
  return res.data is List ? res.data : [];
});

class GradeSectionScreen extends ConsumerWidget {
  const GradeSectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradesAsync = ref.watch(gradesProvider);

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
                      Text('Classes & Sections', style: ApexTypography.pageTitle.copyWith(color: ApexColors.neutral900)),
                      const SizedBox(height: 4),
                      Text('Manage grades, sections, and class teachers', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateGradeDialog(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Grade'),
                  style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: gradesAsync.when(
              data: (grades) {
                if (grades.isEmpty) return Center(child: Text('No grades created', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: grades.length,
                  itemBuilder: (context, i) {
                    final g = grades[i];
                    return _GradeCard(grade: g);
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

  void _showCreateGradeDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Grade'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name (e.g. Class 10)')),
          const SizedBox(height: 8),
          TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code (e.g. 10)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final dio = ref.read(dioProvider);
              await dio.post('/school/grades', data: {'name': nameCtrl.text, 'code': codeCtrl.text});
              Navigator.pop(ctx);
              ref.invalidate(gradesProvider);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _GradeCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> grade;
  const _GradeCard({required this.grade});

  @override
  ConsumerState<_GradeCard> createState() => _GradeCardState();
}

class _GradeCardState extends ConsumerState<_GradeCard> {
  List<dynamic> _sections = [];
  bool _expanded = false;
  bool _loading = false;

  Future<void> _loadSections() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/school/grades/${widget.grade['id']}/sections');
      setState(() { _sections = res.data is List ? res.data : []; _loading = false; });
    } catch (e) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
      child: Column(children: [
        ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: ApexColors.primary600.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(widget.grade['code'] ?? '', style: ApexTypography.titleLarge.copyWith(color: ApexColors.primary600))),
          ),
          title: Text(widget.grade['name'] ?? '', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text('${_sections.length} sections', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              icon: Icon(Icons.add, size: 16, color: ApexColors.primary600),
              onPressed: () => _showAddSectionDialog(context),
            ),
            IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: ApexColors.neutral500),
              onPressed: () {
                setState(() => _expanded = !_expanded);
                if (_expanded && _sections.isEmpty) _loadSections();
              },
            ),
          ]),
        ),
        if (_expanded) ...[
          const Divider(height: 1),
          if (_loading)
            const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())
          else if (_sections.isEmpty)
            Padding(padding: const EdgeInsets.all(16), child: Text('No sections yet', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)))
          else
            ..._sections.map((s) => ListTile(
              dense: true,
              leading: const SizedBox(width: 16),
              title: Text('Section ${s['name']}', style: ApexTypography.caption.copyWith(fontWeight: FontWeight.w500)),
              subtitle: Text('Capacity: ${s['capacity'] ?? 40}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
            )),
        ],
      ]),
    );
  }

  void _showAddSectionDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '40');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Section to ${widget.grade['name']}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Section Name (e.g. A, B, C)')),
          const SizedBox(height: 8),
          TextField(controller: capacityCtrl, decoration: const InputDecoration(labelText: 'Capacity'), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final dio = ref.read(dioProvider);
              // TODO: need academic_year_id
              await dio.post('/school/grades/${widget.grade['id']}/sections', data: {
                'name': nameCtrl.text,
                'capacity': int.tryParse(capacityCtrl.text) ?? 40,
              });
              Navigator.pop(ctx);
              _loadSections();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
