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
      // ignore: avoid_print
      print('EmployeeProvider error: $e');
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
class DepartmentListNotifier extends StateNotifier<AsyncValue<List<Department>>> {
  final EmployeeService _service;
  DepartmentListNotifier(this._service) : super(const AsyncValue.loading()) { fetchDepartments(); }

  Future<void> fetchDepartments({bool isRefresh = false}) async {
    if (isRefresh) state = const AsyncValue.loading();
    try {
      final data = await _service.getDepartments(page: 1, pageSize: 100);
      final items = (data['items'] as List).map((e) => Department.fromJson(e as Map<String, dynamic>)).toList();
      state = AsyncValue.data(items);
    } catch (e, stack) { state = AsyncValue.error(e, stack); }
  }

  Future<void> addDepartment(Map<String, dynamic> data) async {
    final dept = await _service.createDepartment(data);
    if (state.value != null) state = AsyncValue.data([dept, ...state.value!]);
  }

  Future<void> updateDepartment(String id, Map<String, dynamic> data) async {
    final updated = await _service.updateDepartment(id, data);
    if (state.value != null) state = AsyncValue.data(state.value!.map((d) => d.id == id ? updated : d).toList());
  }

  Future<void> deleteDepartment(String id) async {
    await _service.deleteDepartment(id);
    if (state.value != null) state = AsyncValue.data(state.value!.where((d) => d.id != id).toList());
  }
}

final departmentsProvider = StateNotifierProvider<DepartmentListNotifier, AsyncValue<List<Department>>>((ref) {
  return DepartmentListNotifier(ref.read(employeeServiceProvider));
});

// Branches Provider
class BranchListNotifier extends StateNotifier<AsyncValue<List<Branch>>> {
  final EmployeeService _service;
  BranchListNotifier(this._service) : super(const AsyncValue.loading()) { fetchBranches(); }

  Future<void> fetchBranches({bool isRefresh = false}) async {
    if (isRefresh) state = const AsyncValue.loading();
    try {
      final data = await _service.getBranches(page: 1, pageSize: 100);
      final items = (data['items'] as List).map((e) => Branch.fromJson(e as Map<String, dynamic>)).toList();
      state = AsyncValue.data(items);
    } catch (e, stack) { state = AsyncValue.error(e, stack); }
  }

  Future<void> addBranch(Map<String, dynamic> data) async {
    final branch = await _service.createBranch(data);
    if (state.value != null) state = AsyncValue.data([branch, ...state.value!]);
  }

  Future<void> updateBranch(String id, Map<String, dynamic> data) async {
    final updated = await _service.updateBranch(id, data);
    if (state.value != null) state = AsyncValue.data(state.value!.map((b) => b.id == id ? updated : b).toList());
  }

  Future<void> deleteBranch(String id) async {
    await _service.deleteBranch(id);
    if (state.value != null) state = AsyncValue.data(state.value!.where((b) => b.id != id).toList());
  }
}

final branchesProvider = StateNotifierProvider<BranchListNotifier, AsyncValue<List<Branch>>>((ref) {
  return BranchListNotifier(ref.read(employeeServiceProvider));
});

// Designations Provider
class DesignationListNotifier extends StateNotifier<AsyncValue<List<Designation>>> {
  final EmployeeService _service;
  DesignationListNotifier(this._service) : super(const AsyncValue.loading()) { fetchDesignations(); }

  Future<void> fetchDesignations({bool isRefresh = false}) async {
    if (isRefresh) state = const AsyncValue.loading();
    try {
      final data = await _service.getDesignations(page: 1, pageSize: 100);
      final items = (data['items'] as List).map((e) => Designation.fromJson(e as Map<String, dynamic>)).toList();
      state = AsyncValue.data(items);
    } catch (e, stack) { state = AsyncValue.error(e, stack); }
  }

  Future<void> addDesignation(Map<String, dynamic> data) async {
    final desg = await _service.createDesignation(data);
    if (state.value != null) state = AsyncValue.data([desg, ...state.value!]);
  }

  Future<void> updateDesignation(String id, Map<String, dynamic> data) async {
    final updated = await _service.updateDesignation(id, data);
    if (state.value != null) state = AsyncValue.data(state.value!.map((d) => d.id == id ? updated : d).toList());
  }

  Future<void> deleteDesignation(String id) async {
    await _service.deleteDesignation(id);
    if (state.value != null) state = AsyncValue.data(state.value!.where((d) => d.id != id).toList());
  }
}

final designationsProvider = StateNotifierProvider<DesignationListNotifier, AsyncValue<List<Designation>>>((ref) {
  return DesignationListNotifier(ref.read(employeeServiceProvider));
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
