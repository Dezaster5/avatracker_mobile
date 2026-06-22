import 'timesheet.dart';

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

  bool contains(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  List<String> get monthKeys {
    final keys = <String>[];
    var cursor = DateTime(start.year, start.month);
    final last = DateTime(end.year, end.month);
    while (!cursor.isAfter(last)) {
      keys.add(
        '${cursor.year}-${cursor.month.toString().padLeft(2, '0')}',
      );
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return keys;
  }

  @override
  bool operator ==(Object other) =>
      other is AnalyticsRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

class LateArrival {
  const LateArrival({
    required this.date,
    required this.scheduledMinutes,
    required this.actualMinutes,
  });

  final DateTime date;
  final int scheduledMinutes;
  final int actualMinutes;

  int get lateMinutes => actualMinutes - scheduledMinutes;
  String get scheduledLabel => _clockLabel(scheduledMinutes);
  String get actualLabel => _clockLabel(actualMinutes);
}

class AttendanceAnalytics {
  const AttendanceAnalytics({
    required this.range,
    required this.workedMinutes,
    required this.workedDays,
    required this.lateArrivals,
  });

  final AnalyticsRange range;
  final int workedMinutes;
  final int workedDays;
  final List<LateArrival> lateArrivals;

  int get lateDays => lateArrivals.length;
  int get totalLateMinutes => lateArrivals.fold(
        0,
        (total, arrival) => total + arrival.lateMinutes,
      );
  int get averageLateMinutes =>
      lateDays == 0 ? 0 : (totalLateMinutes / lateDays).round();
  int get maxLateMinutes => lateArrivals.fold(
        0,
        (maximum, arrival) =>
            arrival.lateMinutes > maximum ? arrival.lateMinutes : maximum,
      );

  factory AttendanceAnalytics.fromDays(
    AnalyticsRange range,
    Iterable<TimesheetDay> source,
  ) {
    final days = source.where((day) => range.contains(day.date)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final lateArrivals = <LateArrival>[];

    for (final day in days) {
      final scheduled = _parseClock(day.workStart);
      final actual = _firstCheckIn(day.scans);
      if (scheduled != null && actual != null && actual > scheduled) {
        lateArrivals.add(
          LateArrival(
            date: day.date,
            scheduledMinutes: scheduled,
            actualMinutes: actual,
          ),
        );
      }
    }

    return AttendanceAnalytics(
      range: range,
      workedMinutes: days.fold(
        0,
        (total, day) => total + day.workedMinutes,
      ),
      workedDays: days.where((day) => day.workedMinutes > 0).length,
      lateArrivals: lateArrivals.reversed.toList(growable: false),
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

int? _firstCheckIn(List<ScanEntry> scans) {
  int? earliest;
  for (final scan in scans) {
    if (scan.type != 'check_in' || scan.wallClockMinutes == null) continue;
    final value = scan.wallClockMinutes!;
    if (earliest == null || value < earliest) earliest = value;
  }
  return earliest;
}

String _clockLabel(int minutes) {
  final hour = (minutes ~/ 60).toString().padLeft(2, '0');
  final minute = (minutes % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}
