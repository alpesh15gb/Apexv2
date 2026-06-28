import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';

class StudentDetailScreen extends ConsumerStatefulWidget {
  final String studentId;
  const StudentDetailScreen({super.key, required this.studentId});

  @override
  ConsumerState<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends ConsumerState<StudentDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<String, dynamic>? _student;
  List<dynamic> _guardians = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    _loadStudent();
  }

  Future<void> _loadStudent() async {
    try {
      final dio = ref.read(dioProvider);
      final studentRes = await dio.get('/school/students/${widget.studentId}');
      final guardianRes = await dio.get('/school/students/${widget.studentId}/guardians');
      setState(() {
        _student = studentRes.data;
        _guardians = guardianRes.data is List ? guardianRes.data : [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_student == null) return const Scaffold(body: Center(child: Text('Student not found')));

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      appBar: AppBar(
        backgroundColor: ApexColors.neutral0,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        title: Text('${_student!['first_name']} ${_student!['last_name']}', style: ApexTypography.titleLarge.copyWith(color: ApexColors.neutral900)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/school/students')),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/school/students/${widget.studentId}/edit'),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: ApexColors.primary600,
          unselectedLabelColor: ApexColors.neutral500,
          indicatorColor: ApexColors.primary600,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Guardians'),
            Tab(text: 'Attendance'),
            Tab(text: 'Fees'),
            Tab(text: 'Documents'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _OverviewTab(student: _student!),
          _GuardiansTab(guardians: _guardians),
          _AttendanceTab(studentId: widget.studentId),
          _FeesTab(studentId: widget.studentId),
          Center(child: Text('Documents', style: ApexTypography.body.copyWith(color: ApexColors.neutral500))),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> student;
  const _OverviewTab({required this.student});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _infoCard('Personal Information', [
            _infoRow('Admission Number', student['admission_number'] ?? '-'),
            _infoRow('Roll Number', student['roll_number'] ?? '-'),
            _infoRow('Date of Birth', student['date_of_birth'] ?? '-'),
            _infoRow('Gender', student['gender'] ?? '-'),
            _infoRow('Blood Group', student['blood_group'] ?? '-'),
            _infoRow('Email', student['email'] ?? '-'),
            _infoRow('Phone', student['phone'] ?? '-'),
            _infoRow('Address', student['address'] ?? '-'),
          ]),
          const SizedBox(height: 16),
          _infoCard('Academic Information', [
            _infoRow('Status', (student['status'] ?? 'active').toString().toUpperCase()),
            _infoRow('Admission Date', student['admission_date'] ?? '-'),
            _infoRow('Medical Conditions', student['medical_conditions'] ?? '-'),
            _infoRow('Allergies', student['allergies'] ?? '-'),
          ]),
          const SizedBox(height: 16),
          _infoCard('Emergency Contact', [
            _infoRow('Name', student['emergency_contact_name'] ?? '-'),
            _infoRow('Phone', student['emergency_contact_phone'] ?? '-'),
          ]),
        ],
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(12), border: Border.all(color: ApexColors.neutral200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: ApexTypography.titleLarge.copyWith(color: ApexColors.neutral900)),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        SizedBox(width: 160, child: Text(label, style: ApexTypography.caption.copyWith(color: ApexColors.neutral500))),
        Expanded(child: Text(value, style: ApexTypography.caption.copyWith(color: ApexColors.neutral900))),
      ]),
    );
  }
}

class _GuardiansTab extends StatelessWidget {
  final List<dynamic> guardians;
  const _GuardiansTab({required this.guardians});

  @override
  Widget build(BuildContext context) {
    if (guardians.isEmpty) return Center(child: Text('No guardians added', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: guardians.length,
      itemBuilder: (context, i) {
        final g = guardians[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
          child: Row(children: [
            CircleAvatar(backgroundColor: ApexColors.primary600.withOpacity(0.1), child: Text((g['first_name'] ?? '?')[0].toUpperCase(), style: ApexTypography.titleLarge.copyWith(color: ApexColors.primary600))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${g['first_name'] ?? ''} ${g['last_name'] ?? ''}', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600)),
              Text('${g['relationship'] ?? ''} • ${g['phone'] ?? ''}', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
            ])),
            if (g['is_primary'] == true) const ApexBadge(label: 'PRIMARY', type: ApexBadgeType.success),
          ]),
        );
      },
    );
  }
}

class _AttendanceTab extends ConsumerStatefulWidget {
  final String studentId;
  const _AttendanceTab({required this.studentId});
  @override
  ConsumerState<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends ConsumerState<_AttendanceTab> {
  List<dynamic> _attendance = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, 1);
      final dio = ref.read(dioProvider);
      final res = await dio.get('/school/student-attendance/', queryParameters: {
        'student_id': widget.studentId,
        'date_from': from.toIso8601String().substring(0, 10),
        'date_to': now.toIso8601String().substring(0, 10),
      });
      setState(() { _attendance = res.data is List ? res.data : []; _loading = false; });
    } catch (e) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_attendance.isEmpty) return Center(child: Text('No attendance records', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _attendance.length,
      itemBuilder: (context, i) {
        final a = _attendance[i];
        final status = a['status'] ?? 'unknown';
        final color = status == 'present' ? ApexColors.success : status == 'absent' ? ApexColors.error : ApexColors.warning;
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(6)),
          child: Row(children: [
            Icon(Icons.circle, size: 8, color: color),
            const SizedBox(width: 12),
            Text(a['date'] ?? '', style: ApexTypography.caption.copyWith(color: ApexColors.neutral900)),
            const Spacer(),
            Text(status.toString().toUpperCase(), style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.w600, color: color)),
          ]),
        );
      },
    );
  }
}

class _FeesTab extends ConsumerStatefulWidget {
  final String studentId;
  const _FeesTab({required this.studentId});
  @override
  ConsumerState<_FeesTab> createState() => _FeesTabState();
}

class _FeesTabState extends ConsumerState<_FeesTab> {
  List<dynamic> _fees = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/school/fees/students/${widget.studentId}');
      setState(() { _fees = res.data is List ? res.data : []; _loading = false; });
    } catch (e) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_fees.isEmpty) return Center(child: Text('No fee records', style: ApexTypography.body.copyWith(color: ApexColors.neutral500)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _fees.length,
      itemBuilder: (context, i) {
        final f = _fees[i];
        final status = f['status'] ?? 'pending';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('₹${f['final_amount'] ?? 0}', style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600)),
              Text('Due: ${f['due_date'] ?? '-'}', style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
            ])),
            ApexBadge(
              label: status,
              type: status == 'paid' ? ApexBadgeType.success : status == 'partial' ? ApexBadgeType.warning : ApexBadgeType.danger,
            ),
          ]),
        );
      },
    );
  }
}
