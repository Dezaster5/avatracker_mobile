import '../../../../core/error/result.dart';
import '../entities/analytics_range.dart';
import '../entities/attendance_mark.dart';
import '../entities/geo_position.dart';
import '../entities/qr_point.dart';
import '../entities/scan_result.dart';
import '../entities/tardiness.dart';

/// Отметки, табель и аналитика посещаемости.
abstract interface class AttendanceRepository {
  /// Отметки сотрудника за рабочие дни периода.
  Future<Result<AttendanceMarksMonth>> marks({
    required String iin,
    required AnalyticsRange range,
  });

  /// Опоздания по данным `/tardiness/` (без пересчёта по рабочему дню).
  Future<Result<TardinessAnalytics>> tardiness({
    required String iin,
    required AnalyticsRange range,
  });

  Future<Result<QrPoint>> qrPoint(String qrId);

  /// Отметка по QR с фото лица: сервер сверяет лицо с базовым фото сотрудника
  /// и проверяет радиус. Бизнес-отказ — это [ScanResult] с `success: false`.
  Future<Result<ScanResult>> submitMark({
    required String iin,
    required String qrId,
    required GeoPosition position,
    required String photo,
  });
}
