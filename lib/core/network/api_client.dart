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

  /// Эндпоинты, не требующие токена.
  static const _publicPaths = {
    '/mobile/auth/register/send-code',
    '/mobile/auth/register/verify',
    '/mobile/auth/login',
    '/mobile/auth/password/forgot',
    '/mobile/auth/password/verify-code',
    '/mobile/auth/password/reset',
    '/mobile/auth/refresh',
  };

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_publicPaths.contains(options.path)) {
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
    final isPublic = _publicPaths.contains(err.requestOptions.path);
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

  Future<bool> _tryRefresh() async {
    final refresh = await _storage.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await _dio.post<dynamic>(
        '/mobile/auth/refresh',
        data: {'refresh_token': refresh},
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) return false;
      final access = data['access_token']?.toString();
      if (access == null || access.isEmpty) return false;
      await _storage.saveTokens(
        access: access,
        refresh: data['refresh_token']?.toString() ?? refresh,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
