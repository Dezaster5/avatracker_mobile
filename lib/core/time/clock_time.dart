import 'package:flutter/foundation.dart' show immutable;

/// Время суток с точностью до минуты: график `HH:mm` и время отметок.
@immutable
final class ClockTime implements Comparable<ClockTime> {
  /// [minutes] от полуночи. Значения за пределами суток приводятся по модулю
  /// (`25:10` → `01:10`), как у ночного графика.
  const ClockTime.fromMinutes(int minutes)
      : minutesOfDay = minutes % Duration.minutesPerDay;

  /// Локальное время суток момента [moment].
  factory ClockTime.of(DateTime moment) => ClockTime.fromMinutes(
        moment.hour * Duration.minutesPerHour + moment.minute,
      );

  /// Разбирает начало строки `H:mm` / `HH:mm[:ss]`; `null` — формат неверный.
  static ClockTime? tryParse(Object? value) {
    final match = _pattern.firstMatch('${value ?? ''}'.trim());
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return ClockTime.fromMinutes(hour * Duration.minutesPerHour + minute);
  }

  static final _pattern = RegExp(r'^(\d{1,2}):(\d{2})');

  /// Минуты от полуночи, `0…1439`.
  final int minutesOfDay;

  int get hour => minutesOfDay ~/ Duration.minutesPerHour;
  int get minute => minutesOfDay % Duration.minutesPerHour;

  /// `09:05`.
  String get label => '${_twoDigits(hour)}:${_twoDigits(minute)}';

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  @override
  int compareTo(ClockTime other) => minutesOfDay.compareTo(other.minutesOfDay);

  @override
  bool operator ==(Object other) =>
      other is ClockTime && other.minutesOfDay == minutesOfDay;

  @override
  int get hashCode => minutesOfDay.hashCode;

  @override
  String toString() => label;
}
