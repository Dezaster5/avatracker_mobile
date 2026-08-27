import '../../../core/config/app_config.dart';
import 'attendance_marks.dart';

enum AnalyticsPeriod { week, month }

class AnalyticsRange {
  AnalyticsRange({required DateTime start, required DateTime end})
      : start = DateTime(start.year, start.month, start.day),
        end = DateTime(end.year, end.month, end.day);

  factory AnalyticsRange.forPeriod(AnalyticsPeriod period, DateTime anchor) {
    final day = DateTime(anchor.year, anchor.month, anchor.day);
    if (period == AnalyticsPeriod.month) {
      return AnalyticsRange(
        start: DateTime(day.year, day.month),
        end: DateTime(day.year, day.month + 1, 0),
      );
    }
    final monday = day.subtract(Duration(days: day.weekday - 1));
    return AnalyticsRange(
      start: monday,
      end: monday.add(const Duration(days: 6)),
    );
  }

  final DateTime start;
  final DateTime end;

  AnalyticsRange clampEnd(DateTime maxEnd) {
    final maxDay = DateTime(maxEnd.year, maxEnd.month, maxEnd.day);
    if (!end.isAfter(maxDay) || start.isAfter(maxDay)) return this;
    return AnalyticsRange(start: start, end: maxDay);
  }

  String get startParam => _dateParam(start);
  String get endParam => _dateParam(end);

  /// Табель использует рабочие дни 03:00–02:59:59 следующего дня.
  String get attendanceStartParam => '${_dateParam(start)}T03:00:00';

  /// Backend применяет `period_to` включительно (`lte`).
  String get attendanceEndParam =>
      '${_dateParam(end.add(const Duration(days: 1)))}T02:59:59.999999';

  @override
  bool operator ==(Object other) =>
      other is AnalyticsRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

class TardinessEntry {
  const TardinessEntry({
    required this.date,
    required this.authTime,
    required this.scheduledMinutes,
    required this.tardinessMinutes,
    this.actualMinutes,
  });

  final DateTime date;
  final String authTime;
  final int scheduledMinutes;
  final int tardinessMinutes;
  final int? actualMinutes;

  String get scheduledLabel => _clockLabel(scheduledMinutes);
  String get actualLabel {
    if (actualMinutes != null) return _clockLabel(actualMinutes!);
    final parsed = DateTime.tryParse(authTime)?.toLocal();
    if (parsed != null) return _clockLabel(parsed.hour * 60 + parsed.minute);
    return _clockLabel(scheduledMinutes + tardinessMinutes);
  }

  factory TardinessEntry.fromJson(Map<String, dynamic> json) {
    return TardinessEntry(
      date: DateTime.tryParse('${json['date']}') ?? DateTime(1970),
      authTime: '${json['auth_time'] ?? ''}',
      scheduledMinutes:
          _parseClock('${json['schedule_start_time'] ?? ''}') ?? 0,
      tardinessMinutes: _toInt(json['tardiness_minutes']),
      actualMinutes: _localClockMinutes('${json['auth_time'] ?? ''}'),
    );
  }
}

class TardinessAnalytics {
  const TardinessAnalytics({
    required this.range,
    required this.iin,
    required this.employeeName,
    required this.scheduleName,
    required this.scheduleStartTime,
    required this.count,
    required this.maxTardiness,
    required this.avgTardiness,
    required this.results,
  });

  final AnalyticsRange range;
  final String iin;
  final String employeeName;
  final String scheduleName;
  final String scheduleStartTime;
  final int count;
  final int maxTardiness;
  final int avgTardiness;
  final List<TardinessEntry> results;

  int get totalTardinessMinutes => results.fold(
        0,
        (total, entry) => total + entry.tardinessMinutes,
      );

  String get scheduleStartLabel {
    final minutes = _parseClock(scheduleStartTime);
    return minutes == null ? '' : _clockLabel(minutes);
  }

