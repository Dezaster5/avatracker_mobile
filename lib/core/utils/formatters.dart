import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

String _group(String s, int start, int end) {
  if (s.length <= start) return '';
  final e = s.length < end ? s.length : end;
  return s.substring(start, e);
}

/// 10 цифр абонентского номера (без кода страны).
///
/// Текст с ведущим `+` — это уже отформатированное значение или вставка
/// в международном формате: первая семерка там всегда код страны,
/// убираем ее безусловно (иначе при каждом переформатировании поля
/// семерка из префикса «+7» затекала бы в номер). Без `+`: ведущая `8` —
/// межгород, убираем; ведущая `7` — код страны только при 11+ цифрах
/// (операторские коды 700–778 тоже начинаются с семерки).
String _subscriberDigits(String input) {
  final raw = input.trim();
  if (raw.startsWith('+')) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('7')) digits = digits.substring(1);
    if (digits.length > 10) digits = digits.substring(0, 10);
    return digits;
  }
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('8')) digits = digits.substring(1);
  if (digits.startsWith('7') && digits.length >= 11) {
    digits = digits.substring(1);
  }
  if (digits.length > 10) digits = digits.substring(0, 10);
  return digits;
}

String _formatSubscriber(String subscriber) {
  final parts = [
    _group(subscriber, 0, 3),
    _group(subscriber, 3, 6),
    _group(subscriber, 6, 8),
    _group(subscriber, 8, 10),
  ].where((p) => p.isNotEmpty);
  return ['+7', ...parts].join(' ');
}

/// Форматирует ввод номера телефона в вид `+7 700 123 45 67` (ТЗ 3.1).
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final subscriber = _subscriberDigits(newValue.text);
    // Без цифр абонента поле полностью очищается (удаление до «+7 »
    // не должно оставлять залипший префикс).
    final text = subscriber.isEmpty ? '' : _formatSubscriber(subscriber);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// `+7 700 123 45 67` / `8 700...` / `700...` -> `+77001234567`.
String normalizePhone(String input) => '+7${_subscriberDigits(input)}';

/// `+77001234567` -> `+7 700 123 45 67`.
String formatPhone(String normalized) {
  final subscriber = _subscriberDigits(normalized);
  if (subscriber.length != 10) return normalized;
  return _formatSubscriber(subscriber);
}

bool isValidKzPhone(String input) => _subscriberDigits(input).length == 10;

bool isValidIin(String iin) => RegExp(r'^\d{12}$').hasMatch(iin);

/// Минимальные требования к паролю: от 6 символов без пробелов.
bool isValidPassword(String password) =>
    password.length >= 6 && !password.contains(' ');

/// 275 -> `4 ч 35 мин`, 540 -> `9 ч`, 45 -> `45 мин`.
String formatMinutes(int minutes) {
  final m = minutes.abs();
  final h = m ~/ 60;
  final r = m % 60;
  if (h == 0) return '$r мин';
  if (r == 0) return '$h ч';
  return '$h ч $r мин';
}

/// `Июнь 2026`.
String formatMonthTitle(DateTime month) {
  final raw = DateFormat('LLLL yyyy', 'ru').format(month);
  return raw[0].toUpperCase() + raw.substring(1);
}

/// Параметр month для API: `2026-06`.
String monthParam(DateTime month) => DateFormat('yyyy-MM').format(month);

String formatDate(DateTime date) => DateFormat('dd.MM.yyyy').format(date);

String formatTime(DateTime dateTime) => DateFormat('HH:mm').format(dateTime);

/// ISO-8601 с локальным смещением: `2026-06-05T16:22:00+05:00` (ТЗ 13.6).
String isoWithOffset(DateTime dt) {
  final offset = dt.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final h = offset.inHours.abs().toString().padLeft(2, '0');
  final m = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
  final base = DateFormat('yyyy-MM-ddTHH:mm:ss').format(dt);
  return '$base$sign$h:$m';
}
