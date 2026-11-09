import '../../../../core/error/result.dart';
import '../../../../core/network/network_guard.dart';
import '../../domain/entities/analytics_range.dart';
import '../../domain/entities/attendance_mark.dart';
import '../../domain/entities/geo_position.dart';
import '../../domain/entities/qr_point.dart';
import '../../domain/entities/scan_result.dart';
import '../../domain/entities/tardiness.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_data_source.dart';
import '../models/scan_request.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  const AttendanceRepositoryImpl(this._remote);

  final AttendanceRemoteDataSource _remote;

  @override
  Future<Result<AttendanceMarksMonth>> marks({
    required String iin,
    required AnalyticsRange range,
  }) =>
      guardRequest(() async {
        final marks = await _remote.fetchMarks(iin: iin, range: range);
        return AttendanceMarksMonth.fromMarks(
          [for (final mark in marks) mark.toEntity()],
        );
      });

  @override
  Future<Result<TardinessAnalytics>> tardiness({
    required String iin,
    required AnalyticsRange range,
  }) =>
      guardRequest(() async {
        final dto = await _remote.fetchTardiness(iin: iin, range: range);
        return dto.toEntity(range);
      });

  @override
  Future<Result<QrPoint>> qrPoint(String qrId) => guardRequest(
        () async => (await _remote.fetchQrPoint(qrId)).toEntity(),
      );

  @override
  Future<Result<ScanResult>> submitMark({
    required String iin,
    required String qrId,
    required GeoPosition position,
    required String photo,
  }) =>
      guardRequest(() async {
        final request = ScanRequest(
          iin: iin,
          qrId: qrId,
          position: position,
          photo: photo,
          scannedAt: DateTime.now(),
        );
        return (await _remote.submitMark(request)).toEntity();
      });
}
