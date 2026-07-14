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

  /// `/employee-identification-list/` применяет верхнюю границу периода
  /// исключительно: чтобы включить [end], передаём следующий день.
  String get endExclusiveParam => _dateParam(end.add(const Duration(days: 1)));

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
  });

  final DateTime date;
  final String authTime;
  final int scheduledMinutes;
  final int tardinessMinutes;

  String get scheduledLabel => _clockLabel(scheduledMinutes);
  String get actualLabel {
    final match = RegExp(r'T(\d{2}):(\d{2})').firstMatch(authTime);
    if (match != null) return '${match.group(1)}:${match.group(2)}';
    return _clockLabel(scheduledMinutes + tardinessMinutes);
  }

  factory TardinessEntry.fromJson(Map<String, dynamic> json) {
    return TardinessEntry(
      date: DateTime.tryParse('${json['date']}') ?? DateTime(1970),
      authTime: '${json['auth_time'] ?? ''}',
      scheduledMinutes:
          _parseClock('${json['schedule_start_time'] ?? ''}') ?? 0,
      tardinessMinutes: _toInt(json['tardiness_minutes']),
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
