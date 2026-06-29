import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;

import '../../core/dio_client.dart';
import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../services/report_service.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_stat_card.dart';
import '../../widgets/apex_filter_toolbar.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

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

// ─── State & Notifier ─────────────────────────────────────────────────────────

class AttendanceListState {
  final List<Map<String, dynamic>> records;
  final bool loading;
  final String? error;
  final int total;
  final int totalPages;
  final int page;
  final String dateFilter;
  final String? departmentFilter;
  final String? branchFilter;
  final String? shiftFilter;
  final String? statusFilter;
  final String searchFilter;

  AttendanceListState({
    this.records = const [],
    this.loading = false,
    this.error,
    this.total = 0,
    this.totalPages = 1,
    this.page = 1,
    this.dateFilter = '',
    this.departmentFilter,
    this.branchFilter,
    this.shiftFilter,
    this.statusFilter,
    this.searchFilter = '',
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
    String? branchFilter,
    String? shiftFilter,
    String? statusFilter,
    String? searchFilter,
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
      branchFilter: branchFilter ?? this.branchFilter,
      shiftFilter: shiftFilter ?? this.shiftFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      searchFilter: searchFilter ?? this.searchFilter,
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
      if (state.dateFilter.isNotEmpty) params['date'] = state.dateFilter;
      if (state.departmentFilter != null) params['department_id'] = state.departmentFilter;
      if (state.branchFilter != null) params['branch_id'] = state.branchFilter;
      if (state.shiftFilter != null) params['shift_id'] = state.shiftFilter;
      if (state.statusFilter != null) params['status'] = state.statusFilter;
      if (state.searchFilter.isNotEmpty) params['search'] = state.searchFilter;

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
    state = AttendanceListState(
      records: state.records,
      total: state.total,
      totalPages: state.totalPages,
      dateFilter: date,
      departmentFilter: state.departmentFilter,
      branchFilter: state.branchFilter,
      shiftFilter: state.shiftFilter,
      statusFilter: state.statusFilter,
      searchFilter: state.searchFilter,
    );
    fetch();
  }

  void setDepartmentFilter(String? department) {
    state = AttendanceListState(
      records: state.records,
      total: state.total,
      totalPages: state.totalPages,
      dateFilter: state.dateFilter,
      departmentFilter: department,
      branchFilter: state.branchFilter,
      shiftFilter: state.shiftFilter,
      statusFilter: state.statusFilter,
      searchFilter: state.searchFilter,
    );
    fetch();
  }

  void setBranchFilter(String? branch) {
    state = AttendanceListState(
      records: state.records,
      total: state.total,
      totalPages: state.totalPages,
      dateFilter: state.dateFilter,
      departmentFilter: state.departmentFilter,
      branchFilter: branch,
      shiftFilter: state.shiftFilter,
      statusFilter: state.statusFilter,
      searchFilter: state.searchFilter,
    );
    fetch();
  }

  void setShiftFilter(String? shift) {
    state = AttendanceListState(
      records: state.records,
      total: state.total,
      totalPages: state.totalPages,
      dateFilter: state.dateFilter,
      departmentFilter: state.departmentFilter,
      branchFilter: state.branchFilter,
      shiftFilter: shift,
      statusFilter: state.statusFilter,
      searchFilter: state.searchFilter,
    );
    fetch();
  }

  void setStatusFilter(String? status) {
    state = AttendanceListState(
      records: state.records,
      total: state.total,
      totalPages: state.totalPages,
      dateFilter: state.dateFilter,
      departmentFilter: state.departmentFilter,
      branchFilter: state.branchFilter,
      shiftFilter: state.shiftFilter,
      statusFilter: status,
      searchFilter: state.searchFilter,
    );
    fetch();
  }

  void setSearchFilter(String search) {
    state = state.copyWith(searchFilter: search);
    fetch();
  }

  void resetFilters(String date) {
    state = AttendanceListState(dateFilter: date);
    fetch();
  }
}

// ─── Main Dashboard Screen ────────────────────────────────────────────────────

class AttendanceDashboardScreen extends ConsumerWidget {
  const AttendanceDashboardScreen({super.key});

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final attState = ref.read(attendanceListProvider);
    try {
      final service = ref.read(reportServiceProvider);
      final bytes = await service.downloadFilteredAttendance(
        date: attState.dateFilter,
        departmentId: attState.departmentFilter,
        branchId: attState.branchFilter,
        shiftId: attState.shiftFilter,
        status: attState.statusFilter,
        search: attState.searchFilter.isNotEmpty ? attState.searchFilter : null,
      );
      final filename = 'attendance_${attState.dateFilter}.csv';
      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', filename)
          ..click();
        html.Url.revokeObjectUrl(url);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported $filename'), backgroundColor: ApexColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: ApexColors.error),
        );
      }
    }
  }

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
        actions: [
          ApexButton(
            label: 'Refresh',
            icon: Icons.refresh,
            type: ApexButtonType.ghost,
            onPressed: () {
              ref.invalidate(attendanceStatsProvider);
              ref.read(attendanceListProvider.notifier).fetch();
            },
          ),
          const SizedBox(width: 8),
          ApexButton(
            label: 'Export',
            icon: Icons.download,
            type: ApexButtonType.ghost,
            onPressed: () => _exportCsv(context, ref),
          ),
          const SizedBox(width: 8),
          ApexButton(
            label: 'Regularization',
            icon: Icons.edit_note,
            type: ApexButtonType.ghost,
            onPressed: () => context.push('/attendance/corrections'),
          ),
          const SizedBox(width: 8),
          ApexButton(
            label: 'Shift Settings',
            icon: Icons.schedule,
            type: ApexButtonType.ghost,
            onPressed: () => context.push('/attendance/shifts'),
          ),
          const SizedBox(width: 8),
          ApexButton(
            label: 'Mark Attendance',
            onPressed: () => context.push('/attendance/mark'),
            type: ApexButtonType.primary,
            icon: Icons.edit_calendar_outlined,
          ),
        ],
        body: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Row
              statsAsync.when(
                data: (stats) => _StatsRow(stats: stats, isMobile: isMobile),
                loading: () => const _StatsLoading(),
                error: (e, _) => _StatsError(onRetry: () => ref.invalidate(attendanceStatsProvider)),
              ),
              const SizedBox(height: 16),
              // Filters
              _FiltersBar(),
              const SizedBox(height: 16),
              // Table
              _AttendanceTable(records: attState.records, loading: attState.loading, isMobile: isMobile),
              if (attState.totalPages > 1) ...[
                const SizedBox(height: 16),
                _EnhancedPagination(state: attState),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stats Row Component ──────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool isMobile;

  const _StatsRow({required this.stats, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final cardWidth = isMobile
            ? availableWidth
            : availableWidth < 900
                ? (availableWidth - 12) / 2
                : (availableWidth - 36) / 4;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMobile) ...[
              Text(
                'Overview',
                style: ApexTypography.sectionTitle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(width: cardWidth, child: ApexStatCard.present(value: '${stats['present'] ?? 0}')),
                SizedBox(width: cardWidth, child: ApexStatCard.absent(value: '${stats['absent'] ?? 0}')),
                SizedBox(width: cardWidth, child: ApexStatCard.late(value: '${stats['late'] ?? 0}')),
                SizedBox(width: cardWidth, child: ApexStatCard.onLeave(value: '${stats['on_leave'] ?? 0}')),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatsLoading extends StatelessWidget {
  const _StatsLoading();

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final cardWidth = isMobile
            ? availableWidth
            : availableWidth < 900
                ? (availableWidth - 12) / 2
                : (availableWidth - 36) / 4;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(
            4,
            (index) => SizedBox(
              width: cardWidth,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: ApexColors.neutral0,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ApexColors.neutral200),
                ),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatsError extends StatelessWidget {
  final VoidCallback onRetry;

  const _StatsError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ApexColors.neutral0,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ApexColors.error200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: ApexColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Failed to load attendance stats',
              style: ApexTypography.body.copyWith(color: ApexColors.error),
            ),
          ),
          ApexButton(
            label: 'Retry',
            type: ApexButtonType.outline,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

// ─── Filters Bar Component ────────────────────────────────────────────────────

class _FiltersBar extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FiltersBar> createState() => _FiltersBarState();
}

class _FiltersBarState extends ConsumerState<_FiltersBar> {
  List<dynamic> _departments = [];
  List<dynamic> _branches = [];
  List<dynamic> _shifts = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _loadBranches();
    _loadShifts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
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

  Future<void> _loadBranches() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/employees/branches', queryParameters: {'page': 1, 'page_size': 100});
      setState(() {
        _branches = res.data['items'] ?? [];
      });
    } catch (e) {
      // ignore
    }
  }

  Future<void> _loadShifts() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/shifts/', queryParameters: {'page': 1, 'page_size': 100});
      setState(() {
        _shifts = res.data['items'] ?? [];
      });
    } catch (e) {
      // ignore
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(attendanceListProvider.notifier).setSearchFilter(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = ref.watch(attendanceDateProvider);
    final attState = ref.watch(attendanceListProvider);
    final isMobile = Responsive.isMobile(context);

    return ApexFilterToolbar(
      padding: const EdgeInsets.all(16),
      filters: [
        ApexFilter.date(
          label: 'Date',
          value: DateTime.parse(dateStr),
          onChanged: (d) {
            final fmt = DateFormat('yyyy-MM-dd').format(d);
            ref.read(attendanceDateProvider.notifier).state = fmt;
            ref.read(attendanceListProvider.notifier).setDate(fmt);
          },
          width: isMobile ? null : 180,
        ),
        ApexFilter.search(
          label: 'Search',
          hintText: 'Name, code, or mobile',
          onChanged: _onSearchChanged,
          controller: _searchController,
          width: isMobile ? null : 220,
        ),
        ApexFilter.dropdown(
          label: 'Location',
          value: attState.branchFilter,
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('All Locations')),
            ..._branches.map((b) => DropdownMenuItem<String>(value: b['id'] as String, child: Text(b['name'] ?? ''))),
          ],
          onChanged: (v) => ref.read(attendanceListProvider.notifier).setBranchFilter(v),
          width: isMobile ? null : 180,
        ),
        ApexFilter.dropdown(
          label: 'Department',
          value: attState.departmentFilter,
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('All Departments')),
            ..._departments.map((d) => DropdownMenuItem<String>(value: d['id'] as String, child: Text(d['name'] ?? ''))),
          ],
          onChanged: (v) => ref.read(attendanceListProvider.notifier).setDepartmentFilter(v),
          width: isMobile ? null : 180,
        ),
        ApexFilter.dropdown(
          label: 'Shift',
          value: attState.shiftFilter,
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('All Shifts')),
            ..._shifts.map((s) => DropdownMenuItem<String>(value: s['id'] as String, child: Text(s['name'] ?? ''))),
          ],
          onChanged: (v) => ref.read(attendanceListProvider.notifier).setShiftFilter(v),
          width: isMobile ? null : 160,
        ),
        ApexFilter.dropdown(
          label: 'Status',
          value: attState.statusFilter,
          items: const [
            DropdownMenuItem<String>(value: null, child: Text('All Statuses')),
            DropdownMenuItem<String>(value: 'present', child: Text('Present')),
            DropdownMenuItem<String>(value: 'absent', child: Text('Absent')),
            DropdownMenuItem<String>(value: 'late', child: Text('Late')),
            DropdownMenuItem<String>(value: 'on_leave', child: Text('On Leave')),
            DropdownMenuItem<String>(value: 'half_day', child: Text('Half Day')),
          ],
          onChanged: (v) => ref.read(attendanceListProvider.notifier).setStatusFilter(v),
          width: isMobile ? null : 150,
        ),
      ],
      onReset: () {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        _searchController.clear();
        _searchDebounce?.cancel();
        ref.read(attendanceDateProvider.notifier).state = today;
        ref.read(attendanceListProvider.notifier).resetFilters(today);
      },
    );
  }
}

