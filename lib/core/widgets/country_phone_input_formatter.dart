import 'package:flutter/services.dart';

import '../country/country.dart';

/// Форматирует поле телефона группами цифр выбранной страны (без кода
/// страны) и не пропускает цифры сверх длины национального номера.
class CountryPhoneInputFormatter extends TextInputFormatter {
  CountryPhoneInputFormatter(this.country);

  final Country country;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final national = _fieldDigits(newValue.text);
    if (national.length > country.nationalLength) return oldValue;
    final text = national.isEmpty ? '' : country.formatNational(national);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// Цифры поля без кода страны. Вставка в международном формате (`+7…`)
  /// и межгородская «8» (KZ) обрабатываются отдельно от обычного ввода.
  String _fieldDigits(String input) {
    final raw = input.trim();
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final code = country.dialDigits;
    final longerThanNational = digits.length > country.nationalLength;

    if (raw.startsWith('+') && longerThanNational && digits.startsWith(code)) {
      return digits.substring(code.length);
    }
    if (country.isKazakhstan && longerThanNational && digits.startsWith('8')) {
      return digits.substring(1);
    }
    if (!country.isKazakhstan &&
        longerThanNational &&
        digits.startsWith(code)) {
      return digits.substring(code.length);
    }
    return digits;
  }
}
