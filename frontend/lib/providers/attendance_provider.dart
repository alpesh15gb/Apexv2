import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/attendance.dart';
import '../services/attendance_service.dart';

class AttendanceListState {
  final AsyncValue<List<Attendance>> records;
  final int page;
  final bool hasMore;
  final String? employeeId;
  final String? departmentId;
  final String? branchId;
  final String? fromDate;
  final String? toDate;
  final String? status;
  final bool? isLate;
  final String? search;

  AttendanceListState({
    required this.records,
    this.page = 1,
    this.hasMore = true,
    this.employeeId,
    this.departmentId,
    this.branchId,
    this.fromDate,
    this.toDate,
    this.status,
    this.isLate,
    this.search,
  });

  AttendanceListState copyWith({
    AsyncValue<List<Attendance>>? records,
    int? page,
    bool? hasMore,
    String? employeeId,
    String? departmentId,
    String? branchId,
    String? fromDate,
    String? toDate,
    String? status,
    bool? isLate,
    String? search,
  }) {
    return AttendanceListState(
      records: records ?? this.records,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      employeeId: employeeId ?? this.employeeId,
      departmentId: departmentId ?? this.departmentId,
      branchId: branchId ?? this.branchId,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      status: status ?? this.status,
      isLate: isLate ?? this.isLate,
      search: search ?? this.search,
    );
  }
}

class AttendanceListNotifier extends StateNotifier<AttendanceListState> {
  final AttendanceService _service;
  static const int _pageSize = 20;

  AttendanceListNotifier(this._service)
      : super(AttendanceListState(records: const AsyncValue.loading())) {
    fetchRecords();
  }

  Future<void> fetchRecords({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(
        records: const AsyncValue.loading(),
        page: 1,
        hasMore: true,
      );
    }

    if (!state.hasMore && !isRefresh) return;

    try {
      final data = await _service.getAttendanceRecords(
        page: state.page,
        pageSize: _pageSize,
        employeeId: state.employeeId,
        departmentId: state.departmentId,
        branchId: state.branchId,
        fromDate: state.fromDate,
        toDate: state.toDate,
        status: state.status,
        isLate: state.isLate,
        search: state.search,
      );

      final items = (data['items'] as List)
          .map((e) => Attendance.fromJson(e as Map<String, dynamic>))
          .toList();

      final current = state.records.value ?? [];
      state = state.copyWith(
        records: AsyncValue.data(isRefresh ? items : [...current, ...items]),
        page: state.page + 1,
        hasMore: items.length >= _pageSize,
      );
    } catch (e, stack) {
      state = state.copyWith(records: AsyncValue.error(e, stack));
    }
  }

  void setFilters({
    String? employeeId,
    String? departmentId,
    String? branchId,
    String? fromDate,
    String? toDate,
    String? status,
    bool? isLate,
    String? search,
  }) {
    state = state.copyWith(
      employeeId: employeeId,
      departmentId: departmentId,
      branchId: branchId,
      fromDate: fromDate,
      toDate: toDate,
      status: status,
      isLate: isLate,
      search: search,
    );
    fetchRecords(isRefresh: true);
  }

  void clearFilters() {
    state = AttendanceListState(records: const AsyncValue.loading());
    fetchRecords(isRefresh: true);
  }

  Future<void> manualMark(Map<String, dynamic> data) async {
    final record = await _service.manualMark(data);
    if (state.records.value != null) {
      state = state.copyWith(
        records: AsyncValue.data([record, ...state.records.value!]),
      );
    }
  }

  Future<void> approve(String id) async {
    final record = await _service.approveAttendance(id);
    if (state.records.value != null) {
      final list = state.records.value!.map((e) => e.id == id ? record : e).toList();
      state = state.copyWith(records: AsyncValue.data(list));
    }
  }
}

final attendanceListProvider =
    StateNotifierProvider<AttendanceListNotifier, AttendanceListState>((ref) {
  final service = ref.read(attendanceServiceProvider);
  return AttendanceListNotifier(service);
});

// Daily Summary Provider
final dailySummaryProvider =
    FutureProvider.family<DailyAttendanceSummary, String>((ref, dateStr) async {
  final service = ref.read(attendanceServiceProvider);
  return await service.getDailySummary(dateStr);
});

// Employee Summary Provider
final employeeSummaryProvider =
    FutureProvider.family<AttendanceSummary, Map<String, String>>((ref, params) async {
  final service = ref.read(attendanceServiceProvider);
  return await service.getEmployeeSummary(
    params['employeeId']!,
    fromDate: params['fromDate']!,
    toDate: params['toDate']!,
  );
});

// Punch Logs Provider
final punchLogsProvider =
    FutureProvider.family<List<PunchLog>, Map<String, String?>>((ref, params) async {
  final service = ref.read(attendanceServiceProvider);
  final data = await service.getPunchLogs(
    page: 1,
    pageSize: 100,
    employeeId: params['employeeId'],
    fromDate: params['fromDate'],
    toDate: params['toDate'],
  );
  final items = data['items'] as List;
  return items.map((e) => PunchLog.fromJson(e as Map<String, dynamic>)).toList();
});
