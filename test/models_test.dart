import 'package:flutter_test/flutter_test.dart';

import 'package:avatracker_mobile/features/attendance/domain/analytics.dart';
import 'package:avatracker_mobile/features/attendance/domain/scan_result.dart';
import 'package:avatracker_mobile/features/attendance/domain/timesheet.dart';
import 'package:avatracker_mobile/features/auth/domain/employee.dart';

void main() {
  group('Employee.fromJson', () {
    test('вложенные объекты position/division/organization', () {
      final employee = Employee.fromJson({
        'id': 1,
        'iin': '642918307154',
        'full_name': 'Иванов Иван Иванович',
        'photo': 'https://example.com/photo.jpg',
        'active': true,
        'phone': '+77001234567',
        'position': {'name': 'Инженер'},
        'division': {'name': 'IT отдел'},
        'employee_organization': {'name': 'ТОО Аватария'},
        'park_id': 5000011,
      });
      expect(employee.iin, '642918307154');
      expect(employee.position, 'Инженер');
      expect(employee.division, 'IT отдел');
      expect(employee.organization, 'ТОО Аватария');
      expect(employee.parkId, 5000011);
      expect(employee.hasPhoto, true);
      expect(employee.firstName, 'Иван');
    });

    test('плоские строковые поля и active-строка', () {
      final employee = Employee.fromJson({
        'iin': '642918307154',
        'full_name': 'Иванов Иван',
        'active': 'true',
        'position': 'Инженер',
        'division': 'IT',
      });
      expect(employee.active, true);
      expect(employee.position, 'Инженер');
      expect(employee.hasPhoto, false);
    });

    test('toJson -> fromJson сохраняет данные', () {
      final original = Employee.fromJson({
        'iin': '642918307154',
        'full_name': 'Иванов Иван',
        'active': true,
        'position': {'name': 'Инженер'},
      });
      final restored = Employee.fromJson(original.toJson());
      expect(restored.iin, original.iin);
      expect(restored.position, original.position);
      expect(restored.active, original.active);
    });
  });

  group('TimesheetMonth.fromJson', () {
    test('пример из ТЗ 13.7', () {
      final month = TimesheetMonth.fromJson({
        'month': '2026-06',
        'days': [
          {
            'date': '2026-06-05',
            'day_type': 'working_day',
            'work_start': '09:00',
            'work_end': '18:00',
            'worked_minutes': 0,
            'remaining_minutes': 540,
            'status': 'no_scan',
            'scans': [],
          }
        ],
      });
      expect(month.days.length, 1);
      final day = month.days.first;
      expect(day.status, DayStatus.noScan);
      expect(day.workStart, '09:00');
      expect(day.remainingMinutes, 540);
      expect(month.dayFor(DateTime(2026, 6, 5)), isNotNull);
      expect(month.dayFor(DateTime(2026, 6, 6)), isNull);
    });

    test('обед парсится и не входит в отработанное (8 ч при графике 9–18)', () {
      final day = TimesheetDay.fromJson({
        'date': '2026-06-05',
        'day_type': 'working_day',
        'work_start': '09:00',
        'work_end': '18:00',
        'lunch_start': '13:00',
        'lunch_end': '14:00',
        'worked_minutes': 480,
        'remaining_minutes': 0,
        'status': 'on_time',
      });
      expect(day.lunchStart, '13:00');
      expect(day.lunchEnd, '14:00');
      expect(day.workedMinutes, 480);
    });

    test('сканы дня парсятся', () {
      final day = TimesheetDay.fromJson({
        'date': '2026-06-05',
        'status': 'on_time',
        'worked_minutes': 540,
        'remaining_minutes': 0,
        'scans': [
          {
            'scanned_at': '2026-06-05T08:56:00+05:00',
            'mark_type': 'check_in',
            'park': 'AVATARIYA Karaganda',
          }
        ],
      });
      expect(day.scans.length, 1);
      expect(day.scans.first.typeLabel, 'Приход');
      expect(day.scans.first.point, 'AVATARIYA Karaganda');
      expect(day.scans.first.wallClockMinutes, 8 * 60 + 56);
    });
  });

  group('ScanResult', () {
    test('успешная отметка (ТЗ 13.6)', () {
      final result = ScanResult.fromJson({
        'success': true,
        'mark_type': 'check_in',
        'message': 'Отметка успешно засчитана',
        'distance_meters': 12,
        'park': 'AVATARIYA Karaganda',
        'scanned_at': '2026-06-05T16:22:00+05:00',
      });
      expect(result.success, true);
      expect(result.markTypeLabelRu, 'Приход');
      expect(result.distanceMeters, 12);
    });

    test('отказ вне радиуса (ТЗ 28)', () {
      final result = ScanResult.fromJson({
        'success': false,
        'error_code': 'OUT_OF_RADIUS',
        'message': 'Вы находитесь далеко от точки отметки',
        'distance_meters': 184,
        'allowed_radius': 50,
      });
      expect(result.success, false);
      expect(result.errorCode, 'OUT_OF_RADIUS');
      expect(result.allowedRadius, 50);
    });
  });

  group('AttendanceAnalytics', () {
    test('считает отработанное время и детали опозданий из табеля', () {
      final month = TimesheetMonth.fromJson({
        'month': '2026-06',
        'days': [
          {
            'date': '2026-06-04',
            'work_start': '08:00',
            'worked_minutes': 446,
            'scans': [
              {
                'scanned_at': '2026-06-04T08:34:00+05:00',
                'mark_type': 'check_in',
              },
            ],
          },
          {
            'date': '2026-06-05',
            'work_start': '10:00',
            'worked_minutes': 420,
            'scans': [
              {
                'scanned_at': '2026-06-05T09:58:00+05:00',
                'mark_type': 'check_in',
              },
            ],
          },
          {
            'date': '2026-06-06',
            'work_start': '10:00',
            'worked_minutes': 400,
            'scans': [
              {
                'scanned_at': '2026-06-06T10:20:00+05:00',
                'mark_type': 'check_in',
              },
            ],
          },
        ],
      });
      final range = AnalyticsRange.forPeriod(
        AnalyticsPeriod.month,
        DateTime(2026, 6, 10),
      );
      final analytics = AttendanceAnalytics.fromDays(range, month.days);

      expect(analytics.workedMinutes, 1266);
      expect(analytics.workedDays, 3);
      expect(analytics.lateDays, 2);
      expect(analytics.totalLateMinutes, 54);
      expect(analytics.averageLateMinutes, 27);
      expect(analytics.maxLateMinutes, 34);
      expect(analytics.lateArrivals.first.actualLabel, '10:20');
      expect(analytics.lateArrivals.last.scheduledLabel, '08:00');
    });

    test('неделя корректно запрашивает два месяца на границе', () {
      final range = AnalyticsRange.forPeriod(
        AnalyticsPeriod.week,
        DateTime(2026, 7, 1),
      );
      expect(range.start, DateTime(2026, 6, 29));
      expect(range.end, DateTime(2026, 7, 5));
      expect(range.monthKeys, ['2026-06', '2026-07']);
    });
  });
}
