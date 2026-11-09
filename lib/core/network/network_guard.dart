import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrintStack;

import '../config/app_config.dart';
import '../error/failure.dart';
import '../error/result.dart';

/// Граница data-слоя: выполняет запрос и переводит любое исключение в
/// [Failure]. Репозитории оборачивают в неё каждый вызов data source.
Future<Result<T>> guardRequest<T>(Future<T> Function() request) async {
  try {
    return Success(await request());
  } on Failure catch (failure) {
    return Failed(failure);
  } on DioException catch (error, stackTrace) {
    final failure = error.toFailure();
    if (failure is UnknownFailure) _logUnexpected(error, stackTrace);
    return Failed(failure);
  } on FormatException catch (error, stackTrace) {
    _logUnexpected(error, stackTrace);
    return Failed(const InvalidResponseFailure());
  } catch (error, stackTrace) {
    _logUnexpected(error, stackTrace);
    return Failed(UnknownFailure(error));
  }
}

/// Пользователь видит общий текст, а причину — баг клиента или ответ вне
/// контракта — нужно видеть разработчику: в debug и `DEV_TOOLS` она идёт в
/// консоль и панель разработчика. В обычной сборке в системный лог её не
/// пишем — в ней бывают ИИН и адреса запросов.
void _logUnexpected(Object error, StackTrace stackTrace) {
  if (!AppConfig.devToolsEnabled) return;
  debugPrintStack(
    label: 'Unexpected error: $error',
    stackTrace: stackTrace,
    maxFrames: 12,
  );
}

extension DioExceptionToFailure on DioException {
  Failure toFailure() => switch (type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.transformTimeout =>
          const TimeoutFailure(),
        DioExceptionType.connectionError ||
        DioExceptionType.badCertificate =>
          const NetworkFailure(),
        DioExceptionType.badResponse => _responseFailure(response),
        DioExceptionType.cancel ||
        DioExceptionType.unknown =>
          UnknownFailure(error ?? this),
      };

  static Failure _responseFailure(Response<dynamic>? response) {
    final data = response?.data;
    final body =
        data is Map<String, dynamic> ? data : const <String, dynamic>{};
    // Технические тексты SimpleJWT («Given token not valid…») не для
    // пользователя: истёкшая сессия получает понятное сообщение.
    if (body['code'] == 'token_not_valid') return const UnauthorizedFailure();

    final message = serverMessageOf(body);
    final code = body['error_code']?.toString();
    return switch (response?.statusCode) {
      401 => UnauthorizedFailure(serverMessage: message, code: code),
      403 => ForbiddenFailure(serverMessage: message, code: code),
      404 => NotFoundFailure(serverMessage: message, code: code),
      400 ||
      409 ||
      422 =>
        ValidationFailure(serverMessage: message, code: code),
      _ => ServerFailure(serverMessage: message, code: code),
    };
  }
}

/// Текст ошибки DRF: общий `message`/`error`/`detail`, либо первая ошибка
/// поля вида `{"phone": ["Обязательное поле."]}`.
String? serverMessageOf(Map<String, dynamic> body) {
  final message =
      (body['message'] ?? body['error'] ?? body['detail'])?.toString() ??
          _firstFieldError(body);
  return message == null || message.isEmpty ? null : message;
}

String? _firstFieldError(Map<String, dynamic> body) {
  for (final value in body.values) {
    if (value is List && value.isNotEmpty) {
      final first = value.first?.toString();
      if (first != null && first.isNotEmpty) return first;
    } else if (value is String && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}
