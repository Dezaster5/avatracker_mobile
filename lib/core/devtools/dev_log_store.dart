import 'dart:collection';

import 'package:flutter/foundation.dart';

/// Одна запись HTTP-вызова: создаётся на запросе, дополняется на ответе/ошибке
/// (один и тот же объект — список не дублирует строки на каждый вызов).
class DevHttpCall {
  DevHttpCall({required this.method, required this.url})
      : startedAt = DateTime.now();

  final String method;
  final String url;
  final DateTime startedAt;

  Map<String, String>? requestHeaders;
  String? requestBody;

  int? statusCode;
  Map<String, String>? responseHeaders;
  String? responseBody;
  String? error;
  Duration? duration;

  bool get isPending => statusCode == null && error == null;
  bool get isError => error != null || (statusCode ?? 0) >= 400;
}

/// Произвольная строка лога (debugPrint приложения), не связанная с сетью.
class DevLogLine {
  DevLogLine(this.message) : timestamp = DateTime.now();

  final String message;
  final DateTime timestamp;
}

/// Кольцевой буфер сетевых вызовов и логов для экрана панели разработчика.
/// Singleton — используется как из Dio-интерцептора, так и из UI.
class DevLogStore extends ChangeNotifier {
  DevLogStore._();
  static final DevLogStore instance = DevLogStore._();

  static const _maxEntries = 300;

  final _events = Queue<Object>();

  UnmodifiableListView<Object> get events => UnmodifiableListView(_events);

  DevHttpCall addHttpCall(DevHttpCall call) {
    _events.addFirst(call);
    _trim();
    notifyListeners();
    return call;
  }

  /// Вызывается после мутации полей уже добавленного [DevHttpCall]
  /// (ответ/ошибка пришли позже запроса) — просто перерисовывает список.
  void touch() => notifyListeners();

  void addLog(String message) {
    _events.addFirst(DevLogLine(message));
    _trim();
    notifyListeners();
  }

  void clear() {
    _events.clear();
    notifyListeners();
  }

  void _trim() {
    while (_events.length > _maxEntries) {
      _events.removeLast();
    }
  }
}

final devLogStore = DevLogStore.instance;
