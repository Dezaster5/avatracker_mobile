class AttendanceMark {
  const AttendanceMark({
    required this.authTime,
    required this.date,
    required this.minutes,
  });

  final String authTime;
  final DateTime date;
  final int minutes;

  String get timeLabel {
    final hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  factory AttendanceMark.fromJson(Map<String, dynamic> json) {
    final raw = '${json['auth_time'] ?? ''}'.trim();
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      throw const FormatException('Invalid auth_time');
    }
    final local = parsed.toLocal();
    return AttendanceMark(
      authTime: raw,
      date: DateTime(local.year, local.month, local.day),
      minutes: local.hour * 60 + local.minute,
    );
  }
}

class AttendanceDayMarks {
  AttendanceDayMarks({required this.date, required List<AttendanceMark> marks})
      : marks = List<AttendanceMark>.of(marks)
          ..sort((a, b) => a.minutes.compareTo(b.minutes));

  final DateTime date;
  final List<AttendanceMark> marks;

  AttendanceMark? get checkIn => marks.isEmpty ? null : marks.first;

  AttendanceMark? get checkOut => marks.length < 2 ? null : marks.last;
}

class AttendanceMarksMonth {
  AttendanceMarksMonth.fromMarks(List<AttendanceMark> marks)
      : days = _groupByDay(marks);

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
