import 'package:avatracker_mobile/core/error/failure.dart';
import 'package:avatracker_mobile/core/error/result.dart';
import 'package:avatracker_mobile/core/network/network_guard.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show DebugPrintCallback, debugPrint;
import 'package:flutter_test/flutter_test.dart';

DioException _response(int status, [Object? body]) {
  final options = RequestOptions(path: '/x');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: status, data: body),
  );
}

void main() {
  group('DioException → Failure', () {
    test('таймауты и обрыв соединения', () {
      final options = RequestOptions(path: '/x');
      expect(
        DioException.connectionTimeout(
          timeout: const Duration(seconds: 1),
          requestOptions: options,
        ).toFailure(),
        isA<TimeoutFailure>(),
      );
      expect(
        DioException.receiveTimeout(
          timeout: const Duration(seconds: 1),
          requestOptions: options,
        ).toFailure(),
        isA<TimeoutFailure>(),
      );
      expect(
        DioException.connectionError(requestOptions: options, reason: 'x')
            .toFailure(),
        isA<NetworkFailure>(),
      );
    });

    test('технический 401 SimpleJWT не показывается пользователю', () {
      final failure = _response(401, {
        'detail': 'Given token not valid for any token type',
        'code': 'token_not_valid',
      }).toFailure();

      expect(failure, isA<UnauthorizedFailure>());
      expect((failure as UnauthorizedFailure).serverMessage, isNull);
    });

    test('401 входа сохраняет текст сервера', () {
      final failure = _response(401, {
        'detail': 'Неверный номер телефона или пароль',
      }).toFailure() as UnauthorizedFailure;

      expect(failure.serverMessage, 'Неверный номер телефона или пароль');
    });

    test('ошибка поля DRF и error_code', () {
      final failure = _response(400, {
        'phone': ['Обязательное поле.'],
        'error_code': 'INVALID_PHONE',
      }).toFailure() as ValidationFailure;

      expect(failure.serverMessage, 'Обязательное поле.');
      expect(failure.code, 'INVALID_PHONE');
    });

    test('статус определяет тип ошибки', () {
      expect(_response(403).toFailure(), isA<ForbiddenFailure>());
      expect(_response(404).toFailure(), isA<NotFoundFailure>());
      expect(_response(422).toFailure(), isA<ValidationFailure>());
      final server = _response(502, '<html>502</html>').toFailure();
      expect(server, isA<ServerFailure>());
      expect((server as ServerFailure).serverMessage, isNull);
    });
  });

  group('guardRequest', () {
    // Причина непредвиденной ошибки идёт в лог разработчика — собираем её
    // здесь, а не в вывод тестов.
    final logged = <String>[];
    late DebugPrintCallback originalDebugPrint;
    setUp(() {
      logged.clear();
      originalDebugPrint = debugPrint;
      debugPrint = (message, {wrapWidth}) => logged.add(message ?? '');
    });
    tearDown(() => debugPrint = originalDebugPrint);

    test('значение оборачивается в Success', () async {
      final result = await guardRequest(() async => 42);
      expect((result as Success<int>).value, 42);
    });

    test('Failure из data source проходит как есть', () async {
      final result = await guardRequest<int>(
        () async => throw const EmployeeNotFoundFailure(),
      );
      expect((result as Failed).failure, isA<EmployeeNotFoundFailure>());
    });

    test('ошибка формата — InvalidResponseFailure', () async {
      final result = await guardRequest<int>(
        () async => throw const FormatException('bad'),
      );
      expect((result as Failed).failure, isA<InvalidResponseFailure>());
    });

    test('прочее — UnknownFailure с причиной, причина видна в логе', () async {
      final error = StateError('boom');
      final result = await guardRequest<int>(() async => throw error);
      final failure = (result as Failed).failure as UnknownFailure;
      expect(failure.cause, same(error));
      expect(logged.join('\n'), contains('boom'));
    });
  });
}
