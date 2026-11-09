import 'package:flutter/foundation.dart' show immutable;

import '../../../../core/time/clock_time.dart';
import '../../../../core/time/work_day.dart';
import 'analytics_range.dart';
import 'attendance_mark.dart';

/// Опоздание за один рабочий день.
@immutable
final class TardinessEntry {
  const TardinessEntry({
    required this.date,
    required this.authTime,
    required this.scheduled,
    required this.tardinessMinutes,
    this.actual,
  });

  /// Опоздание дня по фактической первой отметке; `null` — пришёл вовремя
  /// или отметок нет. Ночной график (начало до 03:00) относится к следующим
  /// календарным суткам рабочего дня.
  static TardinessEntry? forWorkDay(
    AttendanceDayMarks day,
    ClockTime schedule,
  ) {
    final arrival = day.checkIn;
    if (arrival == null) return null;

    final startsAfterMidnight =
        schedule.minutesOfDay < WorkDay.resetHour * Duration.minutesPerHour;
    final scheduledDate =
        startsAfterMidnight ? day.date.add(const Duration(days: 1)) : day.date;
    final scheduledAt = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      schedule.hour,
      schedule.minute,
    );
    final tardiness = arrival.occurredAt.difference(scheduledAt).inMinutes;
    if (tardiness <= 0) return null;

    return TardinessEntry(
      date: day.date,
      authTime: arrival.authTime,
      scheduled: schedule,
      tardinessMinutes: tardiness,
      actual: arrival.time,
    );
  }

  final DateTime date;

  /// Исходное время прихода из API (ISO-8601).
  final String authTime;
  final ClockTime scheduled;
  final int tardinessMinutes;

  /// Фактическое время прихода, если его удалось определить.
  final ClockTime? actual;

  /// Время прихода; без фактического — график плюс опоздание.
  ClockTime get arrival =>
      actual ??
      ClockTime.fromMinutes(scheduled.minutesOfDay + tardinessMinutes);
}

/// Опоздания за период.
@immutable
final class TardinessAnalytics {
  TardinessAnalytics({
    required this.range,
    required this.scheduleStart,
    required this.count,
    required this.maxTardiness,
    required this.avgTardiness,
    required List<TardinessEntry> results,
  }) : results = List.unmodifiable(results);

  final AnalyticsRange range;

  /// Начало графика по данным `/tardiness/`.
  final ClockTime? scheduleStart;
  final int count;
  final int maxTardiness;
  final int avgTardiness;

  /// Опоздания от последнего к первому.
  final List<TardinessEntry> results;

  int get totalTardinessMinutes =>
      results.fold(0, (total, entry) => total + entry.tardinessMinutes);

  /// Пересчитывает опоздания по первой отметке рабочего дня 03:00–02:59.
  /// Backend `/tardiness/` группирует по календарной дате и может принять
  /// ночной уход за первое событие следующего дня.
  TardinessAnalytics normalizedForWorkDays(
    AttendanceMarksMonth marks, {
    ClockTime? employeeScheduleStart,
  }) {
    final schedule = employeeScheduleStart ?? scheduleStart;
    if (schedule == null) return this;

    final entries = <TardinessEntry>[];
    for (final day in marks.days.values) {
      if (!range.contains(day.date)) continue;
      final entry = TardinessEntry.forWorkDay(day, schedule);
      if (entry != null) entries.add(entry);
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    final total = entries.fold(0, (sum, entry) => sum + entry.tardinessMinutes);
    final maximum = entries.fold(
      0,
      (value, entry) =>
          entry.tardinessMinutes > value ? entry.tardinessMinutes : value,
    );

    return TardinessAnalytics(
      range: range,
      scheduleStart: schedule,
      count: entries.length,
      maxTardiness: maximum,
      avgTardiness: entries.isEmpty ? 0 : (total / entries.length).round(),
      results: entries,
    );
  }
}
