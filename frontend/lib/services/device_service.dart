import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/dio_client.dart';
import '../models/device.dart';

class DeviceService {
  final Dio _dio;

  DeviceService(this._dio);

  Future<DeviceHealth> getDeviceHealth() async {
    final response = await _dio.get(ApiConstants.deviceHealth);
    return DeviceHealth.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getDevices({
    required int page,
    required int pageSize,
  }) async {
    final response = await _dio.get(
      ApiConstants.devices,
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return response.data;
  }

  Future<Device> getDevice(String deviceId) async {
    final response = await _dio.get('${ApiConstants.devices}/$deviceId');
    return Device.fromJson(response.data);
  }

  Future<Device> createDevice(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.devices, data: data);
    return Device.fromJson(response.data);
  }

  Future<Device> updateDevice(String deviceId, Map<String, dynamic> data) async {
    final response = await _dio.put('${ApiConstants.devices}/$deviceId', data: data);
    return Device.fromJson(response.data);
  }

  Future<void> deleteDevice(String deviceId) async {
    await _dio.delete('${ApiConstants.devices}/$deviceId');
  }

  Future<Map<String, dynamic>> getDeviceLogs(String deviceId, {int page = 1, int pageSize = 20}) async {
    final response = await _dio.get(
      '${ApiConstants.devices}/$deviceId/logs',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return response.data;
  }

  Future<void> syncDevice(String deviceId) async {
    await _dio.post('${ApiConstants.devices}/$deviceId/sync');
  }
}

final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService(ref.read(dioProvider));
});
