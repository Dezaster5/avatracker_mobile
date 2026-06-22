import 'mark_types.dart';

/// Статусы дня в табеле (ТЗ 9.3).
enum DayStatus { onTime, late, absent, weekend, weekendWork, noScan, unknown }

DayStatus dayStatusFrom(String? raw) {
  switch (raw) {
    case 'on_time':
      return DayStatus.onTime;
    case 'late':
      return DayStatus.late;
    case 'absent':
    case 'missed':
      return DayStatus.absent;
    case 'weekend':
    case 'day_off':
      return DayStatus.weekend;
    case 'weekend_work':
      return DayStatus.weekendWork;
    case 'no_scan':
      return DayStatus.noScan;
    default:
      return DayStatus.unknown;
  }
}

class ScanEntry {
  const ScanEntry({
    this.time,
    this.wallClockMinutes,
    required this.type,
    this.point,
  });

  final DateTime? time;

  /// Время отметки в часовом поясе, указанном самим API-значением.
  /// Нужно для сравнения с локальным расписанием `HH:mm`.
  final int? wallClockMinutes;
  final String type;
  final String? point;

  String get typeLabel => markTypeLabel(type);

  factory ScanEntry.fromJson(Map<String, dynamic> json) {
    final rawTime = '${json['scanned_at'] ?? json['time'] ?? ''}';
    return ScanEntry(
      time: DateTime.tryParse(rawTime),
      wallClockMinutes: _wallClockMinutes(rawTime),
      type: '${json['mark_type'] ?? json['type'] ?? ''}',
      point: (json['park'] ?? json['point'] ?? json['qr_point'])?.toString(),
    );
  }

  static int? _wallClockMinutes(String value) {
    final match = RegExp(r'(?:T|\s)(\d{2}):(\d{2})').firstMatch(value);
    if (match == null) return null;
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return null;
    }
    return hour * 60 + minute;
  }
}

/// День табеля (ТЗ 13.7, 9.2).
class TimesheetDay {
  const TimesheetDay({
    required this.date,
    required this.dayType,
    this.workStart,
    this.workEnd,
    this.lunchStart,
    this.lunchEnd,
    required this.workedMinutes,
    required this.remainingMinutes,
    required this.status,
    this.statusRaw,
    this.place,
    this.scans = const [],
  });

  final DateTime date;
  final String dayType;
  final String? workStart;
  final String? workEnd;

  /// Обеденный перерыв (не входит в отработанное время).
  final String? lunchStart;
  final String? lunchEnd;
  final int workedMinutes;
  final int remainingMinutes;
  final DayStatus status;
  final String? statusRaw;
  final String? place;
  final List<ScanEntry> scans;

  bool get isWeekend =>
      dayType == 'weekend' ||
      dayType == 'day_off' ||
      status == DayStatus.weekend;

  static int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

  factory TimesheetDay.fromJson(Map<String, dynamic> json) {
    final statusRaw = json['status']?.toString();
    return TimesheetDay(
      date: DateTime.tryParse('${json['date'] ?? ''}') ?? DateTime(2000),
      dayType: '${json['day_type'] ?? 'working_day'}',
      workStart: json['work_start']?.toString(),
      workEnd: json['work_end']?.toString(),
      lunchStart: json['lunch_start']?.toString(),
      lunchEnd: json['lunch_end']?.toString(),
      workedMinutes: _int(json['worked_minutes']),
      remainingMinutes: _int(json['remaining_minutes']),
      status: dayStatusFrom(statusRaw),
      statusRaw: statusRaw,
      place: (json['place'] ?? json['park'] ?? json['work_place'])?.toString(),
      scans: (json['scans'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ScanEntry.fromJson)
          .toList(),
    );
  }
}

class TimesheetMonth {
  const TimesheetMonth({required this.month, required this.days});

  final String month;
  final List<TimesheetDay> days;

  TimesheetDay? dayFor(DateTime date) {
    for (final day in days) {
      if (day.date.year == date.year &&
          day.date.month == date.month &&
          day.date.day == date.day) {
        return day;
      }
    }
    return null;
  }

  factory TimesheetMonth.fromJson(Map<String, dynamic> json) {
    return TimesheetMonth(
      month: '${json['month'] ?? ''}',
      days: (json['days'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(TimesheetDay.fromJson)
          .toList(),
    );
  }
}
