import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'constants.dart';
import 'secure_storage.dart';

String _getBaseUrl() {
  if (kIsWeb) {
    return ApiConstants.baseUrl;
  }
  return ApiConstants.desktopBaseUrl;
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: _getBaseUrl(),
      connectTimeout: AppConstants.connectionTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await secureStorage.read(StorageKeys.accessToken);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        // Extract meaningful error message from response body
        if (error.response?.statusCode != null && error.response?.data != null) {
          final data = error.response!.data;
          String message;
          if (data is Map) {
            message = data['detail'] ?? data['message'] ?? data['error'] ?? 'Request failed (${error.response!.statusCode})';
          } else if (data is String && data.isNotEmpty) {
            message = data.length > 200 ? 'Server error (${error.response!.statusCode})' : data;
          } else {
            message = 'Request failed (${error.response!.statusCode})';
          }
          return handler.reject(DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            message: message,
            error: message,
          ));
        }

        // Network and timeout errors
        String message;
        switch (error.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            message = 'Connection timed out. Please check your internet and try again.';
            break;
          case DioExceptionType.connectionError:
            message = 'Cannot connect to server. Please check if the service is running.';
            break;
          case DioExceptionType.cancel:
            message = 'Request was cancelled.';
            break;
          default:
            if (error.type == DioExceptionType.unknown && 
                error.error != null && 
                error.error.toString().contains('SystemLiteral')) {
              message = 'Server returned an invalid response. Check if the API server is running.';
            } else {
              message = 'An unexpected error occurred. Please try again.';
            }
        }
        return handler.reject(DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          type: error.type,
          message: message,
          error: message,
        ));
      },
            error.requestOptions.path != ApiConstants.login &&
            error.requestOptions.path != ApiConstants.refresh) {
          
          final refreshToken = await secureStorage.read(StorageKeys.refreshToken);
          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              // Try to refresh token
              final refreshResponse = await Dio(
                BaseOptions(
                  baseUrl: _getBaseUrl(),
                  headers: {'Content-Type': 'application/json'},
                ),
              ).post(
                ApiConstants.refresh,
                data: {'refresh_token': refreshToken},
              );

              if (refreshResponse.statusCode == 200 || refreshResponse.statusCode == 201) {
                final data = refreshResponse.data;
                final newAccessToken = data['access_token'];
                final newRefreshToken = data['refresh_token'];

                if (newAccessToken != null && newRefreshToken != null) {
                  await secureStorage.write(StorageKeys.accessToken, newAccessToken);
                  await secureStorage.write(StorageKeys.refreshToken, newRefreshToken);

                  // Retry the original request
                  final originalOptions = error.requestOptions;
                  originalOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                  
                  final response = await dio.fetch(originalOptions);
                  return handler.resolve(response);
                }
              }
            } catch (e) {
              // Refresh failed, clean up and let the error propagate (should trigger logout)
              await secureStorage.delete(StorageKeys.accessToken);
              await secureStorage.delete(StorageKeys.refreshToken);
            }
          }
        }
        return handler.next(error);
      },
    ),
  );

  // Add Pretty Logger in debug mode
  dio.interceptors.add(
    PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 90,
    ),
  );

  return dio;
});
