import 'package:flutter/foundation.dart' show immutable;

/// Страна телефонного номера и идентификатора сотрудника.
///
/// Правила, которые зависят от страны (длина номера, группировка цифр,
/// формат ИИН/ПИНФЛ), собраны здесь, а не разбросаны по проверкам `isoCode`.
@immutable
final class Country {
  const Country({
    required this.id,
    required this.name,
    required this.isoCode,
    required this.dialCode,
    required this.flagEmoji,
  });

  final int id;
  final String name;
  final String isoCode;

  /// Код страны с «+»: `+7`, `+998`.
  final String dialCode;
  final String flagEmoji;

  static const kazakhstan = Country(
    id: 1,
    name: 'Казахстан',
    isoCode: 'KZ',
    dialCode: '+7',
    flagEmoji: '🇰🇿',
  );

  static const uzbekistan = Country(
    id: 2,
    name: 'Узбекистан',
    isoCode: 'UZ',
    dialCode: '+998',
    flagEmoji: '🇺🇿',
  );

  /// Резервный список, если `/countries/` недоступен (используется до входа).
  static const fallback = [kazakhstan, uzbekistan];

  static Country byIso(String? iso) => fallback.firstWhere(
        (country) => country.isoCode == iso,
        orElse: () => fallback.first,
      );

  /// Страна E.164-номера (`+7…` → KZ, `+998…` → UZ). Длинные коды проверяются
  /// первыми, чтобы `+998` не спутать с `+7`.
  static Country ofE164(String e164) {
    final digits = e164.replaceAll(_nonDigits, '');
    final byCodeLength = [...fallback]
      ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
    for (final country in byCodeLength) {
      if (digits.startsWith(country.dialDigits)) return country;
    }
    return fallback.first;
  }

  static final _nonDigits = RegExp(r'\D');

  bool get isKazakhstan => isoCode == 'KZ';
  bool get isUzbekistan => isoCode == 'UZ';

  /// Код страны без «+»: `7`, `998`.
  String get dialDigits => dialCode.replaceAll(_nonDigits, '');

  /// Длина национального номера без кода страны: KZ — 10, UZ — 9.
  int get nationalLength => isUzbekistan ? 9 : 10;

  /// Группы цифр национального номера.
  List<int> get groups =>
      isUzbekistan ? const [2, 3, 2, 2] : const [3, 3, 2, 2];

  /// Пример номера для подсказки в поле ввода.
  String get phoneHint => isUzbekistan ? '90 123 45 67' : '700 123 45 67';

  /// Длина идентификатора сотрудника: ИИН Казахстана — 12 цифр,
  /// ПИНФЛ Узбекистана — до 14 цифр.
  int get personalIdLength => isUzbekistan ? 14 : 12;

  bool isValidPersonalId(String value) => isUzbekistan
      ? RegExp(r'^\d{1,14}$').hasMatch(value)
      : RegExp(r'^\d{12}$').hasMatch(value);

  /// Группирует национальные цифры: KZ «700 123 45 67», UZ «90 123 45 67».
  /// Цифры сверх [nationalLength] отбрасываются.
  String formatNational(String national) {
    final digits = national.length > nationalLength
        ? national.substring(0, nationalLength)
        : national;
    final parts = <String>[];
    var start = 0;
    for (final size in groups) {
      if (start >= digits.length) break;
      final end = start + size > digits.length ? digits.length : start + size;
      parts.add(digits.substring(start, end));
      start = end;
    }
    if (start < digits.length) parts.add(digits.substring(start));
    return parts.join(' ');
  }

  @override
  bool operator ==(Object other) =>
      other is Country && other.isoCode == isoCode;

  @override
  int get hashCode => isoCode.hashCode;
}
