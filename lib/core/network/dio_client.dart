import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../config/api_config.dart';
import '../storage/secure_storage_service.dart';

/// Single Dio instance for the whole app.
/// Adds `X-API-Key` + the Bearer token on every request, retries idempotent
/// requests once on transient failures, and reports an expired session
/// (401 on a logged-in call) through [onSessionExpired].
class DioClient {
  DioClient(this._storage, {this.onSessionExpired}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'X-API-Key': ApiConfig.apiKey,
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final path = error.requestOptions.path;
          final isPublic = ApiConfig.publicPaths.any(path.contains);
          if (error.response?.statusCode == 401 && !isPublic) {
            await _storage.clear();
            onSessionExpired?.call();
          }
          handler.next(error);
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          final options = error.requestOptions;
          if (options.extra[_retriedKey] == true || !_isRetryable(error)) {
            return handler.next(error);
          }
          await Future<void>.delayed(const Duration(seconds: 1));
          options.extra[_retriedKey] = true;
          try {
            return handler.resolve(await _dio.fetch(options));
          } on DioException catch (e) {
            return handler.next(e);
          }
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  static const _retriedKey = 'retried';

  late final Dio _dio;
  final SecureStorageService _storage;
  final VoidCallback? onSessionExpired;

  Dio get dio => _dio;

  /// Only GETs are retried — a repeated POST could create a duplicate
  /// listing, booking or OTP.
  bool _isRetryable(DioException e) {
    if (e.requestOptions.method.toUpperCase() != 'GET') return false;
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.connectionError => true,
      DioExceptionType.badResponse =>
        const {502, 503, 504}.contains(e.response?.statusCode),
      _ => false,
    };
  }
}
