import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/dio_client.dart';
import '../models/dashboard.dart';

class DashboardService {
  final Dio _dio;

  DashboardService(this._dio);

  Future<DashboardStats> getStats({String? dateStr}) async {
    final queryParams = <String, dynamic>{};
    if (dateStr != null) queryParams['date'] = dateStr;

    final response = await _dio.get(
      ApiConstants.dashboardStats,
      queryParameters: queryParams,
    );
    return DashboardStats.fromJson(response.data);
  }

  Future<List<AttendanceTrend>> getAttendanceChart({int days = 30}) async {
    final response = await _dio.get(
      ApiConstants.dashboardChart,
      queryParameters: {'days': days},
    );
    final list = response.data as List;
    return list.map((e) => AttendanceTrend.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<RecentActivity>> getRecentActivity({int limit = 20}) async {
    final response = await _dio.get(
      ApiConstants.dashboardRecentActivity,
      queryParameters: {'limit': limit},
    );
    final list = response.data as List;
    return list.map((e) => RecentActivity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AttendanceHeatmapItem>> getAttendanceHeatmap({int days = 30}) async {
    final response = await _dio.get(
      ApiConstants.dashboardHeatmap,
      queryParameters: {'days': days},
    );
    final list = response.data as List;
    return list.map((e) => AttendanceHeatmapItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<LeaveCalendarItem>> getLeaveCalendar({int? year, int? month}) async {
    final queryParams = <String, dynamic>{};
    if (year != null) queryParams['year'] = year;
    if (month != null) queryParams['month'] = month;

    final response = await _dio.get(
      ApiConstants.dashboardLeaveCalendar,
      queryParameters: queryParams,
    );
    final list = response.data as List;
    return list.map((e) => LeaveCalendarItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<BirthdayItem>> getBirthdays() async {
    final response = await _dio.get(ApiConstants.dashboardBirthdays);
    final list = response.data as List;
    return list.map((e) => BirthdayItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AnniversaryItem>> getAnniversaries() async {
    final response = await _dio.get(ApiConstants.dashboardAnniversaries);
    final list = response.data as List;
    return list.map((e) => AnniversaryItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<DepartmentDistribution>> getDepartmentDistribution() async {
    final response = await _dio.get(ApiConstants.dashboardDepartmentDistribution);
    final list = response.data as List;
    return list.map((e) => DepartmentDistribution.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MonthlyTrend>> getMonthlyTrend({int months = 6}) async {
    final response = await _dio.get(
      ApiConstants.dashboardMonthlyTrend,
      queryParameters: {'months': months},
    );
    final list = response.data as List;
    return list.map((e) => MonthlyTrend.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SyncHealthStatus> getSyncHealth() async {
    final response = await _dio.get(ApiConstants.dashboardSyncHealth);
    return SyncHealthStatus.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> getRecentPunchLogs({int limit = 10}) async {
    final response = await _dio.get('/attendance/punch-logs', queryParameters: {'page': 1, 'page_size': limit});
    final data = response.data;
    if (data is Map && data.containsKey('items')) {
      return List<Map<String, dynamic>>.from(data['items']);
    }
    return [];
  }
}

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService(ref.read(dioProvider));
});
