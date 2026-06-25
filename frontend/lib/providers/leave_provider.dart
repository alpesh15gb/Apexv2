import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/leave.dart';
import '../services/leave_service.dart';

class LeaveRequestsState {
  final AsyncValue<List<LeaveRequest>> requests;
  final int page;
  final bool hasMore;
  final String? employeeId;
  final String? status;

  LeaveRequestsState({
    required this.requests,
    this.page = 1,
    this.hasMore = true,
    this.employeeId,
    this.status,
  });

  LeaveRequestsState copyWith({
    AsyncValue<List<LeaveRequest>>? requests,
    int? page,
    bool? hasMore,
    String? employeeId,
    String? status,
  }) {
    return LeaveRequestsState(
      requests: requests ?? this.requests,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      employeeId: employeeId ?? this.employeeId,
      status: status ?? this.status,
    );
  }
}

class LeaveRequestsNotifier extends StateNotifier<LeaveRequestsState> {
  final LeaveService _service;
  static const int _pageSize = 20;

  LeaveRequestsNotifier(this._service)
      : super(LeaveRequestsState(requests: const AsyncValue.loading())) {
    fetchRequests();
  }

  Future<void> fetchRequests({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(
        requests: const AsyncValue.loading(),
        page: 1,
        hasMore: true,
      );
    }

    if (!state.hasMore && !isRefresh) return;

    try {
      final data = await _service.getLeaveRequests(
        employeeId: state.employeeId,
        status: state.status,
        page: state.page,
        pageSize: _pageSize,
      );

      final items = (data['items'] as List)
          .map((e) => LeaveRequest.fromJson(e as Map<String, dynamic>))
          .toList();

      final current = state.requests.value ?? [];
      state = state.copyWith(
        requests: AsyncValue.data(isRefresh ? items : [...current, ...items]),
        page: state.page + 1,
        hasMore: items.length >= _pageSize,
      );
    } catch (e, stack) {
      state = state.copyWith(requests: AsyncValue.error(e, stack));
    }
  }

  void setFilters({String? employeeId, String? status}) {
    state = state.copyWith(employeeId: employeeId, status: status);
    fetchRequests(isRefresh: true);
  }

  void clearFilters() {
    state = LeaveRequestsState(requests: const AsyncValue.loading());
    fetchRequests(isRefresh: true);
  }

  Future<void> applyLeave(Map<String, dynamic> data) async {
    final req = await _service.applyLeave(data);
    if (state.requests.value != null) {
      state = state.copyWith(
        requests: AsyncValue.data([req, ...state.requests.value!]),
      );
    }
  }

  Future<void> approve(String id) async {
    final updated = await _service.approveLeave(id);
    if (state.requests.value != null) {
      final list = state.requests.value!.map((e) => e.id == id ? updated : e).toList();
      state = state.copyWith(requests: AsyncValue.data(list));
    }
  }

  Future<void> reject(String id, String reason) async {
    final updated = await _service.rejectLeave(id, reason);
    if (state.requests.value != null) {
      final list = state.requests.value!.map((e) => e.id == id ? updated : e).toList();
      state = state.copyWith(requests: AsyncValue.data(list));
    }
  }

  Future<void> cancel(String id) async {
    final updated = await _service.cancelLeave(id);
    if (state.requests.value != null) {
      final list = state.requests.value!.map((e) => e.id == id ? updated : e).toList();
      state = state.copyWith(requests: AsyncValue.data(list));
    }
  }
}

final leaveRequestsProvider =
    StateNotifierProvider<LeaveRequestsNotifier, LeaveRequestsState>((ref) {
  final service = ref.read(leaveServiceProvider);
  return LeaveRequestsNotifier(service);
});

// Leave Types Provider
final leaveTypesProvider = FutureProvider<List<LeaveType>>((ref) async {
  final service = ref.read(leaveServiceProvider);
  final data = await service.getLeaveTypes(page: 1, pageSize: 100);
  final items = data['items'] as List;
  return items.map((e) => LeaveType.fromJson(e as Map<String, dynamic>)).toList();
});

// Leave Balance Provider (family)
final leaveBalanceProvider =
    FutureProvider.family<List<LeaveBalance>, String>((ref, employeeId) async {
  final service = ref.read(leaveServiceProvider);
  return await service.getLeaveBalance(employeeId);
});
