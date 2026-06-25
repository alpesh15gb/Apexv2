import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/dio_client.dart';
import '../models/user.dart';

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> register({
    required String tenantName,
    required String tenantSlug,
    required String adminEmail,
    required String adminPassword,
    required String adminFullName,
  }) async {
    final response = await _dio.post(
      ApiConstants.register,
      data: {
        'tenant_name': tenantName,
        'tenant_slug': tenantSlug,
        'admin_email': adminEmail,
        'admin_password': adminPassword,
        'admin_full_name': adminFullName,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _dio.post(
      ApiConstants.refresh,
      data: {'refresh_token': refreshToken},
    );
    return response.data;
  }

  Future<User> getMe() async {
    final response = await _dio.get(ApiConstants.me);
    return User.fromJson(response.data);
  }

  Future<User> updateMe({String? fullName, String? phone, String? avatarUrl}) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (phone != null) data['phone'] = phone;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;

    final response = await _dio.put(
      ApiConstants.me,
      data: data,
    );
    return User.fromJson(response.data);
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _dio.post(
      ApiConstants.changePassword,
      data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
    );
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(dioProvider));
});
