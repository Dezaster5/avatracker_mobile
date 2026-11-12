import 'dart:async';

import 'package:avatracker_mobile/features/attendance/presentation/controllers/camera_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('операции с камерой идут по очереди, ошибка не блокирует следующие',
      () async {
    final queue = CameraQueue();
    final log = <String>[];
    final release = Completer<void>();

    final stop = queue.run(() async {
      log.add('stop: начало');
      await release.future;
      log.add('stop: конец');
    });
    final failedStart = queue.run(() async {
      log.add('start 1');
      throw StateError('камера занята');
    });
    final start = queue.run(() async => log.add('start 2'));

    await pumpEventQueue();
    expect(log, ['stop: начало'], reason: 'start ждёт завершения stop');

    release.complete();
    await stop;
    await expectLater(failedStart, throwsStateError);
    await start;
    expect(log, ['stop: начало', 'stop: конец', 'start 1', 'start 2']);
  });
}
