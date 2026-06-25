import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/dio_client.dart';
import '../models/notification.dart';

class NotificationService {
  final Dio _dio;

  NotificationService(this._dio);

  Future<Map<String, dynamic>> getNotifications({
    String? status,
    required int page,
    required int pageSize,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (status != null && status.isNotEmpty) queryParams['status'] = status;

    final response = await _dio.get(
      '${ApiConstants.notifications}/',
      queryParameters: queryParams,
    );
    return response.data;
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get('${ApiConstants.notifications}/unread-count');
    return response.data['unread_count'] as int? ?? 0;
  }

  Future<NotificationModel> markAsRead(String notificationId) async {
    final response = await _dio.put('${ApiConstants.notifications}/$notificationId/read');
    return NotificationModel.fromJson(response.data);
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.read(dioProvider));
});
