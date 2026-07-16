import 'package:flutter_test/flutter_test.dart';

import 'package:avatracker_mobile/core/country/country.dart';
import 'package:avatracker_mobile/core/utils/formatters.dart';

void main() {
  group('PhoneInputFormatter', () {
    TextEditingValue format(String input) =>
        PhoneInputFormatter().formatEditUpdate(
            TextEditingValue.empty, TextEditingValue(text: input));

    test('полный номер с 8 приводится к +7', () {
      expect(format('87001234567').text, '+7 700 123 45 67');
    });

    test('полный номер с +7', () {
      expect(format('+77001234567').text, '+7 700 123 45 67');
    });

    test('частичный ввод без кода страны', () {
      expect(format('700123').text, '+7 700 123');
    });

    test('лишние цифры обрезаются', () {
      expect(format('+7700123456799').text, '+7 700 123 45 67');
    });

    test('посимвольный ввод не добавляет фантомную семерку', () {
      final formatter = PhoneInputFormatter();
      var value = TextEditingValue.empty;
      for (final ch in '7001234567'.split('')) {
        value = formatter.formatEditUpdate(
          value,
          TextEditingValue(text: '${value.text}$ch'),
        );
      }
      expect(value.text, '+7 700 123 45 67');
    });

    test('backspace удаляет цифры, пустой префикс очищается', () {
      final formatter = PhoneInputFormatter();
      var value = format('702');
      expect(value.text, '+7 702');

      TextEditingValue erase() => formatter.formatEditUpdate(
            value,
            TextEditingValue(
              text: value.text.substring(0, value.text.length - 1),
            ),
          );

      value = erase();
      expect(value.text, '+7 70');
      value = erase();
      expect(value.text, '+7 7');
      value = erase();
      expect(value.text, '');
    });
  });

  test('normalizePhone', () {
    expect(normalizePhone('+7 700 123 45 67'), '+77001234567');
    expect(normalizePhone('8 700 123 45 67'), '+77001234567');
    expect(normalizePhone('700 123 45 67'), '+77001234567');
    expect(normalizePhone('87001234567'), '+77001234567');
  });

  test('formatPhone', () {
    expect(formatPhone('+77001234567'), '+7 700 123 45 67');
  });

  test('splitPhone разделяет код страны и национальный номер', () {
    final a = splitPhone('+7 700 123 45 67');
    expect(a.dialCode, '+7');
    expect(a.number, '7001234567');

    final b = splitPhone('87001234567');
    expect(b.dialCode, '+7');
    expect(b.number, '7001234567');
  });

  group('Телефон с учётом страны', () {
    final kz = Country.fallback[0];
    final uz = Country.fallback[1];

    test('KZ — 10 цифр', () {
      expect(phoneNational('+7 700 123 45 67', kz), '7001234567');
      expect(fullPhoneFor('+77001234567', kz), '77001234567');
      expect(isValidPhoneFor('7001234567', kz), true);
      expect(prettyE164('+77001234567'), '+7 700 123 45 67');
    });

    test('UZ — 9 цифр', () {
      expect(phoneNational('+998 90 123 45 67', uz), '901234567');
      expect(fullPhoneFor('998901234567', uz), '998901234567');
      final apiPhone = splitPhoneFor('+998 90 123 45 67', uz);
      expect(apiPhone.dialCode, '+998');
      expect(apiPhone.number, '901234567');
      expect(isValidPhoneFor('90123456', uz), false);
      expect(isValidPhoneFor('901234567', uz), true);
      expect(prettyE164('+998901234567'), '+998 90 123 45 67');
    });

    test('countryOfE164 различает UZ и KZ', () {
      expect(countryOfE164('+998901234567').isoCode, 'UZ');
      expect(countryOfE164('+77001234567').isoCode, 'KZ');
    });

    test('форматтер не принимает цифры сверх лимита страны', () {
      final formatter = CountryPhoneInputFormatter(kz);
      final full = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '7001234567'),
      );
      expect(full.text, '700 123 45 67');

      final overflow = formatter.formatEditUpdate(
        full,
        const TextEditingValue(text: '700 123 45 678'),
      );
      expect(overflow.text, full.text);
    });

    test('код страны из API нормализуется с плюсом', () {
      final country = Country.fromJson({
        'iso_code': 'uz',
        'dial_code': '998',
      });
      expect(country.isoCode, 'UZ');
      expect(country.dialCode, '+998');
    });
  });

  test('isValidKzPhone', () {
    expect(isValidKzPhone('+7 700 123 45 67'), true);
    expect(isValidKzPhone('+7 700 123'), false);
  });

  test('isValidIin', () {
    expect(isValidIin('642918307154'), true);
    expect(isValidIin('64291830715'), false);
    expect(isValidIin('6429183071ab'), false);
  });

  test('идентификатор зависит от выбранной страны', () {
    final kz = Country.fallback[0];
    final uz = Country.fallback[1];

    expect(personalIdentifierLength(kz), 12);
    expect(isValidPersonalIdentifier('642918307154', kz), true);
    expect(isValidPersonalIdentifier('64291830715400', kz), false);
    expect(personalIdentifierLength(uz), 14);
    expect(isValidPersonalIdentifier('30101800123456', uz), true);
    expect(isValidPersonalIdentifier('3010180012345', uz), false);
  });

  test('isValidPassword', () {
    expect(isValidPassword('123456'), true);
    expect(isValidPassword('qwerty12'), true);
    expect(isValidPassword('12345'), false);
    expect(isValidPassword('пароль с пробелом'), false);
  });

  test('formatMinutes', () {
    expect(formatMinutes(275), '4 ч 35 мин');
    expect(formatMinutes(540), '9 ч');
    expect(formatMinutes(45), '45 мин');
    expect(formatMinutes(0), '0 мин');
    expect(formatMinutes(-90), '1 ч 30 мин');
  });

  test('monthParam', () {
    expect(monthParam(DateTime(2026, 6)), '2026-06');
    expect(monthParam(DateTime(2026, 11)), '2026-11');
  });

  test('isoWithOffset содержит локальное смещение', () {
    final value = isoWithOffset(DateTime(2026, 6, 5, 16, 22));
    expect(value.startsWith('2026-06-05T16:22:00'), true);
    expect(RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(value), true);
  });
}
