import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/employee.dart';
import '../services/employee_service.dart';
import 'auth_provider.dart';

class EmployeeListState {
  final AsyncValue<List<Employee>> employees;
  final int page;
  final bool hasMore;
  final String search;
  final String? departmentId;
  final String? branchId;
  final String? status;
  final bool isLoadingMore;

  EmployeeListState({
    required this.employees,
    this.page = 1,
    this.hasMore = true,
    this.search = '',
    this.departmentId,
    this.branchId,
    this.status,
    this.isLoadingMore = false,
  });

  EmployeeListState copyWith({
    AsyncValue<List<Employee>>? employees,
    int? page,
    bool? hasMore,
    String? search,
    String? departmentId,
    String? branchId,
    String? status,
    bool? isLoadingMore,
  }) {
    return EmployeeListState(
      employees: employees ?? this.employees,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      search: search ?? this.search,
      departmentId: departmentId ?? this.departmentId,
      branchId: branchId ?? this.branchId,
      status: status ?? this.status,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class EmployeeListNotifier extends StateNotifier<EmployeeListState> {
  final EmployeeService _service;
  static const int _pageSize = 20;

  EmployeeListNotifier(this._service)
      : super(EmployeeListState(employees: const AsyncValue.loading())) {
    fetchEmployees();
  }

  Future<void> fetchEmployees({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(
        employees: const AsyncValue.loading(),
        page: 1,
        hasMore: true,
        isLoadingMore: false,
      );
    }

    if (!state.hasMore && !isRefresh) return;

    try {
      final data = await _service.getEmployees(
        page: state.page,
        pageSize: _pageSize,
        search: state.search,
        departmentId: state.departmentId,
        branchId: state.branchId,
        status: state.status,
      );

      final items = (data['items'] as List)
          .map((e) => Employee.fromJson(e as Map<String, dynamic>))
          .toList();

      final currentList = state.employees.value ?? [];
      final updatedList = isRefresh ? items : [...currentList, ...items];
      
      state = state.copyWith(
        employees: AsyncValue.data(updatedList),
        page: state.page + 1,
        hasMore: items.length >= _pageSize,
      );
    } catch (e, stack) {
      if (isRefresh || state.employees.value == null) {
        state = state.copyWith(employees: AsyncValue.error(e, stack));
      } else {
        // Just fail silently for load more or show snackbar
      }
    }
  }

  void setSearch(String search) {
    if (state.search == search) return;
    state = state.copyWith(search: search);
    fetchEmployees(isRefresh: true);
  }

  void setFilter({String? departmentId, String? branchId, String? status}) {
    state = state.copyWith(
      departmentId: departmentId,
      branchId: branchId,
      status: status,
    );
    fetchEmployees(isRefresh: true);
  }

  void clearFilters() {
    state = state.copyWith(
      departmentId: null,
      branchId: null,
      status: null,
      search: '',
    );
    fetchEmployees(isRefresh: true);
  }

  Future<void> addEmployee(Map<String, dynamic> data) async {
    final newEmp = await _service.createEmployee(data);
    if (state.employees.value != null) {
      state = state.copyWith(
        employees: AsyncValue.data([newEmp, ...state.employees.value!]),
      );
    }
  }

  Future<void> updateEmployee(String id, Map<String, dynamic> data) async {
    final updatedEmp = await _service.updateEmployee(id, data);
    if (state.employees.value != null) {
      final updated = state.employees.value!.map((e) => e.id == id ? updatedEmp : e).toList();
      state = state.copyWith(employees: AsyncValue.data(updated));
    }
  }

  Future<void> deleteEmployee(String id) async {
    await _service.deleteEmployee(id);
    if (state.employees.value != null) {
      final updated = state.employees.value!.where((e) => e.id != id).toList();
      state = state.copyWith(employees: AsyncValue.data(updated));
    }
  }
}

final employeeListProvider = StateNotifierProvider<EmployeeListNotifier, EmployeeListState>((ref) {
  final service = ref.read(employeeServiceProvider);
  return EmployeeListNotifier(service);
});

// Departments Provider
final departmentsProvider = FutureProvider<List<Department>>((ref) async {
  final service = ref.read(employeeServiceProvider);
  final data = await service.getDepartments(page: 1, pageSize: 100);
  final items = data['items'] as List;
  return items.map((e) => Department.fromJson(e as Map<String, dynamic>)).toList();
});

// Branches Provider
final branchesProvider = FutureProvider<List<Branch>>((ref) async {
  final service = ref.read(employeeServiceProvider);
  final data = await service.getBranches(page: 1, pageSize: 100);
  final items = data['items'] as List;
  return items.map((e) => Branch.fromJson(e as Map<String, dynamic>)).toList();
});

// Designations Provider
final designationsProvider = FutureProvider<List<Designation>>((ref) async {
  final service = ref.read(employeeServiceProvider);
  final data = await service.getDesignations(page: 1, pageSize: 100);
  final items = data['items'] as List;
  return items.map((e) => Designation.fromJson(e as Map<String, dynamic>)).toList();
});

// Current Employee Provider (looks up employee by current user's email)
final currentEmployeeProvider = FutureProvider<Employee?>((ref) async {
  final authAsync = ref.watch(authProvider);
  final user = authAsync.value;
  if (user == null) return null;

  final service = ref.read(employeeServiceProvider);
  final data = await service.getEmployees(
    page: 1,
    pageSize: 1,
    search: user.email,
  );
  final items = data['items'] as List;
  if (items.isEmpty) return null;
  return Employee.fromJson(items.first as Map<String, dynamic>);
});
