import '../../../../core/time/work_day.dart';
import '../../domain/entities/analytics_range.dart';

/// Параметры периода в запросах data-API.
extension AnalyticsRangeQuery on AnalyticsRange {
  /// `period_from` для `/tardiness/`: `2026-06-01`.
  String get startParam => _date(start);

  /// `period_to` для `/tardiness/`: `2026-06-30`.
  String get endParam => _date(end);

  /// Отметки берутся по рабочим дням: с 03:00 первого дня…
  String get attendanceStartParam =>
      '${_date(start)}T${_twoDigits(WorkDay.resetHour)}:00:00';

  /// …до 02:59:59 следующего за последним днём (backend применяет `lte`).
  String get attendanceEndParam => '${_date(end.add(const Duration(days: 1)))}'
      'T${_twoDigits(WorkDay.resetHour - 1)}:59:59.999999';

  static String _date(DateTime date) =>
      '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}';

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