  factory TardinessAnalytics.fromJson(
    AnalyticsRange range,
    Map<String, dynamic> json,
  ) {
    final rawResults = json['results'];
    final entries = rawResults is List
        ? rawResults
            .whereType<Map<String, dynamic>>()
            .map(TardinessEntry.fromJson)
            .toList()
        : <TardinessEntry>[];
    entries.sort((a, b) => b.date.compareTo(a.date));
    final computedMax = entries.fold(
      0,
      (maximum, entry) =>
          entry.tardinessMinutes > maximum ? entry.tardinessMinutes : maximum,
    );
    final computedTotal = entries.fold(
      0,
      (total, entry) => total + entry.tardinessMinutes,
    );
    final count = _toInt(json['count'], fallback: entries.length);

    return TardinessAnalytics(
      range: range,
      iin: '${json['iin'] ?? ''}',
      employeeName: '${json['employee_name'] ?? ''}',
      scheduleName: '${json['schedule_name'] ?? ''}',
      scheduleStartTime: '${json['schedule_start_time'] ?? ''}',
      count: count,
      maxTardiness: _toInt(json['max_tardiness'], fallback: computedMax),
      avgTardiness: _toInt(
        json['avg_tardiness'],
        fallback: count == 0 ? 0 : (computedTotal / count).round(),
      ),
      results: entries,
    );
  }

  /// Пересчитывает опоздания по первой отметке рабочего дня 03:00–02:59.
  /// Backend `/tardiness/` группирует по календарной дате и может принять
  /// ночной уход за первое событие следующего дня.
  TardinessAnalytics normalizedForWorkDays(
    AttendanceMarksMonth marks, {
    String? employeeScheduleStart,
  }) {
    final effectiveSchedule = _normalizedClock(employeeScheduleStart) ??
        _normalizedClock(scheduleStartTime);
    final scheduledMinutes = _parseClock(effectiveSchedule);
    if (scheduledMinutes == null) return this;

    final entries = <TardinessEntry>[];
    for (final day in marks.days.values) {
      if (day.date.isBefore(range.start) || day.date.isAfter(range.end)) {
        continue;
      }
      final arrival = day.checkIn;
      if (arrival == null) continue;

      final scheduledDate = scheduledMinutes <
              AppConfig.workDayResetHour * Duration.minutesPerHour
          ? day.date.add(const Duration(days: 1))
          : day.date;
      final scheduledAt = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        scheduledMinutes ~/ Duration.minutesPerHour,
        scheduledMinutes % Duration.minutesPerHour,
      );
      final tardiness = arrival.occurredAt.difference(scheduledAt).inMinutes;
      if (tardiness <= 0) continue;

      entries.add(
        TardinessEntry(
          date: day.date,
          authTime: arrival.authTime,
          scheduledMinutes: scheduledMinutes,
          tardinessMinutes: tardiness,
          actualMinutes: arrival.minutes,
        ),
      );
    }

    entries.sort((a, b) => b.date.compareTo(a.date));
    final total = entries.fold(
      0,
      (sum, entry) => sum + entry.tardinessMinutes,
    );
    final maximum = entries.fold(
      0,
      (value, entry) =>
          entry.tardinessMinutes > value ? entry.tardinessMinutes : value,
    );

    return TardinessAnalytics(
      range: range,
      iin: iin,
      employeeName: employeeName,
      scheduleName: scheduleName,
      scheduleStartTime: effectiveSchedule!,
      count: entries.length,
      maxTardiness: maximum,
      avgTardiness: entries.isEmpty ? 0 : (total / entries.length).round(),
      results: entries,
    );
  }
}

int? _localClockMinutes(String value) {
  final parsed = DateTime.tryParse(value)?.toLocal();
  return parsed == null ? null : parsed.hour * 60 + parsed.minute;
}

String? _normalizedClock(String? value) {
  final minutes = _parseClock(value);
  return minutes == null ? null : _clockLabel(minutes);
}

int? _parseClock(String? value) {
  if (value == null) return null;
  final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value.trim());
  if (match == null) return null;
  final hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  if (hour == null || minute == null || hour > 23 || minute > 59) return null;
  return hour * 60 + minute;
}

String _clockLabel(int minutes) {
  final normalized = minutes % (24 * 60);
  final hour = (normalized ~/ 60).toString().padLeft(2, '0');
  final minute = (normalized % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}

int _toInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse('$value') ?? fallback;
}

String _dateParam(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
