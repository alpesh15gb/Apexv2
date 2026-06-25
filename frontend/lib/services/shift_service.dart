import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/dio_client.dart';
import '../models/shift.dart';

class ShiftService {
  final Dio _dio;

  ShiftService(this._dio);

  Future<Map<String, dynamic>> getShifts({
    required int page,
    required int pageSize,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.shifts}/',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return response.data;
  }

  Future<Shift> getShift(String shiftId) async {
    final response = await _dio.get('${ApiConstants.shifts}/$shiftId');
    return Shift.fromJson(response.data);
  }

  Future<Shift> createShift(Map<String, dynamic> data) async {
    final response = await _dio.post('${ApiConstants.shifts}/', data: data);
    return Shift.fromJson(response.data);
  }

  Future<Shift> updateShift(String shiftId, Map<String, dynamic> data) async {
    final response = await _dio.put('${ApiConstants.shifts}/$shiftId', data: data);
    return Shift.fromJson(response.data);
  }

  Future<void> deleteShift(String shiftId) async {
    await _dio.delete('${ApiConstants.shifts}/$shiftId');
  }

  Future<ShiftSchedule> assignShift(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.assignShift, data: data);
    return ShiftSchedule.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getSchedules({
    String? employeeId,
    required int page,
    required int pageSize,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (employeeId != null && employeeId.isNotEmpty) {
      queryParams['employee_id'] = employeeId;
    }

    final response = await _dio.get(
      '${ApiConstants.shifts}/schedules/',
      queryParameters: queryParams,
    );
    return response.data;
  }
}

final shiftServiceProvider = Provider<ShiftService>((ref) {
  return ShiftService(ref.read(dioProvider));
});
