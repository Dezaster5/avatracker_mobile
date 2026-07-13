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

/// Аналитика опозданий за неделю/месяц.
final tardinessAnalyticsProvider =
    FutureProvider.family<TardinessAnalytics, AnalyticsRange>((ref, range) {
  final iin = _requireIin(ref);
  return ref.watch(attendanceRepositoryProvider).tardiness(
        iin: iin,
        range: range,
      );
});

class AttendanceOverview {
  const AttendanceOverview({required this.marks, required this.tardiness});

  final AttendanceMarksMonth marks;
  final TardinessAnalytics tardiness;
}

/// Табель на production API: все отметки из employee-identification-list,
/// признаки опозданий из tardiness. Оба запроса запускаются параллельно.
final attendanceOverviewProvider =
    FutureProvider.family<AttendanceOverview, AnalyticsRange>(
  (ref, range) async {
    final iin = _requireIin(ref);
    final repository = ref.watch(attendanceRepositoryProvider);
    final marksFuture = repository.attendanceMarks(iin: iin, range: range);
    final tardinessFuture = repository.tardiness(iin: iin, range: range);
    return AttendanceOverview(
      marks: await marksFuture,
      tardiness: await tardinessFuture,
    );
  },
);
