import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/dio_client.dart';
import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_date_picker.dart';

final attendanceDateProvider = StateProvider<String>((ref) => DateFormat('yyyy-MM-dd').format(DateTime.now()));

final attendanceStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final date = ref.watch(attendanceDateProvider);
  try {
    final res = await dio.get('/attendance/daily-summary', queryParameters: {'date': date});
    return Map<String, dynamic>.from(res.data);
  } catch (e) {
    return {};
  }
});

final attendanceListProvider = StateNotifierProvider<AttendanceListNotifier, AttendanceListState>((ref) {
  return AttendanceListNotifier(ref.read(dioProvider));
});

class AttendanceListState {
  final List<Map<String, dynamic>> records;
  final bool loading;
  final String? error;
  final int total;
  final int totalPages;
  final int page;
  final String dateFilter;
  final String? departmentFilter;
  final String? statusFilter;

  AttendanceListState({
    this.records = const [],
    this.loading = false,
    this.error,
    this.total = 0,
    this.totalPages = 1,
    this.page = 1,
    this.dateFilter = '',
    this.departmentFilter,
    this.statusFilter,
  });

  AttendanceListState copyWith({
    List<Map<String, dynamic>>? records,
    bool? loading,
    String? error,
    int? total,
    int? totalPages,
    int? page,
    String? dateFilter,
    String? departmentFilter,
    String? statusFilter,
  }) {
    return AttendanceListState(
      records: records ?? this.records,
      loading: loading ?? this.loading,
      error: error,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      page: page ?? this.page,
      dateFilter: dateFilter ?? this.dateFilter,
      departmentFilter: departmentFilter ?? this.departmentFilter,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class AttendanceListNotifier extends StateNotifier<AttendanceListState> {
  final dynamic _dio;
  AttendanceListNotifier(this._dio) : super(AttendanceListState()) {
    fetch();
  }

  Future<void> fetch({int page = 1}) async {
    state = state.copyWith(loading: true, error: null, page: page);
    try {
      final params = <String, dynamic>{'page': page, 'page_size': 20};
      if (state.dateFilter.isNotEmpty) params['date'] = state.dateFilter;
      if (state.departmentFilter != null) params['department_id'] = state.departmentFilter;
      if (state.statusFilter != null) params['status'] = state.statusFilter;

      final res = await _dio.get('/attendance/', queryParameters: params);
      final data = res.data;
      state = state.copyWith(
        records: List<Map<String, dynamic>>.from(data['items'] ?? []),
        loading: false,
        total: data['total'] ?? 0,
        totalPages: data['total_pages'] ?? 1,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void setDate(String date) {
    state = state.copyWith(dateFilter: date);
    fetch();
  }

  void setFilter({String? department, String? status}) {
    state = state.copyWith(departmentFilter: department, statusFilter: status);
    fetch();
  }
}

class AttendanceDashboardScreen extends ConsumerWidget {
  const AttendanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(attendanceStatsProvider);
    final attState = ref.watch(attendanceListProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Attendance Dashboard',
        description: 'Track daily attendance summaries, punch logs, and active status.',
        onRefresh: () {
          ref.invalidate(attendanceStatsProvider);
          ref.read(attendanceListProvider.notifier).fetch();
        },
        actions: [
          ApexButton(
            label: 'Regularization',
            icon: Icons.edit_note,
            type: ApexButtonType.ghost,
            onPressed: () => context.push('/attendance/corrections'),
          ),
          ApexButton(
            label: 'Shift Settings',
            icon: Icons.schedule,
            type: ApexButtonType.ghost,
            onPressed: () => context.push('/attendance/shifts'),
          ),
          const SizedBox(width: 4),
          ApexButton(
            label: 'Mark Attendance',
            onPressed: () => context.push('/attendance/mark'),
            type: ApexButtonType.primary,
            icon: Icons.edit_calendar_outlined,
          ),
        ],
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              statsAsync.when(
                data: (stats) => _StatsRow(stats: stats),
                loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: ApexColors.error, size: 18),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Failed to load attendance stats', style: ApexTypography.body.copyWith(color: ApexColors.error))),
                    ApexButton(label: 'Retry', type: ApexButtonType.outline, onPressed: () => ref.invalidate(attendanceStatsProvider)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              _FiltersBar(),
              const SizedBox(height: 12),
              _AttendanceTable(records: attState.records, loading: attState.loading),
              if (attState.totalPages > 1) _Pagination(state: attState),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final cards = [
      _StatCard(title: 'Present', value: '${stats['present'] ?? 0}', icon: Icons.check_circle, color: ApexColors.success),
      _StatCard(title: 'Absent', value: '${stats['absent'] ?? 0}', icon: Icons.cancel, color: ApexColors.error),
      _StatCard(title: 'Late', value: '${stats['late'] ?? 0}', icon: Icons.access_time, color: ApexColors.warning),
      _StatCard(title: 'On Leave', value: '${stats['on_leave'] ?? 0}', icon: Icons.beach_access, color: ApexColors.primary500),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards.map((c) => SizedBox(
        width: isMobile ? double.infinity : (MediaQuery.of(context).size.width - 320) / 4.4,
        child: c,
      )).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ApexColors.neutral0, borderRadius: BorderRadius.circular(10), border: Border.all(color: ApexColors.neutral200)),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: ApexTypography.cardTitle.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 2),
              Text(title, style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FiltersBar extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FiltersBar> createState() => _FiltersBarState();
}

class _FiltersBarState extends ConsumerState<_FiltersBar> {
  List<dynamic> _departments = [];

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/employees/departments', queryParameters: {'page': 1, 'page_size': 100});
      setState(() {
        _departments = res.data['items'] ?? [];
      });
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = ref.watch(attendanceDateProvider);
    final attState = ref.watch(attendanceListProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: ApexDatePicker(
              label: 'Selected Date',
              value: DateTime.parse(dateStr),
              onChanged: (d) {
                if (d != null) {
                  final fmt = DateFormat('yyyy-MM-dd').format(d);
                  ref.read(attendanceDateProvider.notifier).state = fmt;
                  ref.read(attendanceListProvider.notifier).setDate(fmt);
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              value: attState.departmentFilter,
              decoration: const InputDecoration(labelText: 'Department', contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Departments')),
                ..._departments.map((d) => DropdownMenuItem(value: d['id'] as String, child: Text(d['name'] ?? ''))),
              ],
              onChanged: (v) => ref.read(attendanceListProvider.notifier).setFilter(department: v),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<String>(
              value: attState.statusFilter,
              decoration: const InputDecoration(labelText: 'Status', contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Statuses')),
                DropdownMenuItem(value: 'present', child: Text('Present')),
                DropdownMenuItem(value: 'absent', child: Text('Absent')),
                DropdownMenuItem(value: 'late', child: Text('Late')),
                DropdownMenuItem(value: 'on_leave', child: Text('On Leave')),
              ],
              onChanged: (v) => ref.read(attendanceListProvider.notifier).setFilter(status: v),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceTable extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final bool loading;

  const _AttendanceTable({required this.records, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading && records.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }
    if (records.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
        child: Center(child: Text('No attendance records found', style: ApexTypography.body.copyWith(color: ApexColors.neutral500))),
      );
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            color: ApexColors.neutral50,
            child: Row(children: [
              const Expanded(flex: 3, child: Text('EMPLOYEE', style: TextStyle(fontWeight: FontWeight.bold))),
              const Expanded(flex: 2, child: Text('CHECK IN', style: TextStyle(fontWeight: FontWeight.bold))),
              const Expanded(flex: 2, child: Text('CHECK OUT', style: TextStyle(fontWeight: FontWeight.bold))),
              const Expanded(flex: 2, child: Text('WORK HOURS', style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(width: 100, child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(width: 40),
            ]),
          ),
          ...records.asMap().entries.map((entry) {
            final idx = entry.key;
            final r = entry.value;
            final status = r['status'] ?? 'absent';
            final employeeName = r['employee_name'] ?? '—';
            final employeeCode = r['employee_code'] ?? '—';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: idx.isEven ? Colors.white : ApexColors.neutral50,
                border: Border(bottom: BorderSide(color: ApexColors.neutral200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(employeeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(employeeCode, style: TextStyle(color: ApexColors.neutral500, fontSize: 11)),
                      ],
                    ),
                  ),
                  Expanded(flex: 2, child: Text(r['check_in'] ?? '—')),
                  Expanded(flex: 2, child: Text(r['check_out'] ?? '—')),
                  Expanded(flex: 2, child: Text(r['work_hours'] ?? '—')),
                  SizedBox(
                    width: 100,
                    child: _StatusBadge(status: status),
                  ),
                  SizedBox(
                    width: 40,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 16),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'detail', child: Text('Detail View')),
                        const PopupMenuItem(value: 'edit', child: Text('Manual Override')),
                      ],
                      onSelected: (v) {
                        if (v == 'detail') context.push('/attendance/detail?employeeId=${r['employee_id']}');
                        if (v == 'edit') context.push('/attendance/mark');
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'present': return ApexBadge.success('PRESENT');
      case 'absent': return ApexBadge.danger('ABSENT');
      case 'late': return ApexBadge.warning('LATE');
      case 'on_leave': return ApexBadge.neutral('ON LEAVE');
      default: return ApexBadge.neutral(status.toUpperCase());
    }
  }
}

class _Pagination extends ConsumerWidget {
  final AttendanceListState state;
  const _Pagination({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: state.page > 1 ? () => ref.read(attendanceListProvider.notifier).fetch(page: state.page - 1) : null,
          ),
          Text('Page ${state.page} of ${state.totalPages}'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: state.page < state.totalPages ? () => ref.read(attendanceListProvider.notifier).fetch(page: state.page + 1) : null,
          ),
        ],
      ),
    );
  }
}
