import 'package:flutter/foundation.dart' show immutable;

import 'country.dart';

/// Номер телефона с учётом страны.
///
/// Мобильный API ждёт номер в разных форматах на разных шагах: национальный
/// номер + `dial_code`, полный номер без «+» или E.164 — все они берутся
/// отсюда, а не собираются строками по месту.
@immutable
final class PhoneNumber {
  const PhoneNumber._(this.country, this._digits);

  /// Ввод пользователя для выбранной страны. Код страны и межгородская «8»
  /// (KZ) отбрасываются.
  factory PhoneNumber.parse(String input, Country country) =>
      PhoneNumber._(country, _nationalDigits(input, country));

  /// Номер в международном формате; страна определяется по коду.
  factory PhoneNumber.fromE164(String e164) =>
      PhoneNumber.parse(e164, Country.ofE164(e164));

  final Country country;

  /// Национальные цифры в том количестве, в каком их ввели.
  final String _digits;

  /// Национальный номер без кода страны: KZ — 10 цифр, UZ — 9.
  String get national => _digits.length > country.nationalLength
      ? _digits.substring(0, country.nationalLength)
      : _digits;

  bool get isValid => _digits.length == country.nationalLength;

  /// `+77001234567` — формат хранения в сессии.
  String get e164 => '${country.dialCode}$national';

  /// Полный номер без «+»: `77001234567`, `998901234567`.
  String get fullDigits => '${country.dialDigits}$national';

  /// `+7 700 123 45 67`, `+998 90 123 45 67`.
  String get formatted =>
      '${country.dialCode} ${country.formatNational(_digits)}';

  /// Отображение номера из API в любом формате; нераспознанное — как есть.
  static String display(String raw) {
    final phone = PhoneNumber.fromE164(raw);
    return phone._digits.isEmpty ? raw : phone.formatted;
  }

  static String _nationalDigits(String input, Country country) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    final longerThanNational = digits.length > country.nationalLength;
    if (longerThanNational && digits.startsWith(country.dialDigits)) {
      return digits.substring(country.dialDigits.length);
    }
    if (longerThanNational && country.isKazakhstan && digits.startsWith('8')) {
      return digits.substring(1);
    }
    return digits;
  }

  @override
  bool operator ==(Object other) =>
      other is PhoneNumber &&
      other.country == country &&
      other._digits == _digits;

  @override
  int get hashCode => Object.hash(country, _digits);

  @override
  String toString() => e164;
}
