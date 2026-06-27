import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/dio_client.dart';
import '../models/employee.dart';

class EmployeeService {
  final Dio _dio;

  EmployeeService(this._dio);

  Future<Map<String, dynamic>> getEmployees({
    required int page,
    required int pageSize,
    String? search,
    String? departmentId,
    String? branchId,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (departmentId != null && departmentId.isNotEmpty) queryParams['department_id'] = departmentId;
    if (branchId != null && branchId.isNotEmpty) queryParams['branch_id'] = branchId;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;

    final response = await _dio.get(
      ApiConstants.employees,
      queryParameters: queryParams,
    );
    return response.data;
  }

  Future<Employee> getEmployee(String employeeId) async {
    final response = await _dio.get('${ApiConstants.employees}/$employeeId');
    return Employee.fromJson(response.data);
  }

  Future<Employee> createEmployee(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.employees, data: data);
    return Employee.fromJson(response.data);
  }

  Future<Employee> updateEmployee(String employeeId, Map<String, dynamic> data) async {
    final response = await _dio.put('${ApiConstants.employees}/$employeeId', data: data);
    return Employee.fromJson(response.data);
  }

  Future<void> deleteEmployee(String employeeId) async {
    await _dio.delete('${ApiConstants.employees}/$employeeId');
  }

  Future<Map<String, dynamic>> getDepartments({int page = 1, int pageSize = 100}) async {
    final response = await _dio.get(
      ApiConstants.departments,
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return response.data;
  }

  Future<Department> createDepartment(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.departments, data: data);
    return Department.fromJson(response.data);
  }

  Future<Department> updateDepartment(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('${ApiConstants.departments}/$id', data: data);
    return Department.fromJson(response.data);
  }

  Future<void> deleteDepartment(String id) async {
    await _dio.delete('${ApiConstants.departments}/$id');
  }

  Future<Map<String, dynamic>> getDesignations({int page = 1, int pageSize = 100}) async {
    final response = await _dio.get(
      ApiConstants.designations,
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return response.data;
  }

  Future<Designation> createDesignation(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.designations, data: data);
    return Designation.fromJson(response.data);
  }

  Future<Designation> updateDesignation(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('${ApiConstants.designations}/$id', data: data);
    return Designation.fromJson(response.data);
  }

  Future<void> deleteDesignation(String id) async {
    await _dio.delete('${ApiConstants.designations}/$id');
  }

  Future<Map<String, dynamic>> getBranches({int page = 1, int pageSize = 100}) async {
    final response = await _dio.get(
      ApiConstants.branches,
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return response.data;
  }

  Future<Branch> createBranch(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.branches, data: data);
    return Branch.fromJson(response.data);
  }

  Future<Branch> updateBranch(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('${ApiConstants.branches}/$id', data: data);
    return Branch.fromJson(response.data);
  }

  Future<void> deleteBranch(String id) async {
    await _dio.delete('${ApiConstants.branches}/$id');
  }

  Future<void> bulkImport(List<int> bytes, String fileName) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    await _dio.post(ApiConstants.bulkImport, data: formData);
  }
}

final employeeServiceProvider = Provider<EmployeeService>((ref) {
  return EmployeeService(ref.read(dioProvider));
});
