import 'package:avatracker_mobile/core/utils/date_formatters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  test('isoWithOffset содержит локальное смещение', () {
    final value = isoWithOffset(DateTime(2026, 6, 5, 16, 22));
    expect(value.startsWith('2026-06-05T16:22:00'), isTrue);
    expect(RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(value), isTrue);
  });

  test('заголовок месяца с заглавной буквы', () async {
    await initializeDateFormatting('ru');
    expect(formatMonthTitle(DateTime(2026, 6), locale: 'ru'), 'Июнь 2026');
  });
}
