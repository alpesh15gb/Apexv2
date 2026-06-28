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

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  String? _selectedSectionId;
  List<dynamic> _timetable = [];
  bool _loading = false;

  static const _days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  Future<void> _loadTimetable(String sectionId) async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/school/timetable/section/$sectionId');
      setState(() { _timetable = res.data is List ? res.data : []; _loading = false; });
    } catch (e) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final gradesAsync = ref.watch(gradesProvider);

    // Group timetable by day
    final Map<int, List<dynamic>> byDay = {};
    for (final entry in _timetable) {
      final day = entry['day_of_week'] as int;
      byDay.putIfAbsent(day, () => []).add(entry);
    }

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: ApexColors.neutral0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Timetable', style: ApexTypography.pageTitle.copyWith(color: ApexColors.neutral900)),
                const SizedBox(height: 16),
                gradesAsync.when(
                  data: (grades) => DropdownButtonFormField<String>(
                    value: _selectedSectionId,
                    decoration: const InputDecoration(labelText: 'Select Section', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    items: grades.expand<DropdownMenuItem<String>>((g) => [
                      DropdownMenuItem(value: null, child: Text(g['name'], style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600))),
                    ]).toList(),
                    onChanged: (v) {
                      setState(() => _selectedSectionId = v);
                      if (v != null) _loadTimetable(v);
                    },
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _timetable.isEmpty
                    ? Center(child: Text('Select a section to view timetable', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: List.generate(6, (dayIndex) {
                            final day = dayIndex + 1;
                            final entries = byDay[day] ?? [];
                            if (entries.isEmpty) return const SizedBox.shrink();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(color: ApexColors.primary600.withOpacity(0.05), borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
                                    child: Text(_days[day], style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600, color: ApexColors.primary600)),
                                  ),
                                  ...entries.map((e) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Row(children: [
                                      SizedBox(width: 80, child: Text('${e['start_time'] ?? ''}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500))),
                                      Expanded(child: Text(e['period_name'] ?? '', style: ApexTypography.caption.copyWith(fontWeight: FontWeight.w500))),
                                      if (e['subject_id'] != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: ApexColors.primary600.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                          child: Text('Subject', style: ApexTypography.captionSmall.copyWith(color: ApexColors.primary600)),
                                        ),
                                    ]),
                                  )),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
