import 'package:flutter/foundation.dart' show immutable;

import '../../../../core/time/clock_time.dart';
import 'attendance_mark.dart';
import 'tardiness.dart';

/// Статус дня в табеле.
enum DayAttendanceStatus { upcoming, late, noMarks, onTime }

/// Табель периода: отметки и опоздания по рабочим дням.
@immutable
final class AttendanceOverview {
  AttendanceOverview({
    required this.marks,
    required this.tardiness,
    ClockTime? scheduleStart,
  }) : _latenessByDay = _latenessByWorkDay(marks, tardiness, scheduleStart);

  final AttendanceMarksMonth marks;
  final TardinessAnalytics tardiness;
  final Map<DateTime, TardinessEntry> _latenessByDay;

  /// Даты, когда сотрудник опоздал.
  Set<DateTime> get lateDates => _latenessByDay.keys.toSet();

  AttendanceDayMarks? marksOn(DateTime date) => marks.days[_dateOnly(date)];

  TardinessEntry? latenessOn(DateTime date) => _latenessByDay[_dateOnly(date)];

  DayAttendanceStatus statusOn(DateTime date, {required DateTime today}) {
    if (date.isAfter(today)) return DayAttendanceStatus.upcoming;
    if (latenessOn(date) != null) return DayAttendanceStatus.late;
    final day = marksOn(date);
    if (day == null || day.marks.isEmpty) return DayAttendanceStatus.noMarks;
    return DayAttendanceStatus.onTime;
  }

  /// Табель показывает отметки напрямую, поэтому статус дня окончательно
  /// считается по тем же отметкам и текущему графику — это защищает текущий
  /// день от устаревшего `/tardiness/`.
  static Map<DateTime, TardinessEntry> _latenessByWorkDay(
    AttendanceMarksMonth marks,
    TardinessAnalytics tardiness,
    ClockTime? scheduleStart,
  ) {
    final lateness = <DateTime, TardinessEntry>{
      for (final entry in tardiness.results) _dateOnly(entry.date): entry,
    };
    if (scheduleStart == null) return Map.unmodifiable(lateness);
    for (final day in marks.days.values) {
      final date = _dateOnly(day.date);
      final calculated = TardinessEntry.forWorkDay(day, scheduleStart);
      if (calculated == null) {
        lateness.remove(date);
      } else {
        lateness[date] = calculated;
      }
    }
    return Map.unmodifiable(lateness);
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
