import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/dio_client.dart';
import '../models/essl_server.dart';

class EsslService {
  final Dio _dio;

  EsslService(this._dio);

  Future<Map<String, dynamic>> getServers({int page = 1, int pageSize = 20}) async {
    final response = await _dio.get(
      '/essl/',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return response.data;
  }

  Future<EsslServer> getServer(String serverId) async {
    final response = await _dio.get('/essl/$serverId');
    return EsslServer.fromJson(response.data);
  }

  Future<EsslServer> createServer(Map<String, dynamic> data) async {
    final response = await _dio.post('/essl/', data: data);
    return EsslServer.fromJson(response.data);
  }

  Future<EsslServer> updateServer(String serverId, Map<String, dynamic> data) async {
    final response = await _dio.put('/essl/$serverId', data: data);
    return EsslServer.fromJson(response.data);
  }

  Future<void> deleteServer(String serverId) async {
    await _dio.delete('/essl/$serverId');
  }

  Future<EsslTestResult> testConnection(String serverId) async {
    final response = await _dio.post('/essl/$serverId/test');
    return EsslTestResult.fromJson(response.data);
  }

  Future<EsslSyncHistory> syncEmployees(String serverId) async {
    final response = await _dio.post('/essl/$serverId/sync/employees');
    return EsslSyncHistory.fromJson(response.data);
  }

  Future<EsslSyncHistory> syncAttendance(String serverId) async {
    final response = await _dio.post('/essl/$serverId/sync/attendance');
    return EsslSyncHistory.fromJson(response.data);
  }

  Future<EsslSyncHistory> syncDevices(String serverId) async {
    final response = await _dio.post('/essl/$serverId/sync/devices');
    return EsslSyncHistory.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getSyncHistory(String serverId, {int page = 1, int pageSize = 20}) async {
    final response = await _dio.get(
      '/essl/$serverId/sync/history',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return response.data;
  }

  Future<List<EsslSyncDashboardStatus>> getSyncDashboard() async {
    final response = await _dio.get('/essl/dashboard/sync-status');
    return (response.data as List).map((e) => EsslSyncDashboardStatus.fromJson(e)).toList();
  }

  Future<EsslSyncHistory> initialSyncAttendance(String serverId, String fromDate, String toDate) async {
    final response = await _dio.post(
      '/essl/$serverId/sync/initial',
      queryParameters: {'from_date': fromDate, 'to_date': toDate},
    );
    return EsslSyncHistory.fromJson(response.data);
  }

  Future<SyncProgress> getSyncProgress(String serverId, String historyId) async {
    final response = await _dio.get('/essl/$serverId/sync/$historyId/progress');
    return SyncProgress.fromJson(response.data);
  }

  Future<void> pauseSync(String serverId, String historyId) async {
    await _dio.post('/essl/$serverId/sync/$historyId/pause');
  }

  Future<void> resumeSync(String serverId, String historyId) async {
    await _dio.post('/essl/$serverId/sync/$historyId/resume');
  }

  Future<void> cancelSync(String serverId, String historyId) async {
    await _dio.post('/essl/$serverId/sync/$historyId/cancel');
  }

  Future<EnterpriseSyncDashboard> getEnterpriseDashboard({int throughputDays = 7}) async {
    final response = await _dio.get(
      '/essl/dashboard/enterprise',
      queryParameters: {'throughput_days': throughputDays},
    );
    return EnterpriseSyncDashboard.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> reprocessAttendance(
    String serverId, {
    String? fromDate,
    String? toDate,
    String? employeeId,
    String? departmentId,
  }) async {
    final body = <String, dynamic>{};
    if (fromDate != null) body['from_date'] = fromDate;
    if (toDate != null) body['to_date'] = toDate;
    if (employeeId != null) body['employee_id'] = employeeId;
    if (departmentId != null) body['department_id'] = departmentId;

    final response = await _dio.post('/essl/$serverId/reprocess', data: body);
    return response.data as Map<String, dynamic>;
  }
}

final esslServiceProvider = Provider<EsslService>((ref) {
  return EsslService(ref.read(dioProvider));
});
