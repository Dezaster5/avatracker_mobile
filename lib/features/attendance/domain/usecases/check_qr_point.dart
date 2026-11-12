import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/qr_point.dart';
import '../repositories/attendance_repository.dart';

/// Пред-проверка точки до FaceID: незарегистрированную или отключённую точку
/// отсекаем сразу, не заставляя делать селфи. Проверка не блокирует отметку,
/// если не удалась сама (сеть, формат), — решение примет сервер при скане.
final class CheckQrPoint {
  const CheckQrPoint(this._repository);

  final AttendanceRepository _repository;

  Future<QrPointAvailability> call(String qrId) async {
    return switch (await _repository.qrPoint(qrId)) {
      Success(:final value) => value.isActive
          ? QrPointAvailability.available
          : QrPointAvailability.disabled,
      Failed(failure: NotFoundFailure()) => QrPointAvailability.notRegistered,
      Failed() => QrPointAvailability.unverified,
    };
  }
}
