import 'package:avatracker_mobile/core/time/clock_time.dart';
import 'package:avatracker_mobile/features/attendance/data/models/attendance_mark_dto.dart';
import 'package:avatracker_mobile/features/attendance/domain/entities/analytics_range.dart';
import 'package:avatracker_mobile/features/attendance/domain/entities/attendance_mark.dart';
import 'package:avatracker_mobile/features/attendance/domain/entities/attendance_overview.dart';
import 'package:avatracker_mobile/features/attendance/domain/entities/tardiness.dart';
import 'package:flutter_test/flutter_test.dart';

AttendanceMarksMonth _marks(List<String> authTimes) =>
    AttendanceMarksMonth.fromMarks([
      for (final time in authTimes)
        AttendanceMarkDto.fromJson({'auth_time': time}).toEntity(),
    ]);

TardinessAnalytics _server(
  AnalyticsRange range, {
  String? schedule,
  List<TardinessEntry> results = const [],
}) =>
    TardinessAnalytics(
      range: range,
      scheduleStart: ClockTime.tryParse(schedule),
      count: results.length,
      maxTardiness: 0,
      avgTardiness: 0,
      results: results,
    );

final _ten = ClockTime.tryParse('10:00')!;

void main() {
  group('Опоздания по рабочему дню', () {
    test('приход 10:14 при графике с 10:00 — опоздание 14 минут', () {
      final marks = _marks(['2026-08-27T10:14:00', '2026-08-27T12:32:00']);
      final entry =
          TardinessEntry.forWorkDay(marks.days[DateTime(2026, 8, 27)]!, _ten);

      expect(entry?.date, DateTime(2026, 8, 27));
      expect(entry?.arrival.label, '10:14');
      expect(entry?.tardinessMinutes, 14);
    });

    test('уход в 02:59 не скрывает опоздание следующего рабочего дня', () {
      final range = AnalyticsRange(
        start: DateTime(2026, 7, 13),
        end: DateTime(2026, 7, 14),
      );
      final marks = _marks([
        '2026-07-13T10:00:00',
        '2026-07-14T02:59:00',
        '2026-07-14T10:07:00',
      ]);

      final analytics =
          _server(range, schedule: '10:00:00').normalizedForWorkDays(marks);

      expect(analytics.count, 1);
      expect(analytics.results.single.date, DateTime(2026, 7, 14));
      expect(analytics.results.single.arrival.label, '10:07');
      expect(analytics.totalTardinessMinutes, 7);
    });

    test('ночной график рассчитывает опоздание после полуночи', () {
      final range = AnalyticsRange(
        start: DateTime(2026, 7, 13),
        end: DateTime(2026, 7, 13),
      );
      final analytics = _server(range, schedule: '02:00:00')
          .normalizedForWorkDays(_marks(['2026-07-14T02:12:00']));

      expect(analytics.results.single.date, DateTime(2026, 7, 13));
      expect(analytics.results.single.tardinessMinutes, 12);
    });

    test('график сотрудника приоритетнее графика из /tardiness/', () {
      final range = AnalyticsRange.month(DateTime(2026, 8));
      final analytics = _server(range, schedule: '09:00').normalizedForWorkDays(
        _marks(['2026-08-27T09:30:00']),
        employeeScheduleStart: _ten,
      );

      expect(analytics.results, isEmpty);
      expect(analytics.scheduleStart, _ten);
    });

    test('без графика данные сервера не пересчитываются', () {
      final server = _server(AnalyticsRange.month(DateTime(2026, 8)));
      expect(server.normalizedForWorkDays(_marks([])), same(server));
    });
  });

  group('AttendanceOverview', () {
    final range = AnalyticsRange.month(DateTime(2026, 8));
    final staleLate = TardinessEntry(
      date: DateTime(2026, 8, 27),
      authTime: '2026-08-27T10:30:00',
      scheduled: _ten,
      tardinessMinutes: 30,
    );
    final lateWithoutMarks = TardinessEntry(
      date: DateTime(2026, 8, 3),
      authTime: '2026-08-03T10:05:00',
      scheduled: _ten,
      tardinessMinutes: 5,
    );

    test('статус дня по отметкам перекрывает устаревший /tardiness/', () {
      final overview = AttendanceOverview(
        marks: _marks(['2026-08-27T09:55:00', '2026-08-28T10:20:00']),
        tardiness: _server(range, results: [staleLate, lateWithoutMarks]),
        scheduleStart: _ten,
      );

      expect(overview.latenessOn(DateTime(2026, 8, 27)), isNull);
      expect(overview.latenessOn(DateTime(2026, 8, 28))?.tardinessMinutes, 20);
      expect(overview.latenessOn(DateTime(2026, 8, 3)), lateWithoutMarks);
      expect(
        overview.lateDates,
        {DateTime(2026, 8, 28), DateTime(2026, 8, 3)},
      );
    });

    test('без графика используются опоздания сервера', () {
      final overview = AttendanceOverview(
        marks: _marks(['2026-08-27T09:55:00']),
        tardiness: _server(range, results: [staleLate]),
      );
      expect(overview.latenessOn(DateTime(2026, 8, 27)), staleLate);
    });

    test('статус дня в табеле', () {
      final overview = AttendanceOverview(
        marks: _marks(['2026-08-27T09:55:00', '2026-08-28T10:20:00']),
        tardiness: _server(range),
        scheduleStart: _ten,
      );
      final today = DateTime(2026, 8, 28);

      expect(
        overview.statusOn(DateTime(2026, 8, 29), today: today),
        DayAttendanceStatus.upcoming,
      );
      expect(
        overview.statusOn(DateTime(2026, 8, 28), today: today),
        DayAttendanceStatus.late,
      );
      expect(
        overview.statusOn(DateTime(2026, 8, 27), today: today),
        DayAttendanceStatus.onTime,
      );
      expect(
        overview.statusOn(DateTime(2026, 8, 26), today: today),
        DayAttendanceStatus.noMarks,
      );
    });
  });
}
