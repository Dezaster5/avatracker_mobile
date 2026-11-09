import '../../../../core/error/result.dart';
import '../../../../core/time/clock_time.dart';
import '../entities/analytics_range.dart';
import '../entities/attendance_overview.dart';
import '../repositories/attendance_repository.dart';

/// Табель и аналитика периода: отметки и `/tardiness/` загружаются
/// параллельно, опоздания пересчитываются по рабочим дням 03:00–02:59, чтобы
/// ночной уход не скрывал опоздание.
final class GetAttendanceOverview {
  const GetAttendanceOverview(this._repository);

  final AttendanceRepository _repository;

  Future<Result<AttendanceOverview>> call({
    required String iin,
    required AnalyticsRange range,
    ClockTime? scheduleStart,
  }) async {
    final marksRequest = _repository.marks(iin: iin, range: range);
    final tardinessRequest = _repository.tardiness(iin: iin, range: range);
    final results = (await marksRequest, await tardinessRequest);

    return switch (results) {
      (Success(value: final marks), Success(value: final tardiness)) => Success(
          AttendanceOverview(
            marks: marks,
            tardiness: tardiness.normalizedForWorkDays(
              marks,
              employeeScheduleStart: scheduleStart,
            ),
            scheduleStart: scheduleStart,
          ),
        ),
      (Failed(:final failure), _) ||
      (_, Failed(:final failure)) =>
        Failed(failure),
    };
  }
}
