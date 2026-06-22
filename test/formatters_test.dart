import 'package:flutter_test/flutter_test.dart';

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

  test('isValidKzPhone', () {
    expect(isValidKzPhone('+7 700 123 45 67'), true);
    expect(isValidKzPhone('+7 700 123'), false);
  });

  test('isValidIin', () {
    expect(isValidIin('642918307154'), true);
    expect(isValidIin('64291830715'), false);
    expect(isValidIin('6429183071ab'), false);
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
