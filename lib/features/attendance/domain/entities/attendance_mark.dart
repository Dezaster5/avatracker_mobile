import 'package:flutter/foundation.dart' show immutable;

import '../../../../core/time/clock_time.dart';

/// Отметка сотрудника (`/api/v1/employee-identification-list/`).
@immutable
final class AttendanceMark {
  const AttendanceMark({
    required this.authTime,
    required this.occurredAt,
    required this.date,
    required this.time,
  });

  /// Исходное время отметки из API (ISO-8601).
  final String authTime;

  /// Момент отметки во времени устройства.
  final DateTime occurredAt;

  /// Рабочая дата: рабочий день длится с 03:00 до 02:59.
  final DateTime date;

  /// Время суток отметки.
  final ClockTime time;
}

/// Отметки одного рабочего дня в хронологическом порядке. Тип отметки API не
/// присылает: первая отметка дня — приход, последняя (если их хотя бы две) —
/// уход.
@immutable
final class AttendanceDayMarks {
  AttendanceDayMarks({required this.date, required List<AttendanceMark> marks})
      : marks = List.unmodifiable(
          List<AttendanceMark>.of(marks)
            ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt)),
        );

  final DateTime date;
  final List<AttendanceMark> marks;

  AttendanceMark? get checkIn => marks.isEmpty ? null : marks.first;

  AttendanceMark? get checkOut => marks.length < 2 ? null : marks.last;
}

/// Отметки периода, сгруппированные по рабочим датам.
@immutable
final class AttendanceMarksMonth {
  AttendanceMarksMonth.fromMarks(List<AttendanceMark> marks)
      : days = Map.unmodifiable(_groupByDay(marks));

  final Map<DateTime, AttendanceDayMarks> days;

  static Map<DateTime, AttendanceDayMarks> _groupByDay(
    List<AttendanceMark> marks,
  ) {
    final grouped = <DateTime, List<AttendanceMark>>{};
    for (final mark in marks) {
      final day = DateTime(mark.date.year, mark.date.month, mark.date.day);
      grouped.putIfAbsent(day, () => []).add(mark);
    }
    return {
      for (final entry in grouped.entries)
        entry.key: AttendanceDayMarks(date: entry.key, marks: entry.value),
    };
  }
}
