import 'package:avatracker_mobile/features/attendance/data/models/analytics_range_query.dart';
import 'package:avatracker_mobile/features/attendance/data/models/attendance_mark_dto.dart';
import 'package:avatracker_mobile/features/attendance/data/models/qr_point_dto.dart';
import 'package:avatracker_mobile/features/attendance/data/models/scan_result_dto.dart';
import 'package:avatracker_mobile/features/attendance/data/models/tardiness_dto.dart';
import 'package:avatracker_mobile/features/attendance/domain/entities/analytics_range.dart';
import 'package:avatracker_mobile/features/attendance/domain/entities/attendance_mark.dart';
import 'package:avatracker_mobile/features/attendance/domain/entities/scan_result.dart';
import 'package:flutter_test/flutter_test.dart';

AttendanceMark _mark(String authTime) =>
    AttendanceMarkDto.fromJson({'auth_time': authTime}).toEntity();

void main() {
  group('AttendanceMarkDto', () {
    test('первая отметка — приход, последняя — уход', () {
      final month = AttendanceMarksMonth.fromMarks([
        _mark('2026-07-13T18:07:00'),
        _mark('2026-07-13T12:15:00'),
        _mark('2026-07-13T09:12:00'),
      ]);
      final day = month.days[DateTime(2026, 7, 13)];
      expect(day?.checkIn?.time.label, '09:12');
      expect(day?.checkOut?.time.label, '18:07');
    });

    test('одна отметка не считается уходом', () {
      final month = AttendanceMarksMonth.fromMarks([
        _mark('2026-07-13T09:12:00'),
      ]);
      final day = month.days[DateTime(2026, 7, 13)];
      expect(day?.checkIn?.time.label, '09:12');
      expect(day?.checkOut, isNull);
    });

    test('UTC-время отметки переводится во время устройства', () {
      const raw = '2026-07-13T13:16:53.839Z';
      final expected = DateTime.parse(raw).toLocal();
      final mark = _mark(raw);

      expect(mark.date, DateTime(expected.year, expected.month, expected.day));
      expect(mark.time.minutesOfDay, expected.hour * 60 + expected.minute);
    });

    test('отметки до 03:00 относятся к предыдущему рабочему дню', () {
      final beforeReset = _mark('2026-07-14T02:59:00');
      expect(beforeReset.date, DateTime(2026, 7, 13));
      expect(beforeReset.time.label, '02:59');
      expect(_mark('2026-07-14T03:00:00').date, DateTime(2026, 7, 14));
    });

    test('последняя ночная отметка остаётся уходом предыдущего дня', () {
      final month = AttendanceMarksMonth.fromMarks([
        _mark('2026-07-14T02:15:00'),
        _mark('2026-07-13T22:00:00'),
      ]);
      final day = month.days[DateTime(2026, 7, 13)];
      expect(day?.checkIn?.time.label, '22:00');
      expect(day?.checkOut?.time.label, '02:15');
    });

    test('время в неверном формате — ошибка формата ответа', () {
      expect(() => _mark('вчера'), throwsFormatException);
    });
  });

  group('ScanResultDto', () {
    test('успешная отметка (ТЗ 13.6)', () {
      final result = ScanResultDto.fromJson({
        'success': true,
        'mark_type': 'check_in',
        'message': 'Отметка успешно засчитана',
        'distance_meters': 12,
        'park': 'AVATARIYA Karaganda',
        'scanned_at': '2026-06-05T16:22:00+05:00',
      }).toEntity();
      expect(result.success, isTrue);
      expect(result.markType, MarkType.checkIn);
      expect(result.distanceMeters, 12);
      expect(result.park, 'AVATARIYA Karaganda');
    });

    test('отказ вне радиуса (ТЗ 28)', () {
      final result = ScanResultDto.fromJson({
        'success': false,
        'error_code': 'OUT_OF_RADIUS',
        'message': 'Вы находитесь далеко от точки отметки',
        'distance_meters': '184',
        'allowed_radius': 50,
      }).toEntity();
      expect(result.success, isFalse);
      expect(result.errorCode, 'OUT_OF_RADIUS');
      expect(result.distanceMeters, 184);
      expect(result.allowedRadius, 50);
    });

    test('без текста сервера и с неизвестным типом отметки', () {
      final result =
          ScanResultDto.fromJson({'success': true, 'mark_type': 'extra'})
              .toEntity();
      expect(result.message, isNull);
      expect(result.markType, MarkType.other);
    });
  });

  test('QrPointDto: без поля активности точка активна', () {
    expect(QrPointDto.fromJson({'qr_id': 'p1'}).toEntity().isActive, isTrue);
    expect(
      QrPointDto.fromJson({'qr_id': 'p1', 'is_active': 'false'})
          .toEntity()
          .isActive,
      isFalse,
    );
  });

  group('TardinessAnalyticsDto', () {
    test('парсит ответ /tardiness и считает сумму минут', () {
      final range = AnalyticsRange.month(DateTime(2026, 6, 10));
      final analytics = TardinessAnalyticsDto.fromJson({
        'schedule_start_time': '09:00:00',
        'count': 2,
        'max_tardiness': 178,
        'avg_tardiness': 92,
        'results': [
          {
            'date': '2026-06-22',
            'auth_time': '2026-06-22T11:58:42+05:00',
            'schedule_start_time': '09:00:00',
            'tardiness_minutes': 178,
          },
          {
            'date': '2026-06-23',
            'auth_time': '2026-06-23T09:07:50',
            'schedule_start_time': '09:00:00',
            'tardiness_minutes': 7,
          },
        ],
      }).toEntity(range);

      expect(analytics.scheduleStart?.label, '09:00');
      expect(analytics.count, 2);
      expect(analytics.totalTardinessMinutes, 185);
      expect(analytics.avgTardiness, 92);
      expect(analytics.maxTardiness, 178);
      expect(analytics.results.first.date, DateTime(2026, 6, 23));
      expect(analytics.results.first.arrival.label, '09:07');
      expect(analytics.results.last.scheduled.label, '09:00');
    });

    test('без агрегатов сервера они считаются по записям', () {
      final analytics = TardinessAnalyticsDto.fromJson({
        'results': [
          {'date': '2026-06-22', 'tardiness_minutes': 10},
          {'date': '2026-06-23', 'tardiness_minutes': 21},
        ],
      }).toEntity(AnalyticsRange.month(DateTime(2026, 6)));

      expect(analytics.count, 2);
      expect(analytics.maxTardiness, 21);
      expect(analytics.avgTardiness, 16);
    });
  });

  group('AnalyticsRangeQuery', () {
    test('границы табеля соответствуют рабочему дню с 03:00', () {
      final range = AnalyticsRange(
        start: DateTime(2026, 7, 14),
        end: DateTime(2026, 7, 14),
      );
      expect(range.attendanceStartParam, '2026-07-14T03:00:00');
      expect(range.attendanceEndParam, '2026-07-15T02:59:59.999999');
    });

    test('текущий период можно ограничить сегодняшней датой', () {
      final range = AnalyticsRange.month(DateTime(2026, 6, 24))
          .clampEnd(DateTime(2026, 6, 24));
      expect(range.startParam, '2026-06-01');
      expect(range.endParam, '2026-06-24');
    });
  });
}
