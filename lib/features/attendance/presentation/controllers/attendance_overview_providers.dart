import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../di/attendance_providers.dart';
import '../../domain/entities/analytics_range.dart';
import '../../domain/entities/attendance_overview.dart';

/// Табель периода — единственный источник и для табеля, и для аналитики
/// (`AttendanceOverview.tardiness`): обновление одного не может оставить
/// другой со старыми данными. Ошибка загрузки — `Failure` в
/// `AsyncValue.error`.
final attendanceOverviewProvider =
    FutureProvider.family<AttendanceOverview, AnalyticsRange>((ref, range) {
  final employee = ref.watch(
    authControllerProvider.select((session) => session.employee),
  );
  final iin = employee?.iin;
  if (iin == null || iin.isEmpty) throw const EmployeeDataMissingFailure();

  return ref
      .watch(getAttendanceOverviewProvider)
      .call(iin: iin, range: range, scheduleStart: employee?.scheduleStart)
      .then((result) => result.getOrThrow());
});

extension AttendanceOverviewReload on WidgetRef {
  /// Pull-to-refresh: заново загружает табель периода с сервера. Ошибку
  /// экран показывает сам через `AsyncValue.error`, поэтому в
  /// `RefreshIndicator` она не пробрасывается.
  Future<void> reloadAttendanceOverview(AnalyticsRange range) async {
    invalidate(attendanceOverviewProvider(range));
    try {
      await read(attendanceOverviewProvider(range).future);
    } on Failure {
      // Экран уже показывает ошибку с кнопкой «Повторить».
    }
  }
}
