import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'mock_interceptor.dart';

typedef OnSessionExpired = Future<void> Function();

/// HTTP-клиент: JWT-заголовок, автоматический refresh при 401, mock-режим.
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
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint('[API] $o'),
      ));
    }
  }

  late final Dio _dio;
  final TokenStorage _storage;
  final OnSessionExpired? _onSessionExpired;

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
      final token = await _storage.accessToken;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
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
    if (!is401 || isPublic || alreadyRetried) {
      return handler.next(err);
    }

    final refreshed = await _tryRefresh();
    if (!refreshed) {
      await _onSessionExpired?.call();
      return handler.next(err);
    }

    final options = err.requestOptions..extra['retried'] = true;
    final token = await _storage.accessToken;
    options.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await _dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  /// Обновление JWT через `POST …/api/mobile/auth/token/refresh/`
  /// (SimpleJWT: запрос `{refresh}`, ответ `{access, refresh?}`).
  Future<bool> _tryRefresh() async {
    // В тест-режиме (40-символьный токен /api/v1) refresh не применим.
    if (AppConfig.testAuthEnabled) return false;
    final refresh = await _storage.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await _dio.post<dynamic>(
        '${AppConfig.mobileApiBaseUrl}/auth/token/refresh/',
        data: {'refresh': refresh},
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) return false;
      final access = (data['access'] ?? data['access_token'])?.toString();
      if (access == null || access.isEmpty) return false;
      await _storage.saveTokens(
        access: access,
        refresh:
            (data['refresh'] ?? data['refresh_token'])?.toString() ?? refresh,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
