import 'package:intl/intl.dart';

/// `Июнь 2026` — заголовок месяца в выбранной локали.
String formatMonthTitle(DateTime month, {required String locale}) {
  final raw = DateFormat('LLLL yyyy', locale).format(month);
  return raw[0].toUpperCase() + raw.substring(1);
}

/// `05.06.2026`.
String formatDate(DateTime date) => DateFormat('dd.MM.yyyy').format(date);

/// `16:22`.
String formatTime(DateTime dateTime) => DateFormat('HH:mm').format(dateTime);

/// ISO-8601 с локальным смещением: `2026-06-05T16:22:00+05:00` (ТЗ 13.6).
String isoWithOffset(DateTime dateTime) {
  final offset = dateTime.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.inHours.abs().toString().padLeft(2, '0');
  final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
  final base = DateFormat('yyyy-MM-ddTHH:mm:ss').format(dateTime);
  return '$base$sign$hours:$minutes';
}
