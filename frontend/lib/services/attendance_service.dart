import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/dio_client.dart';
import '../models/attendance.dart';

class AttendanceService {
  final Dio _dio;

  AttendanceService(this._dio);

  Future<DailyAttendanceSummary> getDailySummary(String dateStr) async {
    final response = await _dio.get(
      ApiConstants.dailySummary,
      queryParameters: {'date': dateStr},
    );
    return DailyAttendanceSummary.fromJson(response.data);
  }

  Future<AttendanceSummary> getEmployeeSummary(
    String employeeId, {
    required String fromDate,
    required String toDate,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.attendance}/employee/$employeeId',
      queryParameters: {
        'from_date': fromDate,
        'to_date': toDate,
      },
    );
    return AttendanceSummary.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getAttendanceRecords({
    required int page,
    required int pageSize,
    String? employeeId,
    String? departmentId,
    String? branchId,
    String? fromDate,
    String? toDate,
    String? status,
    bool? isLate,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (employeeId != null && employeeId.isNotEmpty) queryParams['employee_id'] = employeeId;
    if (departmentId != null && departmentId.isNotEmpty) queryParams['department_id'] = departmentId;
    if (branchId != null && branchId.isNotEmpty) queryParams['branch_id'] = branchId;
    if (fromDate != null && fromDate.isNotEmpty) queryParams['from_date'] = fromDate;
    if (toDate != null && toDate.isNotEmpty) queryParams['to_date'] = toDate;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (isLate != null) queryParams['is_late'] = isLate;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _dio.get(
      '${ApiConstants.attendance}/',
      queryParameters: queryParams,
    );
    return response.data;
  }

  Future<Attendance> manualMark(Map<String, dynamic> data) async {
    final response = await _dio.post(
      '${ApiConstants.attendance}/',
      data: data,
    );
    return Attendance.fromJson(response.data);
  }

  Future<void> processAttendance(String dateStr) async {
    await _dio.post(
      ApiConstants.processAttendance,
      queryParameters: {'target_date': dateStr},
    );
  }

  Future<Attendance> approveAttendance(String attendanceId) async {
    final response = await _dio.put(
      '${ApiConstants.attendance}/$attendanceId/approve',
    );
    return Attendance.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getPunchLogs({
    required int page,
    required int pageSize,
    String? employeeId,
    String? fromDate,
    String? toDate,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (employeeId != null && employeeId.isNotEmpty) queryParams['employee_id'] = employeeId;
    if (fromDate != null && fromDate.isNotEmpty) queryParams['from_date'] = fromDate;
    if (toDate != null && toDate.isNotEmpty) queryParams['to_date'] = toDate;

    final response = await _dio.get(
      ApiConstants.punchLogs,
      queryParameters: queryParams,
    );
    return response.data;
  }
}

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService(ref.read(dioProvider));
});
