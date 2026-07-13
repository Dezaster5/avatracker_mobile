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

  String get timeLabel {
    final minutes = wallClockMinutes;
    if (minutes == null) return '';
    final hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool get isCheckIn => type == 'check_in' || type == 'arrival' || type == 'in';

  bool get isCheckOut =>
      type == 'check_out' || type == 'departure' || type == 'out';

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

  List<ScanEntry> get chronologicalScans {
    final ordered = List<ScanEntry>.of(scans);
    ordered.sort((a, b) {
      final aMinutes = a.wallClockMinutes;
      final bMinutes = b.wallClockMinutes;
      if (aMinutes != null && bMinutes != null) {
        return aMinutes.compareTo(bMinutes);
      }
      final aTime = a.time;
      final bTime = b.time;
      if (aTime != null && bTime != null) return aTime.compareTo(bTime);
      return 0;
    });
    return ordered;
  }

  ScanEntry? get checkIn {
    for (final scan in chronologicalScans) {
      if (scan.isCheckIn) return scan;
    }
    return null;
  }

  ScanEntry? get checkOut {
    for (final scan in chronologicalScans.reversed) {
      if (scan.isCheckOut) return scan;
    }
    return null;
  }

  String get scheduleRangeLabel {
    final start = _clockLabel(workStart);
    final end = _clockLabel(workEnd);
    if (start == null || end == null) return '';
    return '$start-$end';
  }

  int get tardinessMinutes {
    final start = _clockMinutes(workStart);
    final arrival = checkIn?.wallClockMinutes;
    if (start == null || arrival == null || arrival <= start) return 0;
    return arrival - start;
  }

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

int? _clockMinutes(String? value) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch((value ?? '').trim());
  if (match == null) return null;
  final hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  if (hour == null || minute == null || hour > 23 || minute > 59) return null;
  return hour * 60 + minute;
}

String? _clockLabel(String? value) {
  final minutes = _clockMinutes(value);
  if (minutes == null) return null;
  final hour = (minutes ~/ 60).toString().padLeft(2, '0');
  final minute = (minutes % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
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
