import 'dart:async';

/// Сигнал «сервер отклонил refresh-токен».
///
/// HTTP-клиент сообщает о событии, auth-фича подписывается и завершает
/// сессию — так core не зависит от feature-модулей.
class SessionExpiryNotifier {
  final _events = StreamController<void>.broadcast();

  Stream<void> get events => _events.stream;

  void notify() => _events.add(null);

  Future<void> dispose() => _events.close();
}
