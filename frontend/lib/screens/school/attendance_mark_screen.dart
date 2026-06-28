import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';

final gradesProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/school/grades');
  return res.data is List ? res.data : [];
});

final sectionsProvider = FutureProvider.family<List<dynamic>, String>((ref, gradeId) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/school/grades/$gradeId/sections');
  return res.data is List ? res.data : [];
});

final sectionStudentsProvider = FutureProvider.family<List<dynamic>, String>((ref, sectionId) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/school/sections/$sectionId/students');
  return res.data is List ? res.data : [];
});

class AttendanceMarkScreen extends ConsumerStatefulWidget {
  const AttendanceMarkScreen({super.key});

  @override
  ConsumerState<AttendanceMarkScreen> createState() => _AttendanceMarkScreenState();
}

class _AttendanceMarkScreenState extends ConsumerState<AttendanceMarkScreen> {
  String? _selectedGradeId;
  String? _selectedSectionId;
  DateTime _selectedDate = DateTime.now();
  final Map<String, String> _attendanceMap = {};

  @override
  Widget build(BuildContext context) {
    final gradesAsync = ref.watch(gradesProvider);
    final sectionsAsync = _selectedGradeId != null ? ref.watch(sectionsProvider(_selectedGradeId!)) : null;
    final studentsAsync = _selectedSectionId != null ? ref.watch(sectionStudentsProvider(_selectedSectionId!)) : null;

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
                Text('Mark Attendance', style: ApexTypography.pageTitle.copyWith(color: ApexColors.neutral900)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: gradesAsync.when(
                      data: (grades) => DropdownButtonFormField<String>(
                        value: _selectedGradeId,
                        decoration: const InputDecoration(labelText: 'Grade', border: OutlineInputBorder()),
                        items: grades.map<DropdownMenuItem<String>>((g) => DropdownMenuItem(value: g['id'] as String, child: Text(g['name']))).toList(),
                        onChanged: (v) => setState(() { _selectedGradeId = v; _selectedSectionId = null; _attendanceMap.clear(); }),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: sectionsAsync != null
                        ? sectionsAsync.when(
                            data: (sections) => DropdownButtonFormField<String>(
                              value: _selectedSectionId,
                              decoration: const InputDecoration(labelText: 'Section', border: OutlineInputBorder()),
                              items: sections.map<DropdownMenuItem<String>>((s) => DropdownMenuItem(value: s['id'] as String, child: Text(s['name']))).toList(),
                              onChanged: (v) => setState(() { _selectedSectionId = v; _attendanceMap.clear(); }),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          )
                        : DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: 'Section', border: OutlineInputBorder()), items: [], onChanged: null),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                  ),
                ]),
              ],
            ),
          ),
          if (_selectedSectionId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              color: ApexColors.neutral0,
              child: Row(children: [
                _quickAction('All Present', ApexColors.success, () => _markAll('present')),
                const SizedBox(width: 8),
                _quickAction('All Absent', ApexColors.error, () => _markAll('absent')),
                const SizedBox(width: 16),
                Text('${_attendanceMap.length} students marked', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
                const Spacer(),
                ElevatedButton(
                  onPressed: _attendanceMap.isNotEmpty ? _submitAttendance : null,
                  style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary600, foregroundColor: Colors.white),
                  child: const Text('Save Attendance'),
                ),
              ]),
            ),
          Expanded(
            child: studentsAsync != null
                ? studentsAsync.when(
                    data: (students) {
                      if (students.isEmpty) return const EmptyState(
                        icon: Icons.people_outline,
                        title: 'No Students Found',
                        description: 'No students are enrolled in this section.',
                      );
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: students.length,
                        itemBuilder: (context, i) {
                          final s = students[i];
                          final sid = s['id'] as String;
                          final currentStatus = _attendanceMap[sid] ?? 'present';
                          return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: currentStatus == 'present'
                                ? ApexColors.success.withOpacity(0.05)
                                : currentStatus == 'absent'
                                    ? ApexColors.error.withOpacity(0.05)
                                    : ApexColors.warning.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: ApexColors.primary600.withOpacity(0.1),
                              child: Text((s['first_name'] ?? '?')[0].toUpperCase(), style: ApexTypography.caption.copyWith(color: ApexColors.primary600, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${s['first_name'] ?? ''} ${s['last_name'] ?? ''}', style: ApexTypography.caption.copyWith(fontWeight: FontWeight.w600)),
                              Text('Roll: ${s['roll_number'] ?? '-'} • Adm: ${s['admission_number'] ?? ''}', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                            ])),
                            _statusButton(sid, 'present', 'P', ApexColors.success, currentStatus),
                            const SizedBox(width: 4),
                            _statusButton(sid, 'absent', 'A', ApexColors.error, currentStatus),
                            const SizedBox(width: 4),
                            _statusButton(sid, 'late', 'L', ApexColors.warning, currentStatus),
                          ]),
                        );
                      },
                    ),
                    loading: () => const LoadingWidget(),
                    error: (e, _) => CustomErrorWidget(
                      errorMessage: e.toString(),
                      onRetry: () => ref.invalidate(sectionStudentsProvider(_selectedSectionId!)),
                    ),
                  )
                : const EmptyState(
                    icon: Icons.school_outlined,
                    title: 'Select Grade & Section',
                    description: 'Choose a grade and section to mark attendance.',
                  ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(String label, Color color, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(side: BorderSide(color: color)),
      child: Text(label, style: ApexTypography.captionSmall.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _statusButton(String studentId, String status, String label, Color color, String currentStatus) {
    final isSelected = currentStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _attendanceMap[studentId] = status),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(label, style: ApexTypography.captionSmall.copyWith(color: isSelected ? Colors.white : color, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  void _markAll(String status) {
    final studentsAsync = ref.read(sectionStudentsProvider(_selectedSectionId!));
    studentsAsync.whenData((students) {
      setState(() {
        for (final s in students) {
          _attendanceMap[s['id'] as String] = status;
        }
      });
    });
  }

  void _submitAttendance() async {
    try {
      final dio = ref.read(dioProvider);
      final marks = _attendanceMap.entries.map((e) => {'student_id': e.key, 'status': e.value}).toList();
      await dio.post('/school/student-attendance/bulk-mark', data: {
        'section_id': _selectedSectionId,
        'date': _selectedDate.toIso8601String().substring(0, 10),
        'attendance_type': 'daily',
        'marks': marks,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Attendance saved for ${marks.length} students'), backgroundColor: ApexColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: ApexColors.error),
        );
      }
    }
  }
}
