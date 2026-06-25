import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/dio_client.dart';
import '../models/device.dart';

class CommandService {
  final Dio _dio;

  CommandService(this._dio);

  Future<Map<String, dynamic>> getCommands({
    String? deviceId,
    String? status,
    required int page,
    required int pageSize,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (deviceId != null && deviceId.isNotEmpty) queryParams['device_id'] = deviceId;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;

    final response = await _dio.get(
      '${ApiConstants.commands}/',
      queryParameters: queryParams,
    );
    return response.data;
  }

  Future<DeviceCommand> createCommand(Map<String, dynamic> data) async {
    final response = await _dio.post('${ApiConstants.commands}/', data: data);
    return DeviceCommand.fromJson(response.data);
  }

  Future<DeviceCommand> executeCommand(String commandId) async {
    final response = await _dio.post('${ApiConstants.commands}/$commandId/execute');
    return DeviceCommand.fromJson(response.data);
  }

  Future<DeviceCommand> getCommand(String commandId) async {
    final response = await _dio.get('${ApiConstants.commands}/$commandId');
    return DeviceCommand.fromJson(response.data);
  }
}

final commandServiceProvider = Provider<CommandService>((ref) {
  return CommandService(ref.read(dioProvider));
});
