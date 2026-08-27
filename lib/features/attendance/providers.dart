import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../auth/providers.dart';
import 'data/attendance_repository.dart';
import 'domain/analytics.dart';
import 'domain/attendance_marks.dart';

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

String? _scheduleStart(Ref ref) => ref.watch(
      authControllerProvider.select(
        (state) => state.employee?.scheduleStartTime,
      ),
    );

Future<AttendanceOverview> _loadOverview(Ref ref, AnalyticsRange range) async {
  final iin = _requireIin(ref);
  final scheduleStart = _scheduleStart(ref);
  final repository = ref.watch(attendanceRepositoryProvider);
  final marksFuture = repository.attendanceMarks(iin: iin, range: range);
  final tardinessFuture = repository.tardiness(iin: iin, range: range);
  final marks = await marksFuture;
  final serverTardiness = await tardinessFuture;
  return AttendanceOverview(
    marks: marks,
    tardiness: serverTardiness.normalizedForWorkDays(
      marks,
      employeeScheduleStart: scheduleStart,
    ),
  );
}

/// Аналитика использует метаданные `/tardiness/`, но пересчитывает случаи по
/// отметкам рабочего дня 03:00–02:59, чтобы ночной уход не скрывал опоздание.
final tardinessAnalyticsProvider =
    FutureProvider.family<TardinessAnalytics, AnalyticsRange>(
  (ref, range) async => (await _loadOverview(ref, range)).tardiness,
);

class AttendanceOverview {
  const AttendanceOverview({required this.marks, required this.tardiness});

  final AttendanceMarksMonth marks;
  final TardinessAnalytics tardiness;
}

/// Табель на production API: отметки и нормализованные признаки опозданий.
final attendanceOverviewProvider =
    FutureProvider.family<AttendanceOverview, AnalyticsRange>(
  _loadOverview,
);
