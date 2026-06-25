import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/dio_client.dart';
import '../models/leave.dart';

class LeaveService {
  final Dio _dio;

  LeaveService(this._dio);

  Future<Map<String, dynamic>> getLeaveTypes({int page = 1, int pageSize = 20}) async {
    final response = await _dio.get(
      ApiConstants.leaveTypes,
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return response.data;
  }

  Future<LeaveType> createLeaveType(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.leaveTypes, data: data);
    return LeaveType.fromJson(response.data);
  }

  Future<List<LeaveBalance>> getLeaveBalance(String employeeId, {int? year}) async {
    final queryParams = <String, dynamic>{};
    if (year != null) queryParams['year'] = year;

    final response = await _dio.get(
      '${ApiConstants.leaveBalance}/$employeeId',
      queryParameters: queryParams,
    );
    final list = response.data as List;
    return list.map((e) => LeaveBalance.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<LeaveRequest> applyLeave(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.leaveApply, data: data);
    return LeaveRequest.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getLeaveRequests({
    String? employeeId,
    String? status,
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
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final response = await _dio.get(
      ApiConstants.leaveRequests,
      queryParameters: queryParams,
    );
    return response.data;
  }

  Future<LeaveRequest> approveLeave(String requestId) async {
    final response = await _dio.put('/leaves/requests/$requestId/approve');
    return LeaveRequest.fromJson(response.data);
  }

  Future<LeaveRequest> rejectLeave(String requestId, String rejectionReason) async {
    final response = await _dio.put(
      '/leaves/requests/$requestId/reject',
      data: {
        'status': 'rejected',
        'rejection_reason': rejectionReason,
      },
    );
    return LeaveRequest.fromJson(response.data);
  }

  Future<LeaveRequest> cancelLeave(String requestId) async {
    final response = await _dio.put('/leaves/requests/$requestId/cancel');
    return LeaveRequest.fromJson(response.data);
  }
}

final leaveServiceProvider = Provider<LeaveService>((ref) {
  return LeaveService(ref.read(dioProvider));
});
