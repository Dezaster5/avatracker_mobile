import '../config/app_config.dart';

/// Рабочий день длится с 03:00 до 02:59 следующих суток: ночной уход
/// относится к дню прихода.
abstract final class WorkDay {
  static const resetHour = 3;

  /// Рабочая дата момента [moment] — полночь локального дня.
  static DateTime dateOf(DateTime moment) {
    final shifted = moment.subtract(const Duration(hours: resetHour));
    return DateTime(shifted.year, shifted.month, shifted.day);
  }

  /// Текущий рабочий день; `--dart-define=TEST_TODAY` фиксирует дату.
  static DateTime get today {
    final fixed = AppConfig.testToday;
    if (fixed != null) return DateTime(fixed.year, fixed.month, fixed.day);
    return dateOf(DateTime.now());
  }
}
