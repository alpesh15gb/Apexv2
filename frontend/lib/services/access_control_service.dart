import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/dio_client.dart';
import '../models/access_control.dart';

class AccessControlService {
  final Dio _dio;

  AccessControlService(this._dio);

  Future<Map<String, dynamic>> getAccessZones({
    required int page,
    required int pageSize,
  }) async {
    final response = await _dio.get(
      ApiConstants.accessZones,
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return response.data;
  }

  Future<AccessZone> createAccessZone(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.accessZones, data: data);
    return AccessZone.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getDoors({
    required int page,
    required int pageSize,
    String? zoneId,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (zoneId != null && zoneId.isNotEmpty) queryParams['zone_id'] = zoneId;

    final response = await _dio.get(
      ApiConstants.accessDoors,
      queryParameters: queryParams,
    );
    return response.data;
  }

  Future<Door> createDoor(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.accessDoors, data: data);
    return Door.fromJson(response.data);
  }

  Future<UserAccessLevel> grantAccess(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.accessGrant, data: data);
    return UserAccessLevel.fromJson(response.data);
  }

  Future<void> revokeAccess(String accessLevelId) async {
    await _dio.delete('${ApiConstants.accessGrant}/$accessLevelId');
  }

  Future<Map<String, dynamic>> checkAccess(String employeeId, String doorId) async {
    final response = await _dio.get(
      ApiConstants.accessCheck,
      queryParameters: {
        'employee_id': employeeId,
        'door_id': doorId,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getAccessLogs({
    required int page,
    required int pageSize,
    String? fromDate,
    String? toDate,
    bool? granted,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (fromDate != null && fromDate.isNotEmpty) queryParams['from_date'] = fromDate;
    if (toDate != null && toDate.isNotEmpty) queryParams['to_date'] = toDate;
    if (granted != null) queryParams['granted'] = granted;

    final response = await _dio.get(
      ApiConstants.accessLogs,
      queryParameters: queryParams,
    );
    return response.data;
  }
}

final accessControlServiceProvider = Provider<AccessControlService>((ref) {
  return AccessControlService(ref.read(dioProvider));
});
