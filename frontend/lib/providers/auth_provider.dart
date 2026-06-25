import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/secure_storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = const AsyncValue.loading();
    try {
      final token = await secureStorage.read(StorageKeys.accessToken);
      if (token != null && token.isNotEmpty) {
        final user = await _authService.getMe();
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      // If profile fetch fails (e.g. token expired and refresh failed), log out
      await secureStorage.delete(StorageKeys.accessToken);
      await secureStorage.delete(StorageKeys.refreshToken);
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final result = await _authService.login(email, password);
      final accessToken = result['access_token'] as String;
      final refreshToken = result['refresh_token'] as String;

      await secureStorage.write(StorageKeys.accessToken, accessToken);
      await secureStorage.write(StorageKeys.refreshToken, refreshToken);

      final user = await _authService.getMe();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> register({
    required String tenantName,
    required String tenantSlug,
    required String adminEmail,
    required String adminPassword,
    required String adminFullName,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.register(
        tenantName: tenantName,
        tenantSlug: tenantSlug,
        adminEmail: adminEmail,
        adminPassword: adminPassword,
        adminFullName: adminFullName,
      );
      // Registration successful, transition to Login screen by setting state to null
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await secureStorage.delete(StorageKeys.accessToken);
      await secureStorage.delete(StorageKeys.refreshToken);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProfile({String? fullName, String? phone, String? avatarUrl}) async {
    if (state.value == null) return;
    try {
      final updatedUser = await _authService.updateMe(
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      state = AsyncValue.data(updatedUser);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final authService = ref.read(authServiceProvider);
  return AuthNotifier(authService);
});
