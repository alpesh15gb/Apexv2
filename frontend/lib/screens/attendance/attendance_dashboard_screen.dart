import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/dio_client.dart';
import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/apex_app_bar.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/apex_date_picker.dart';

final attendanceStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final res = await dio.get('/attendance/daily-summary', queryParameters: {'date': today});
  return Map<String, dynamic>.from(res.data);
});

final attendanceListProvider = StateNotifierProvider<AttendanceListNotifier, AttendanceListState>((ref) {
  return AttendanceListNotifier(ref.read(dioProvider));
});

class AttendanceListState {
  final List<Map<String, dynamic>> records;
  final bool loading;
  final String? error;
  final int page;
  final int total;
  final int totalPages;
  final String? dateFilter;
  final String? departmentFilter;
  final String? statusFilter;

  AttendanceListState({
    this.records = const [],
    this.loading = false,
    this.error,
    this.page = 1,
    this.total = 0,
    this.totalPages = 1,
    this.dateFilter,
    this.departmentFilter,
    this.statusFilter,
  });

  AttendanceListState copyWith({
    List<Map<String, dynamic>>? records,
    bool? loading,
    String? error,
    int? page,
    int? total,
    int? totalPages,
    String? dateFilter,
    String? departmentFilter,
    String? statusFilter,
  }) {
    return AttendanceListState(
      records: records ?? this.records,
      loading: loading ?? this.loading,
      error: error,
      page: page ?? this.page,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      dateFilter: dateFilter ?? this.dateFilter,
      departmentFilter: departmentFilter ?? this.departmentFilter,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class AttendanceListNotifier extends StateNotifier<AttendanceListState> {
  final dynamic _dio;
  AttendanceListNotifier(this._dio) : super(AttendanceListState(dateFilter: DateFormat('yyyy-MM-dd').format(DateTime.now()))) {
    fetch();
  }

  Future<void> fetch({int page = 1}) async {
    state = state.copyWith(loading: true, error: null, page: page);
    try {
      final params = <String, dynamic>{'page': page, 'page_size': 20};
      if (state.dateFilter != null) params['date'] = state.dateFilter;
      if (state.departmentFilter != null) params['department_id'] = state.departmentFilter;
      if (state.statusFilter != null) params['status'] = state.statusFilter;

      final res = await _dio.get('/attendance/', queryParameters: params);
      final data = res.data;
      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
      state = state.copyWith(
        records: items,
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
      appBar: AppBar(
        title: Text('Attendance', style: ApexTypography.sectionTitle),
        backgroundColor: Colors.white,
        foregroundColor: ApexColors.neutral900,
        elevation: 0,
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: ApexColors.neutral200)),
        actions: [
          ApexButton(
            label: 'Regularization',
            icon: Icons.edit_note,
            type: ApexButtonType.ghost,
            onPressed: () => context.push('/attendance/regularization'),
          ),
          ApexButton(
            label: 'Shifts',
            icon: Icons.schedule,
            type: ApexButtonType.ghost,
            onPressed: () => context.push('/shifts'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            statsAsync.when(
              data: (stats) => _StatsRow(stats: stats),
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text('Error: $e', style: TextStyle(color: ApexColors.error)),
            ),
            const SizedBox(height: 16),
            _FiltersBar(),
            const SizedBox(height: 12),
            _AttendanceTable(records: attState.records, loading: attState.loading),
            if (attState.totalPages > 1) _Pagination(state: attState),
          ],
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
      _StatCard(title: 'On Leave', value: '${stats['on_leave'] ?? 0}', icon: Icons.event_busy, color: ApexColors.primary),
      _StatCard(title: 'Half Day', value: '${stats['half_day'] ?? 0}', icon: Icons.schedule, color: ApexColors.neutral500),
      _StatCard(title: 'Total', value: '${stats['total_employees'] ?? 0}', icon: Icons.people, color: ApexColors.neutral900),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards.map((c) => SizedBox(
        width: isMobile ? double.infinity : (MediaQuery.of(context).size.width - 80) / 6,
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
    return ApexCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: ApexTypography.caption.copyWith(color: ApexColors.neutral500, fontWeight: FontWeight.w500)),
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
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: () {
              setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
              ref.read(attendanceListProvider.notifier).setDate(DateFormat('yyyy-MM-dd').format(_selectedDate));
            },
          ),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2024), lastDate: DateTime(2030));
              if (picked != null) {
                setState(() => _selectedDate = picked);
                ref.read(attendanceListProvider.notifier).setDate(DateFormat('yyyy-MM-dd').format(picked));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: ApexColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(6)),
              child: Row(children: [
                Icon(Icons.calendar_today, size: 14, color: ApexColors.primary),
                const SizedBox(width: 6),
                Text(DateFormat('dd MMM yyyy').format(_selectedDate), style: ApexTypography.captionMedium.copyWith(color: ApexColors.primary)),
              ]),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: () {
              setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
              ref.read(attendanceListProvider.notifier).setDate(DateFormat('yyyy-MM-dd').format(_selectedDate));
            },
          ),
          const SizedBox(width: 8),
          ApexButton(
            label: 'Today',
            type: ApexButtonType.ghost,
            onPressed: () {
              setState(() => _selectedDate = DateTime.now());
              ref.read(attendanceListProvider.notifier).setDate(DateFormat('yyyy-MM-dd').format(DateTime.now()));
            },
          ),
          const Spacer(),
          IconButton(icon: Icon(Icons.download, size: 18, color: ApexColors.neutral500), onPressed: () {}),
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
    if (loading) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    if (records.isEmpty) return ApexCard(
      padding: const EdgeInsets.all(32),
      child: SizedBox(
        height: 136,
        child: Center(child: Text('No attendance records for this date', style: ApexTypography.body.copyWith(color: ApexColors.neutral500))),
      ),
    );

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: ApexColors.neutral200)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1000),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: ApexColors.neutral50,
                child: Row(children: [
                  SizedBox(width: 180, child: Text('EMPLOYEE', style: ApexTypography.tableHeader)),
                  SizedBox(width: 100, child: Text('CODE', style: ApexTypography.tableHeader)),
                  SizedBox(width: 100, child: Text('CHECK IN', style: ApexTypography.tableHeader)),
                  SizedBox(width: 100, child: Text('CHECK OUT', style: ApexTypography.tableHeader)),
                  SizedBox(width: 80, child: Text('HOURS', style: ApexTypography.tableHeader)),
                  SizedBox(width: 80, child: Text('STATUS', style: ApexTypography.tableHeader)),
                  SizedBox(width: 80, child: Text('SOURCE', style: ApexTypography.tableHeader)),
                ]),
              ),
              ...records.asMap().entries.map((entry) {
                final i = entry.key;
                final r = entry.value;
                final status = r['status'] ?? 'unknown';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: i.isEven ? Colors.white : ApexColors.neutral50,
                  child: Row(children: [
                    SizedBox(width: 180, child: Row(children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: ApexColors.primary.withOpacity(0.1),
                        child: Text((r['employee_name'] ?? '?')[0].toUpperCase(), style: ApexTypography.captionSmall.copyWith(color: ApexColors.primary, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(r['employee_name'] ?? '—', style: ApexTypography.table, overflow: TextOverflow.ellipsis)),
                    ])),
                    SizedBox(width: 100, child: Text(r['employee_code'] ?? '—', style: ApexTypography.table.copyWith(color: ApexColors.neutral500))),
                    SizedBox(width: 100, child: Text(_formatTime(r['punch_in']), style: ApexTypography.table)),
                    SizedBox(width: 100, child: Text(_formatTime(r['punch_out']), style: ApexTypography.table)),
                    SizedBox(width: 80, child: Text(r['total_hours'] != null ? '${(r['total_hours'] as num).toStringAsFixed(1)}h' : '—', style: ApexTypography.table)),
                    SizedBox(
                      width: 80,
                      child: _statusBadge(status),
                    ),
                    SizedBox(width: 80, child: Text(r['source'] ?? 'biometric', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500))),
                  ]),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(dynamic time) {
    if (time == null) return '—';
    try {
      final dt = DateTime.parse(time.toString());
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return time.toString();
    }
  }

  Widget _statusBadge(String status) {
    ApexBadgeType type;
    switch (status) {
      case 'present': type = ApexBadgeType.success; break;
      case 'absent': type = ApexBadgeType.danger; break;
      case 'late': type = ApexBadgeType.warning; break;
      case 'half_day': type = ApexBadgeType.warning; break;
      case 'on_leave': type = ApexBadgeType.info; break;
      default: type = ApexBadgeType.neutral;
    }
    return ApexBadge(label: status, type: type);
  }
}

class _Pagination extends ConsumerWidget {
  final AttendanceListState state;
  const _Pagination({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: ApexColors.neutral200))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${state.total} records', style: ApexTypography.caption.copyWith(color: ApexColors.neutral500)),
          const SizedBox(width: 24),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: state.page > 1 ? () => ref.read(attendanceListProvider.notifier).fetch(page: state.page - 1) : null,
          ),
          Text('Page ${state.page} of ${state.totalPages}', style: ApexTypography.caption),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: state.page < state.totalPages ? () => ref.read(attendanceListProvider.notifier).fetch(page: state.page + 1) : null,
          ),
        ],
      ),
    );
  }
}

