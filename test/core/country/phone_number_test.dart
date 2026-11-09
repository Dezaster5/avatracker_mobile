import 'package:avatracker_mobile/core/country/country.dart';
import 'package:avatracker_mobile/core/country/phone_number.dart';
import 'package:avatracker_mobile/core/widgets/country_phone_input_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const kz = Country.kazakhstan;
  const uz = Country.uzbekistan;

  group('PhoneNumber', () {
    test('KZ — 10 цифр', () {
      final phone = PhoneNumber.parse('+7 700 123 45 67', kz);
      expect(phone.national, '7001234567');
      expect(phone.fullDigits, '77001234567');
      expect(phone.e164, '+77001234567');
      expect(PhoneNumber.parse('7001234567', kz).isValid, isTrue);
      expect(PhoneNumber.parse('87001234567', kz).national, '7001234567');
      expect(
          PhoneNumber.fromE164('+77001234567').formatted, '+7 700 123 45 67');
    });

    test('UZ — 9 цифр', () {
      final phone = PhoneNumber.parse('+998 90 123 45 67', uz);
      expect(phone.national, '901234567');
      expect(phone.country.dialCode, '+998');
      expect(PhoneNumber.parse('998901234567', uz).fullDigits, '998901234567');
      expect(PhoneNumber.parse('90123456', uz).isValid, isFalse);
      expect(PhoneNumber.parse('901234567', uz).isValid, isTrue);
      expect(
        PhoneNumber.fromE164('+998901234567').formatted,
        '+998 90 123 45 67',
      );
    });

    test('номер из API отображается в формате страны', () {
      expect(PhoneNumber.display('77001234567'), '+7 700 123 45 67');
      expect(PhoneNumber.display('нет'), 'нет');
    });
  });

  group('Country', () {
    test('страна определяется по коду E.164', () {
      expect(Country.ofE164('+998901234567'), uz);
      expect(Country.ofE164('+77001234567'), kz);
      expect(Country.byIso('UZ'), uz);
      expect(Country.byIso(null), kz);
    });

    test('идентификатор сотрудника зависит от страны', () {
      expect(kz.personalIdLength, 12);
      expect(kz.isValidPersonalId('642918307154'), isTrue);
      expect(kz.isValidPersonalId('64291830715'), isFalse);
      expect(kz.isValidPersonalId('6429183071ab'), isFalse);
      expect(kz.isValidPersonalId('64291830715400'), isFalse);
      expect(uz.personalIdLength, 14);
      expect(uz.isValidPersonalId('30101800123456'), isTrue);
      expect(uz.isValidPersonalId('3'), isTrue);
      expect(uz.isValidPersonalId(''), isFalse);
      expect(uz.isValidPersonalId('301018001234567'), isFalse);
    });
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

    final pasted = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '+7 700 123 45 67'),
    );
    expect(pasted.text, '700 123 45 67');
  });
}
