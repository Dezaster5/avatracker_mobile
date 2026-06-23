import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../auth/providers.dart';
import 'data/attendance_repository.dart';
import 'domain/analytics.dart';
import 'domain/timesheet.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepository(api: ref.watch(apiClientProvider)),
);

String _requireIin(Ref ref) {
  final iin = ref.watch(authControllerProvider.select((s) => s.employee?.iin));
  if (iin == null || iin.isEmpty) {
    throw const ApiException(message: 'Нет данных сотрудника');
  }
  return iin;
}

/// Табель за месяц, ключ — `2026-06`. Инвалидируется после успешной отметки.
final timesheetProvider =
    FutureProvider.family<TimesheetMonth, String>((ref, month) {
  final iin = _requireIin(ref);
  return ref
      .watch(attendanceRepositoryProvider)
      .timesheet(iin: iin, month: month);
});

/// Аналитика опозданий за неделю/месяц.
final tardinessAnalyticsProvider =
    FutureProvider.family<TardinessAnalytics, AnalyticsRange>((ref, range) {
  final iin = _requireIin(ref);
  return ref.watch(attendanceRepositoryProvider).tardiness(
        iin: iin,
        range: range,
      );
});