// ─── Attendance Table Component ──────────────────────────────────────────────

class _AttendanceTable extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final bool loading;
  final bool isMobile;

  const _AttendanceTable({required this.records, required this.loading, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    if (loading && records.isEmpty) {
      return const _TableLoading();
    }

    if (records.isEmpty) {
      return _TableEmpty();
    }

    const double rowHeight = 52;
    const double headerHeight = 44;
    final double tableHeight = headerHeight + (records.length * rowHeight);
    final double maxHeight = isMobile ? 450 : 600;
    final double containerHeight = tableHeight < maxHeight ? tableHeight : maxHeight;

    Widget buildTable() {
      return Container(
        height: containerHeight,
        decoration: BoxDecoration(
          color: ApexColors.neutral0,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ApexColors.neutral200),
          boxShadow: [
            BoxShadow(
              color: ApexColors.neutral900.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            const _TableHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  return _TableRow(record: records[index], index: index);
                },
              ),
            ),
          ],
        ),
      );
    }

    if (isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: 760, child: buildTable()),
      );
    }

    return buildTable();
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ApexColors.neutral50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          bottom: BorderSide(color: ApexColors.neutral200),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('EMPLOYEE', style: _headerStyle)),
          Expanded(flex: 2, child: Text('CHECK IN', style: _headerStyle, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('CHECK OUT', style: _headerStyle, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('WORK HOURS', style: _headerStyle, textAlign: TextAlign.right)),
          SizedBox(width: 16),
          SizedBox(width: 110, child: Text('STATUS', style: _headerStyle)),
          SizedBox(width: 44),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: ApexColors.gray600,
    letterSpacing: 0.5,
  );
}

