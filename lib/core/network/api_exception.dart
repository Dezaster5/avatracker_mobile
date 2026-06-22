import 'package:dio/dio.dart';

/// Единое исключение слоя API с человекочитаемым сообщением (тексты — по ТЗ).
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.details,
  });

  final String message;

  /// Машинный код ошибки из API, например `OUT_OF_RADIUS`.
  final String? code;
  final int? statusCode;
  final Map<String, dynamic>? details;

  factory ApiException.fromDio(DioException e) {
    final response = e.response;
    final data = response?.data;
    if (data is Map<String, dynamic>) {
      final message =
          (data['message'] ?? data['error'] ?? data['detail'])?.toString();
      if (message != null && message.isNotEmpty) {
        return ApiException(
          message: message,
          code: data['error_code']?.toString(),
          statusCode: response?.statusCode,
          details: data,
        );
      }
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'Ошибка соединения. Попробуйте позже',
          statusCode: response?.statusCode,
        );
      default:
        if (response?.statusCode == 401) {
          return const ApiException(
            message: 'Сессия истекла. Войдите заново',
            statusCode: 401,
          );
        }
        return ApiException(
          message: 'Нет соединения с сервером',
          statusCode: response?.statusCode,
        );
    }
  }

  @override
  String toString() => message;
}
