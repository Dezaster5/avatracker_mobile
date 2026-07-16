import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../country/country.dart';

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

/// Разбивает номер на `dial_code` + национальный номер для мобильного API,
/// которое хранит код страны отдельным полем.
///
/// Пока Казахстан: `dial_code = '+7'`, `phone = 10 цифр` (`7001234567`).
/// Когда добавим Узбекистан, выбор кода будет по введённому номеру.
({String dialCode, String number}) splitPhone(String input) {
  return (dialCode: '+7', number: _subscriberDigits(input));
}

/// `+77001234567` -> `+7 700 123 45 67`.
String formatPhone(String normalized) {
  final subscriber = _subscriberDigits(normalized);
  if (subscriber.length != 10) return normalized;
  return _formatSubscriber(subscriber);
}

bool isValidKzPhone(String input) => _subscriberDigits(input).length == 10;

// ─── Телефон с учётом выбранной страны (KZ 10 цифр / UZ 9 цифр) ─────────────

/// Национальные цифры номера для страны (без кода страны).
String phoneNational(String input, Country country) {
  var digits = input.replaceAll(RegExp(r'\D'), '');
  final code = country.dialCode.replaceAll(RegExp(r'\D'), '');
  final n = country.nationalLength;
  // Ввод с кодом страны или межгородской «8» — убираем префикс.
  if (digits.length > n && digits.startsWith(code)) {
    digits = digits.substring(code.length);
  } else if (country.isoCode == 'KZ' &&
      digits.length > n &&
      digits.startsWith('8')) {
    digits = digits.substring(1);
  }
  return digits;
}

String _limitedPhoneNational(String input, Country country) {
  final digits = phoneNational(input, country);
  return digits.length > country.nationalLength
      ? digits.substring(0, country.nationalLength)
      : digits;
}

String _phoneFieldNational(String input, Country country) {
  final raw = input.trim();
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  final code = country.dialCode.replaceAll(RegExp(r'\D'), '');
  final n = country.nationalLength;

  if (raw.startsWith('+') && digits.length > n && digits.startsWith(code)) {
    digits = digits.substring(code.length);
  } else if (country.isoCode == 'KZ' &&
      digits.length > n &&
      digits.startsWith('8')) {
    digits = digits.substring(1);
  } else if (country.isoCode != 'KZ' &&
      digits.length > n &&
      digits.startsWith(code)) {
    digits = digits.substring(code.length);
  }
  return digits;
}

/// Форматирует национальные цифры группами: KZ «700 123 45 67», UZ «90 123 45 67».
String formatNational(String national, Country country) {
  if (national.length > country.nationalLength) {
    national = national.substring(0, country.nationalLength);
  }
  final parts = <String>[];
  var i = 0;
  for (final g in country.groups) {
    if (i >= national.length) break;
    final end = (i + g) > national.length ? national.length : i + g;
    parts.add(national.substring(i, end));
    i = end;
  }
  if (i < national.length) parts.add(national.substring(i));
  return parts.join(' ');
}

bool isValidPhoneFor(String input, Country country) =>
    phoneNational(input, country).length == country.nationalLength;

/// `dial_code` + национальный номер для login/register.
({String dialCode, String number}) splitPhoneFor(
        String input, Country country) =>
    (dialCode: country.dialCode, number: _limitedPhoneNational(input, country));

/// Полный номер с кодом страны без «+»: KZ «77001234567», UZ «998901234567».
String fullPhoneFor(String input, Country country) {
  final code = country.dialCode.replaceAll(RegExp(r'\D'), '');
  return '$code${_limitedPhoneNational(input, country)}';
}

/// `+77001234567` / `+998901234567` — для отображения (хранения телефона сессии).
String e164For(String input, Country country) =>
    '${country.dialCode}${_limitedPhoneNational(input, country)}';

/// Красивое отображение E.164-номера с учётом страны:
/// `+7 700 123 45 67` / `+998 90 123 45 67`.
String prettyE164(String e164) {
  final c = countryOfE164(e164);
  final national = phoneNational(e164, c);
  if (national.isEmpty) return e164;
  return '${c.dialCode} ${formatNational(national, c)}';
}

/// Определяет страну по E.164-номеру (`+7…` → KZ, `+998…` → UZ).
/// Длинные коды проверяем первыми, чтобы `+998` не спутать с `+7`.
Country countryOfE164(String e164) {
  final digits = e164.replaceAll(RegExp(r'\D'), '');
  final byCode = [...Country.fallback]..sort(
      (a, b) => b.dialCode.length.compareTo(a.dialCode.length),
    );
  for (final c in byCode) {
    final code = c.dialCode.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith(code)) return c;
  }
  return Country.fallback.first;
}

/// Форматтер поля телефона с учётом страны (группировка без кода страны).
class CountryPhoneInputFormatter extends TextInputFormatter {
  CountryPhoneInputFormatter(this.country);

  final Country country;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final national = _phoneFieldNational(newValue.text, country);
    if (national.length > country.nationalLength) {
      return oldValue;
    }
    final text = national.isEmpty ? '' : formatNational(national, country);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

bool isValidIin(String iin) => RegExp(r'^\d{12}$').hasMatch(iin);

/// Казахстан использует 12-значный ИИН, Узбекистан — 14-значный ПИНФЛ.
int personalIdentifierLength(Country country) =>
    country.isoCode == 'UZ' ? 14 : 12;

bool isValidPersonalIdentifier(String value, Country country) => RegExp(
      '^\\d{${personalIdentifierLength(country)}}\$',
    ).hasMatch(value);

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
String formatMonthTitle(DateTime month, {String locale = 'ru'}) {
  final raw = DateFormat('LLLL yyyy', locale).format(month);
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