class _TableRow extends StatelessWidget {
  final Map<String, dynamic> record;
  final int index;

  const _TableRow({required this.record, required this.index});

  @override
  Widget build(BuildContext context) {
    final status = record['status'] ?? 'absent';
    final employeeName = record['employee_name'] ?? '—';
    final employeeCode = record['employee_code'] ?? '—';

    return Material(
      color: index.isEven ? ApexColors.neutral0 : ApexColors.neutral50,
      child: InkWell(
        hoverColor: ApexColors.primary50.withValues(alpha: 0.45),
        onTap: () => context.push('/attendance/detail?employeeId=${record['employee_id']}'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: ApexColors.neutral200, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employeeName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ApexColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      employeeCode,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ApexColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _formatTime(record['punch_in']),
                  style: const TextStyle(fontSize: 14, color: ApexColors.gray700),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _formatTime(record['punch_out']),
                  style: const TextStyle(fontSize: 14, color: ApexColors.gray700),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  record['total_hours'] != null ? '${(record['total_hours'] as num).toStringAsFixed(1)} hrs' : '—',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ApexColors.gray700,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 110,
                child: AttendanceStatusBadge(status: status),
              ),
              SizedBox(
                width: 44,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  tooltip: 'Attendance row actions',
                  padding: EdgeInsets.zero,
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(value: 'detail', child: Text('Detail View')),
                    PopupMenuItem(value: 'edit', child: Text('Manual Override')),
                  ],
                  onSelected: (v) {
                    if (v == 'detail') context.push('/attendance/detail?employeeId=${record['employee_id']}');
                    if (v == 'edit') context.push('/attendance/mark');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(dynamic time) {
    if (time == null) return '—';
    try {
      final dt = DateTime.parse(time.toString()).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return time.toString();
    }
  }
}

class _TableLoading extends StatelessWidget {
  const _TableLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: ApexColors.neutral0,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ApexColors.neutral200),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _TableEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: ApexColors.neutral0,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ApexColors.neutral200),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 48, color: ApexColors.gray400),
            const SizedBox(height: 12),
            Text(
              'No attendance records found',
              style: ApexTypography.body.copyWith(color: ApexColors.gray500),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Enhanced Pagination ──────────────────────────────────────────────────────

class _EnhancedPagination extends ConsumerWidget {
  final AttendanceListState state;

  const _EnhancedPagination({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ApexColors.neutral0,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ApexColors.neutral200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: state.page > 1
                ? () => ref.read(attendanceListProvider.notifier).fetch(page: state.page - 1)
                : null,
            tooltip: 'Previous Page',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const SizedBox(width: 16),
          Text(
            'Page ${state.page} of ${state.totalPages}',
            style: ApexTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: ApexColors.gray700,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: state.page < state.totalPages
                ? () => ref.read(attendanceListProvider.notifier).fetch(page: state.page + 1)
                : null,
            tooltip: 'Next Page',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }
}