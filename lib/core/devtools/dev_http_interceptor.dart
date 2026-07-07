import 'dart:convert';

import 'package:dio/dio.dart';

import 'dev_log_store.dart';

const _devCallKey = '__devCall';

/// Пишет каждый HTTP-вызов в [DevLogStore] для панели разработчика.
/// Маскируются только пароли — остальное (токены, фото и т. п.) видно как есть.
class DevHttpInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final call = DevHttpCall(method: options.method, url: options.uri.toString())
      ..requestHeaders = _sanitizeHeaders(options.headers)
      ..requestBody = _stringify(options.data);
    options.extra[_devCallKey] = call;
    devLogStore.addHttpCall(call);
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final call = response.requestOptions.extra[_devCallKey] as DevHttpCall?;
    if (call != null) {
      call
        ..statusCode = response.statusCode
        ..responseHeaders = response.headers.map
            .map((key, value) => MapEntry(key, value.join('; ')))
        ..responseBody = _stringify(response.data)
        ..duration = DateTime.now().difference(call.startedAt);
      devLogStore.touch();
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final call = err.requestOptions.extra[_devCallKey] as DevHttpCall?;
    if (call != null) {
      call
        ..statusCode = err.response?.statusCode
        ..responseBody = _stringify(err.response?.data)
        ..error = err.message ?? err.type.toString()
        ..duration = DateTime.now().difference(call.startedAt);
      devLogStore.touch();
    }
    handler.next(err);
  }

  Map<String, String> _sanitizeHeaders(Map<String, dynamic> headers) {
    return headers.map((key, value) => MapEntry(key, value.toString()));
  }

  dynamic _sanitize(dynamic data) {
    if (data is Map) {
      return data.map((key, value) {
        final k = key.toString();
        if (RegExp(r'password', caseSensitive: false).hasMatch(k)) {
          return MapEntry(k, '***');
        }
        return MapEntry(k, _sanitize(value));
      });
    }
    if (data is List) return data.map(_sanitize).toList();
    return data;
  }

  String? _stringify(dynamic data) {
    if (data == null) return null;
    final sanitized = _sanitize(data);
    if (sanitized is String) return sanitized;
    try {
      return const JsonEncoder.withIndent('  ').convert(sanitized);
    } catch (_) {
      return sanitized.toString();
    }
  }
}
