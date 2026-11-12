import 'package:flutter/foundation.dart' show immutable;

/// Период табеля и аналитики — даты включительно, без времени.
@immutable
final class AnalyticsRange {
  AnalyticsRange({required DateTime start, required DateTime end})
      : start = _dateOnly(start),
        end = _dateOnly(end);

  /// Календарный месяц, в который попадает [anchor].
  factory AnalyticsRange.month(DateTime anchor) => AnalyticsRange(
        start: DateTime(anchor.year, anchor.month),
        end: DateTime(anchor.year, anchor.month + 1, 0),
      );

  final DateTime start;
  final DateTime end;

  /// Обрезает конец периода датой [maxEnd] (текущий месяц — до сегодня).
  AnalyticsRange clampEnd(DateTime maxEnd) {
    final maxDay = _dateOnly(maxEnd);
    if (!end.isAfter(maxDay) || start.isAfter(maxDay)) return this;
    return AnalyticsRange(start: start, end: maxDay);
  }

  bool contains(DateTime date) => !date.isBefore(start) && !date.isAfter(end);

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  bool operator ==(Object other) =>
      other is AnalyticsRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}
