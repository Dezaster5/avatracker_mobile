import 'package:avatracker_mobile/core/time/clock_time.dart';
import 'package:avatracker_mobile/core/time/work_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClockTime', () {
    test('разбирает H:mm и HH:mm:ss', () {
      expect(ClockTime.tryParse('9:05')?.label, '09:05');
      expect(ClockTime.tryParse('18:00:00')?.label, '18:00');
      expect(ClockTime.tryParse(' 07:30 ')?.minutesOfDay, 450);
    });

    test('неверный формат — null', () {
      expect(ClockTime.tryParse(null), isNull);
      expect(ClockTime.tryParse(''), isNull);
      expect(ClockTime.tryParse('24:00'), isNull);
      expect(ClockTime.tryParse('10:60'), isNull);
      expect(ClockTime.tryParse('утро'), isNull);
    });

    test('минуты за пределами суток приводятся по модулю', () {
      expect(const ClockTime.fromMinutes(25 * 60 + 10).label, '01:10');
      expect(const ClockTime.fromMinutes(-30).label, '23:30');
    });

    test('сравнение и равенство по времени суток', () {
      final morning = ClockTime.tryParse('09:00')!;
      expect(morning, ClockTime.of(DateTime(2026, 1, 1, 9)));
      expect(morning.compareTo(ClockTime.tryParse('10:00')!), lessThan(0));
    });
  });

  group('WorkDay', () {
    test('рабочий день меняется в 03:00', () {
      expect(
          WorkDay.dateOf(DateTime(2026, 7, 14, 2, 59)), DateTime(2026, 7, 13));
      expect(WorkDay.dateOf(DateTime(2026, 7, 14, 3)), DateTime(2026, 7, 14));
    });
  });
}
