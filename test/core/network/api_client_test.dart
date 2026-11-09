import 'dart:convert';
import 'dart:typed_data';

import 'package:avatracker_mobile/core/network/api_client.dart';
import 'package:avatracker_mobile/core/error/failure.dart';
import 'package:avatracker_mobile/core/network/network_guard.dart';
import 'package:avatracker_mobile/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

enum _RefreshMode { rotate, offline, badGateway }

/// Мини-SimpleJWT как в production: refresh ротируется, старый refresh
/// после использования попадает в blacklist (повторно → 401 token_not_valid).
/// Защищённые эндпоинты принимают только выданные сервером access-токены.
class _FakeJwtServer implements HttpClientAdapter {
  _FakeJwtServer(
      {this.refreshMode = _RefreshMode.rotate, this.slowPaths = const {}});

  final _RefreshMode refreshMode;

  /// Пути, ответ на которые приходит заметно позже остальных.
  final Set<String> slowPaths;

  final validAccess = <String>{};
  final validRefresh = <String>{'refresh-1'};
  int refreshCalls = 0;
  var _seq = 1;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    final slow = slowPaths.any(path.endsWith);
    await Future<void>.delayed(Duration(milliseconds: slow ? 200 : 20));

    if (path.endsWith('/auth/token/refresh/')) {
      refreshCalls++;
      switch (refreshMode) {
        case _RefreshMode.offline:
          throw DioException.connectionError(
            requestOptions: options,
            reason: 'offline',
          );
        case _RefreshMode.badGateway:
          return ResponseBody.fromString('<html>502 Bad Gateway</html>', 502);
        case _RefreshMode.rotate:
          break;
      }
      final refresh = (options.data as Map)['refresh'];
      if (!validRefresh.remove(refresh)) {
        return _json(401, {
          'detail': 'Token is blacklisted',
          'code': 'token_not_valid',
        });
      }
      _seq++;
      validAccess.add('access-$_seq');
      validRefresh.add('refresh-$_seq');
      return _json(200, {'access': 'access-$_seq', 'refresh': 'refresh-$_seq'});
    }

    final header = options.headers['Authorization'];
    if (header is String && validAccess.contains(header.substring(7))) {
      return _json(200, {'ok': true});
    }
    return _json(401, {
      'detail': 'Given token not valid for any token type',
      'code': 'token_not_valid',
    });
  }

  static ResponseBody _json(int status, Map<String, dynamic> body) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

Future<DioException> _dioError(Future<Object?> request) async {
  try {
    await request;
  } on DioException catch (e) {
    return e;
  }
  fail('Ожидалась DioException');
}

void main() {
  late TokenStorage storage;
  late int sessionExpiredCalls;

  Dio dioFor(_FakeJwtServer server) {
    final client = ApiClient(
      storage: storage,
      onSessionExpired: () async => sessionExpiredCalls++,
    );
    client.dio.httpClientAdapter = server;
    return client.dio;
  }

  setUp(() {
    // Access истёк (сервер его не знает), refresh ещё живой.
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'access-expired',
      'refresh_token': 'refresh-1',
      'iin': '900101300123',
    });
    storage = TokenStorage();
    sessionExpiredCalls = 0;
  });

  test('параллельные 401 ждут один refresh и не выкидывают из аккаунта',
      () async {
    final server = _FakeJwtServer();
    final dio = dioFor(server);

    // Табель/аналитика грузят отметки и опоздания одновременно.
    final responses = await Future.wait([
      dio.get<dynamic>('/employee-identification-list/'),
      dio.get<dynamic>('/tardiness/'),
      dio.get<dynamic>('/employees/900101300123/'),
    ]);

    expect(responses.map((r) => r.statusCode), everyElement(200));
    expect(server.refreshCalls, 1);
    expect(sessionExpiredCalls, 0);
    expect(await storage.accessToken, 'access-2');
    expect(await storage.refreshToken, 'refresh-2');
  });

  test('ответ 401 на старый токен после refresh — повтор без второго refresh',
      () async {
    final server = _FakeJwtServer(slowPaths: {'/tardiness/'});
    final dio = dioFor(server);

    final responses = await Future.wait([
      dio.get<dynamic>('/employee-identification-list/'),
      dio.get<dynamic>('/tardiness/'),
    ]);

    expect(responses.map((r) => r.statusCode), everyElement(200));
    expect(server.refreshCalls, 1);
    expect(sessionExpiredCalls, 0);
  });

  test('нет сети во время refresh — ошибка соединения, сессия сохраняется',
      () async {
    final server = _FakeJwtServer(refreshMode: _RefreshMode.offline);
    final dio = dioFor(server);

    final error = await _dioError(dio.get<dynamic>('/tardiness/'));

    expect(error.toFailure(), isA<NetworkFailure>());
    expect(sessionExpiredCalls, 0);
    expect(await storage.accessToken, 'access-expired');
    expect(await storage.refreshToken, 'refresh-1');
  });

  test('5xx на refresh — не выход, а ошибка соединения', () async {
    final server = _FakeJwtServer(refreshMode: _RefreshMode.badGateway);
    final dio = dioFor(server);

    final error = await _dioError(dio.get<dynamic>('/tardiness/'));

    expect(error.toFailure(), isA<NetworkFailure>());
    expect(sessionExpiredCalls, 0);
    expect(await storage.refreshToken, 'refresh-1');
  });

  test('отозванный refresh завершает сессию ровно один раз', () async {
    final server = _FakeJwtServer()..validRefresh.clear();
    final dio = dioFor(server);

    final errors = await Future.wait([
      _dioError(dio.get<dynamic>('/employee-identification-list/')),
      _dioError(dio.get<dynamic>('/tardiness/')),
    ]);

    for (final error in errors) {
      expect(error.response?.statusCode, 401);
    }
    expect(server.refreshCalls, 1);
    expect(sessionExpiredCalls, 1);
  });
}
