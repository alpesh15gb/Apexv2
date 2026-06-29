import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/dio_client.dart';

class ReportService {
  final Dio _dio;

  ReportService(this._dio);

  Future<Uint8List> downloadDailyReport({required String date, required String format}) async {
    final response = await _dio.get<List<int>>(
      '/reports/attendance/daily',
      queryParameters: {'date': date, 'format': format},
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  }

  Future<Uint8List> downloadMonthlyReport({
    required int month,
    required int year,
    required String format,
  }) async {
    final response = await _dio.get<List<int>>(
      '/reports/attendance/monthly',
      queryParameters: {'month': month, 'year': year, 'format': format},
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  }

  Future<Uint8List> downloadEmployeeReport({
    required String employeeId,
    required String fromDate,
    required String toDate,
    required String format,
  }) async {
    final response = await _dio.get<List<int>>(
      '/reports/attendance/employee/$employeeId',
      queryParameters: {'from_date': fromDate, 'to_date': toDate, 'format': format},
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  }

  Future<Uint8List> downloadLateReport({
    required String fromDate,
    required String toDate,
    required String format,
  }) async {
    final response = await _dio.get<List<int>>(
      '/reports/attendance/late',
      queryParameters: {'from_date': fromDate, 'to_date': toDate, 'format': format},
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  }

  Future<Uint8List> downloadOvertimeReport({
    required String fromDate,
    required String toDate,
    required String format,
  }) async {
    final response = await _dio.get<List<int>>(
      '/reports/attendance/overtime',
      queryParameters: {'from_date': fromDate, 'to_date': toDate, 'format': format},
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  }

  Future<Uint8List> downloadAbsentReport({required String date, required String format}) async {
    final response = await _dio.get<List<int>>(
      '/reports/attendance/absent',
      queryParameters: {'date': date, 'format': format},
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  }

  Future<Uint8List> downloadVisitorReport({
    required String fromDate,
    required String toDate,
    required String format,
  }) async {
    final response = await _dio.get<List<int>>(
      '/reports/visitors',
      queryParameters: {'from_date': fromDate, 'to_date': toDate, 'format': format},
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  }

  Future<Uint8List> downloadDeviceReport({required String format}) async {
    final response = await _dio.get<List<int>>(
      '/reports/devices',
      queryParameters: {'format': format},
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  }

  Future<Uint8List> downloadEarlyGoingReport({required String fromDate, required String toDate, required String format}) async {
    final response = await _dio.get<List<int>>('/reports/attendance/early-going', queryParameters: {'from_date': fromDate, 'to_date': toDate, 'format': format}, options: Options(responseType: ResponseType.bytes));
    return Uint8List.fromList(response.data!);
  }

  Future<Uint8List> downloadMissedPunchReport({required String fromDate, required String toDate, required String format}) async {
    final response = await _dio.get<List<int>>('/reports/attendance/missed-punch', queryParameters: {'from_date': fromDate, 'to_date': toDate, 'format': format}, options: Options(responseType: ResponseType.bytes));
    return Uint8List.fromList(response.data!);
  }

  Future<Uint8List> downloadDeptSummaryReport({required String fromDate, required String toDate, required String format}) async {
    final response = await _dio.get<List<int>>('/reports/attendance/department-summary', queryParameters: {'from_date': fromDate, 'to_date': toDate, 'format': format}, options: Options(responseType: ResponseType.bytes));
    return Uint8List.fromList(response.data!);
  }

  Future<Uint8List> downloadOtSummaryReport({required int month, required int year, required String format}) async {
    final response = await _dio.get<List<int>>('/reports/attendance/ot-summary', queryParameters: {'month': month, 'year': year, 'format': format}, options: Options(responseType: ResponseType.bytes));
    return Uint8List.fromList(response.data!);
  }

  Future<Uint8List> downloadMusterRollReport({required int month, required int year, required String format}) async {
    final response = await _dio.get<List<int>>('/reports/attendance/muster-roll', queryParameters: {'month': month, 'year': year, 'format': format}, options: Options(responseType: ResponseType.bytes));
    return Uint8List.fromList(response.data!);
  }

  Future<Uint8List> downloadFilteredAttendance({
    required String date,
    String? departmentId,
    String? branchId,
    String? shiftId,
    String? status,
    String? search,
    String format = 'csv',
  }) async {
    final params = <String, dynamic>{'date': date, 'format': format};
    if (departmentId != null) params['department_id'] = departmentId;
    if (branchId != null) params['branch_id'] = branchId;
    if (shiftId != null) params['shift_id'] = shiftId;
    if (status != null) params['status'] = status;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final response = await _dio.get<List<int>>(
      '/attendance/export',
      queryParameters: params,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  }
}

final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService(ref.read(dioProvider));
});
