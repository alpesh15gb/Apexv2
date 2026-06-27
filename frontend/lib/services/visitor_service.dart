import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/dio_client.dart';
import '../models/visitor.dart';

class VisitorService {
  final Dio _dio;

  VisitorService(this._dio);

  Future<Map<String, dynamic>> getVisitors({
    required int page,
    required int pageSize,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _dio.get(
      '${ApiConstants.visitors}/',
      queryParameters: queryParams,
    );
    return response.data;
  }

  Future<Visitor> registerVisitor(Map<String, dynamic> data) async {
    final response = await _dio.post('${ApiConstants.visitors}/', data: data);
    return Visitor.fromJson(response.data);
  }

  Future<VisitorPass> createVisitorPass(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.visitorPasses, data: data);
    return VisitorPass.fromJson(response.data);
  }

  Future<VisitorPass> checkIn(String passId) async {
    final response = await _dio.post('${ApiConstants.visitors}/passes/$passId/check-in');
    return VisitorPass.fromJson(response.data);
  }

  Future<VisitorPass> checkOut(String passId) async {
    final response = await _dio.post('${ApiConstants.visitors}/passes/$passId/check-out');
    return VisitorPass.fromJson(response.data);
  }

  Future<List<VisitorPass>> getActiveVisitors() async {
    final response = await _dio.get(ApiConstants.activeVisitors);
    final list = response.data as List;
    return list.map((e) => VisitorPass.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<VisitorPass> getVisitorPass(String passId) async {
    final response = await _dio.get('${ApiConstants.visitorPasses}/$passId');
    return VisitorPass.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getVisitorPasses({
    required int page,
    required int pageSize,
    String? status,
    String? hostEmployeeId,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (hostEmployeeId != null && hostEmployeeId.isNotEmpty) {
      queryParams['host_employee_id'] = hostEmployeeId;
    }
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _dio.get(
      ApiConstants.visitorPasses,
      queryParameters: queryParams,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getVisitorHistory({
    required int page,
    required int pageSize,
    String? fromDate,
    String? toDate,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (fromDate != null && fromDate.isNotEmpty) queryParams['from_date'] = fromDate;
    if (toDate != null && toDate.isNotEmpty) queryParams['to_date'] = toDate;

    final response = await _dio.get(
      ApiConstants.visitorHistory,
      queryParameters: queryParams,
    );
    return response.data;
  }
}

final visitorServiceProvider = Provider<VisitorService>((ref) {
  return VisitorService(ref.read(dioProvider));
});
