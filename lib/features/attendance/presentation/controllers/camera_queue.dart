import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Камера — общий ресурс приложения: операции всех экранов сканера идут через
/// одну очередь. Так запуск нового контроллера не пересекается с остановкой
/// старого, например когда после повторного входа сканер создаётся заново.
final cameraQueueProvider = Provider<CameraQueue>((ref) => CameraQueue());

/// Выполняет асинхронные операции с камерой строго по очереди.
class CameraQueue {
  Future<void> _tail = Future<void>.value();

  /// Запускает [operation] после всех ранее поставленных операций. Ошибка
  /// возвращается вызывающему, но не блокирует следующие операции.
  Future<void> run(Future<void> Function() operation) {
    final next = _tail.then((_) => operation());
    _tail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }
}
