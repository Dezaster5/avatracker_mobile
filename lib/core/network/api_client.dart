import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../devtools/dev_http_interceptor.dart';
import '../storage/token_storage.dart';
import 'api_endpoints.dart';
import 'mock_interceptor.dart';

typedef OnSessionExpired = Future<void> Function();

/// Итог попытки обновить JWT.
enum _RefreshOutcome {
  /// Новая пара токенов сохранена.
  refreshed,

  /// Сервер отклонил refresh-токен (истёк/отозван) — сессия закончилась.
  rejected,

  /// Сервер недоступен (нет сети, таймаут, 5xx) — сессию не трогаем.
  unavailable,
}

/// Bearer для обеих схем; refresh применяется только к сохранённым JWT.
class ApiClient {
  ApiClient({required TokenStorage storage, OnSessionExpired? onSessionExpired})
      : _storage = storage,
        _onSessionExpired = onSessionExpired {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {'Accept': 'application/json'},
      ),
    );
    if (AppConfig.mockApi) {
      _dio.interceptors.add(MockInterceptor());
    }
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
    if (AppConfig.devToolsEnabled) {
      _dio.interceptors.add(DevHttpInterceptor());
    }
  }

  late final Dio _dio;
  final TokenStorage _storage;
  final OnSessionExpired? _onSessionExpired;

  /// Идущее сейчас обновление токена. Параллельные 401 ждут его, а не
  /// запускают свои: SimpleJWT с ротацией отзывает refresh после первого
  /// использования, и второй refresh тем же токеном получил бы 401 — то есть
  /// ложный выход из аккаунта.
  Future<_RefreshOutcome>? _refreshing;

  Dio get dio => _dio;

  /// Публичные (без токена) эндпоинты мобильного auth-API. Сопоставляем по
  /// суффиксу пути, т.к. auth-вызовы идут на абсолютные URL `…/api/mobile/…`.
  static bool _isPublicAuth(String path) {
    final p = Uri.parse(path).path;
    return p.contains('/auth/login') ||
        p.contains('/auth/register') ||
        p.contains('/auth/token/refresh') ||
        p.contains('/password-reset/');
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublicAuth(options.path)) {
      // Не отправляем токен, который прямо сейчас заменяется.
      final pending = _refreshing;
      if (pending != null) await pending;
      // Logout привязан к ключу, с которым пользователь начал выход.
      if (Uri.parse(options.path).path.endsWith('/auth/logout/') &&
          options.headers['Authorization'] != null) {
        return handler.next(options);
      }
      final token = await _storage.accessToken;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      } else {
        options.headers.remove('Authorization');
      }
    } else {
      options.headers.remove('Authorization');
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final is401 = err.response?.statusCode == 401;
    final isPublic = _isPublicAuth(err.requestOptions.path);
    final alreadyRetried = err.requestOptions.extra['retried'] == true;
    // Logout сам обрабатывает 401. Не запускаем из него повторный выход.
    final isLogout =
        Uri.parse(err.requestOptions.path).path.endsWith('/auth/logout/');
    if (!is401 || isPublic || isLogout) {
      return handler.next(err);
    }

    // Пока запрос был в пути, токен мог уже обновить параллельный запрос —
    // тогда достаточно повторить с новым, второй refresh не нужен.
    final session = await _storage.readSession();
    final current = session.access;
    if (current == null || current.isEmpty) return handler.next(err);
    final tokenUnchanged = current == _sentToken(err.requestOptions);
    if (tokenUnchanged && session.scheme == AuthScheme.opaque) {
      await _expireSession(current);
      return handler.next(err);
    }
    if (alreadyRetried) return handler.next(err);
    if (tokenUnchanged) {
      switch (await _refreshOnce(session)) {
        case _RefreshOutcome.refreshed:
          break;
        case _RefreshOutcome.rejected:
          return handler.next(err);
        case _RefreshOutcome.unavailable:
          // Это ошибка связи, а не «сессия истекла»: ApiException покажет
          // «Ошибка соединения», токены остаются — следующий запрос повторит
          // refresh.
          return handler.next(
            DioException.connectionError(
              requestOptions: err.requestOptions,
              reason: 'Не удалось обновить токен: сервер недоступен',
            ),
          );
      }
    }

    // Актуальный токен подставит _onRequest.
    final options = err.requestOptions..extra['retried'] = true;
    try {
      final response = await _dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  static String? _sentToken(RequestOptions options) {
    final header = options.headers['Authorization'];
    if (header is! String || !header.startsWith('Bearer ')) return null;
    return header.substring('Bearer '.length);
  }

  /// Один refresh на все одновременные 401.
  Future<_RefreshOutcome> _refreshOnce(TokenSession session) =>
      _refreshing ??= _refreshAndNotify(session);

  Future<_RefreshOutcome> _refreshAndNotify(TokenSession session) async {
    final _RefreshOutcome outcome;
    try {
      outcome = await _refresh(session);
    } finally {
      // Сбрасываем до колбэка: запросы, которые он вызовет, не должны ждать
      // этот же refresh.
      _refreshing = null;
    }
    if (outcome == _RefreshOutcome.rejected) {
      // Один раз на refresh, а не на каждый ожидавший его запрос.
      await _expireSession(session.access!);
    }
    return outcome;
  }

  Future<void> _expireSession(String token) async {
    // Сравнение и удаление сериализованы: параллельные 401 уведомят один раз,
    // а ответ от старой сессии не удалит ключ после нового входа.
    if (await _storage.clearIfCurrent(token)) {
      await _onSessionExpired?.call();
    }
  }

  /// Обновление JWT через `POST …/api/mobile/auth/token/refresh/`
  /// (SimpleJWT: запрос `{refresh}`, ответ `{access, refresh?}`).
  Future<_RefreshOutcome> _refresh(TokenSession session) async {
    // В тест-режиме (40-символьный токен /api/v1) refresh не применим.
    if (AppConfig.testAuthEnabled) return _RefreshOutcome.rejected;
    try {
      if (await _storage.readSession() != session) {
        return _RefreshOutcome.refreshed;
      }
      final refresh = session.refresh;
      if (refresh == null || refresh.isEmpty) return _RefreshOutcome.rejected;
      final res = await _dio.post<dynamic>(
        ApiEndpoints.tokenRefresh,
        data: {'refresh': refresh},
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) return _RefreshOutcome.unavailable;
      final access = (data['access'] ?? data['access_token'])?.toString();
      if (access == null || access.isEmpty) return _RefreshOutcome.unavailable;
      await _storage.replaceJwtTokens(
        previous: session,
        access: access,
        refresh:
            (data['refresh'] ?? data['refresh_token'])?.toString() ?? refresh,
      );
      return _RefreshOutcome.refreshed;
    } on DioException catch (e) {
      // 400/401/403 — refresh невалиден, истёк или отозван (SimpleJWT
      // `token_not_valid`). Нет сети, таймаут и 5xx — временный сбой.
      final status = e.response?.statusCode;
      return status == 400 || status == 401 || status == 403
          ? _RefreshOutcome.rejected
          : _RefreshOutcome.unavailable;
    } catch (_) {
      return _RefreshOutcome.unavailable;
    }
  }
}
