import 'dart:io';

import 'package:dio/dio.dart';

enum ApiErrorType { noInternet, timeout, server, unauthorized, client, unknown }

/// User-facing messages shared by every repository.
class ApiErrorMessages {
  ApiErrorMessages._();

  static const noInternet =
      'No internet connection. Please check your network and try again.';
  static const timeout = 'Your connection is slow. Please try again.';
  static const server =
      'Something went wrong on our side. Please try again in a while.';
  static const sessionExpired = 'Your session has expired. Please log in again.';
  static const generic = 'Something went wrong. Please try again.';
}

/// Typed exception thrown by repositories on any API failure,
/// so controllers/UI never need to know about Dio.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.type = ApiErrorType.unknown,
  });

  final String message;
  final int? statusCode;
  final ApiErrorType type;

  /// Maps a Dio failure to a user-facing message. [fallback] is used for
  /// 4xx responses that carry no readable message of their own.
  factory ApiException.fromDio(DioException e, [String? fallback]) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          ApiErrorMessages.timeout,
          type: ApiErrorType.timeout,
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          ApiErrorMessages.noInternet,
          type: ApiErrorType.noInternet,
        );
      case DioExceptionType.unknown when e.error is SocketException:
        return const ApiException(
          ApiErrorMessages.noInternet,
          type: ApiErrorType.noInternet,
        );
      case DioExceptionType.badResponse:
        return _fromResponse(e, fallback);
      default:
        return ApiException(fallback ?? ApiErrorMessages.generic);
    }
  }

  static ApiException _fromResponse(DioException e, String? fallback) {
    final status = e.response?.statusCode ?? 0;
    final serverMessage = _messageFromBody(e.response?.data);

    // 5xx bodies are usually an HTML error page — never worth showing.
    if (status >= 500) {
      return ApiException(
        ApiErrorMessages.server,
        statusCode: status,
        type: ApiErrorType.server,
      );
    }

    if (status == 401) {
      return ApiException(
        serverMessage ?? ApiErrorMessages.sessionExpired,
        statusCode: status,
        type: ApiErrorType.unauthorized,
      );
    }

    final defaultMessage = switch (status) {
      403 => "You don't have permission to do this.",
      404 => 'The requested information could not be found.',
      429 => 'Too many attempts. Please wait a moment and try again.',
      _ => ApiErrorMessages.generic,
    };
    return ApiException(
      serverMessage ?? fallback ?? defaultMessage,
      statusCode: status,
      type: ApiErrorType.client,
    );
  }

  /// Reads `message` / `error` / `detail`, then falls back to Django REST
  /// Framework validation errors: `{"field": ["msg", ...]}`.
  static String? _messageFromBody(Object? data) {
    if (data is! Map) return null;

    for (final key in const ['message', 'error', 'detail']) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) return value;
      if (value is List && value.isNotEmpty && value.first is String) {
        return value.first as String;
      }
    }

    for (final entry in data.entries) {
      final value = entry.value;
      if (value is! List || value.isEmpty || value.first is! String) continue;
      return value.first as String;
    }
    return null;
  }

  @override
  String toString() => message;
}
