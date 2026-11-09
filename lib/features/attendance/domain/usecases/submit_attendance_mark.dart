import '../../../../core/error/result.dart';
import '../entities/geo_position.dart';
import '../entities/scan_result.dart';
import '../repositories/attendance_repository.dart';

/// Отметка по QR (ТЗ 7, 19.4).
final class SubmitAttendanceMark {
  const SubmitAttendanceMark(this._repository);

  final AttendanceRepository _repository;

  Future<Result<ScanResult>> call({
    required String iin,
    required String qrId,
    required GeoPosition position,
    required String photo,
  }) =>
      _repository.submitMark(
        iin: iin,
        qrId: qrId,
        position: position,
        photo: photo,
      );
}
