import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../di/attendance_providers.dart';
import '../../domain/entities/geo_position.dart';
import '../../domain/entities/qr_point.dart';
import '../../domain/entities/scan_result.dart';
import 'attendance_overview_providers.dart';

/// Этап отметки, который видит сотрудник.
enum ScanStage { checkingPoint, checkingFace, checkingLocation, sendingMark }

@immutable
class ScannerState {
  const ScannerState({this.stage});

  /// `null` — сканер ждёт QR-код.
  final ScanStage? stage;

  bool get isBusy => stage != null;
}

/// Итог попытки отметки для шторки результата.
sealed class ScanOutcome {
  const ScanOutcome();
}

/// Сервер ответил: отметка засчитана или отклонена бизнес-правилом.
final class ScanCompleted extends ScanOutcome {
  const ScanCompleted(this.result);

  final ScanResult result;
}

/// Отметка не дошла до сервера или точка не прошла пред-проверку.
final class ScanFailed extends ScanOutcome {
  const ScanFailed(this.failure);

  final Failure failure;
}

/// Сценарий отметки (ТЗ 7, 19.4): QR → пред-проверка точки → FaceID →
/// геолокация с проверками → отметка. FaceID — отдельный экран, его
/// открывает UI между [checkPoint] и [submit].
class ScannerController extends Notifier<ScannerState> {
  @override
  ScannerState build() => const ScannerState();

  /// Код распознан — сканер занят, повторные распознавания игнорируются.
  void start() => state = const ScannerState(stage: ScanStage.checkingPoint);

  /// Пред-проверка точки. `null` — можно переходить к FaceID.
  Future<ScanOutcome?> checkPoint(QrCode code) async {
    state = const ScannerState(stage: ScanStage.checkingPoint);
    switch (await ref.read(checkQrPointProvider).call(code.id)) {
      case QrPointAvailability.disabled:
        return const ScanFailed(QrPointDisabledFailure());
      case QrPointAvailability.notRegistered:
        return ScanFailed(QrNotRegisteredFailure(code.id));
      case QrPointAvailability.available:
      case QrPointAvailability.unverified:
        state = const ScannerState(stage: ScanStage.checkingFace);
        return null;
    }
  }

  /// Снимок лица получен: геолокация и отметка. Сервер сверяет лицо с
  /// базовым фото сотрудника прямо при скане.
  Future<ScanOutcome> submit({
    required QrCode code,
    required String photo,
  }) async {
    state = const ScannerState(stage: ScanStage.checkingLocation);
    final GeoPosition position;
    switch (await ref.read(getVerifiedPositionProvider).call()) {
      case Success(:final value):
        position = value;
      case Failed(:final failure):
        return ScanFailed(failure);
    }

    state = const ScannerState(stage: ScanStage.sendingMark);
    final iin = ref.read(authControllerProvider).employee?.iin ?? '';
    final result = await ref.read(submitAttendanceMarkProvider).call(
          iin: iin,
          qrId: code.id,
          position: position,
          photo: photo,
        );
    switch (result) {
      case Success(:final value):
        if (value.success) {
          // Из этого провайдера строятся и табель, и аналитика.
          ref.invalidate(attendanceOverviewProvider);
        }
        return ScanCompleted(value);
      case Failed(:final failure):
        return ScanFailed(failure);
    }
  }

  /// Результат показан — сканер снова ждёт QR-код.
  void finish() => state = const ScannerState();
}

final scannerControllerProvider =
    NotifierProvider<ScannerController, ScannerState>(ScannerController.new);
