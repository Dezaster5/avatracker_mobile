import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avatracker_mobile/core/i18n/locale_provider.dart';
import 'package:avatracker_mobile/l10n/app_localizations.dart';
import 'package:avatracker_mobile/l10n/l10n_ext.dart';

void main() {
  test('приложение поддерживает казахский, русский и узбекский', () {
    expect(
      AppLocalizations.supportedLocales.map((locale) => locale.languageCode),
      containsAll(<String>['kk', 'ru', 'uz']),
    );
  });

  test('страна автоматически выбирает локальный язык', () {
    expect(localeCodeForCountry('KZ'), 'kk');
    expect(localeCodeForCountry('UZ'), 'uz');
  });

  test('основная навигация переведена для всех локалей', () {
    final kk = lookupAppLocalizations(const Locale('kk'));
    final ru = lookupAppLocalizations(const Locale('ru'));
    final uz = lookupAppLocalizations(const Locale('uz'));

    expect(kk.tabScanner, 'Сканер');
    expect(ru.tabAnalytics, 'Аналитика');
    expect(uz.tabProfile, 'Profil');
    expect(uz.fieldPinfl, 'JShShIR (PINFL)');
    expect(uz.validatorPinfl, contains('kiriting'));
  });

  test('длительность форматируется в выбранной локали', () {
    final kk = lookupAppLocalizations(const Locale('kk'));
    final ru = lookupAppLocalizations(const Locale('ru'));
    final uz = lookupAppLocalizations(const Locale('uz'));

    expect(kk.formatDuration(125), '2 сағ 5 мин');
    expect(ru.formatDuration(125), '2 ч 5 мин');
    expect(uz.formatDuration(125), '2 soat 5 daq');
  });

  test('клиентские ошибки локализуются, серверный текст сохраняется', () {
    final uz = lookupAppLocalizations(const Locale('uz'));

    expect(
      uz.localizeKnownMessage('Сессия истекла. Войдите заново'),
      uz.errorSessionExpired,
    );
    expect(
      uz.localizeKnownMessage('Специальное сообщение backend'),
      'Специальное сообщение backend',
    );
  });

  test('удаление аккаунта и неудачный снимок — тоже известные ключи', () {
    final kk = lookupAppLocalizations(const Locale('kk'));

    expect(
      kk.localizeKnownMessage('Аккаунт удалён. Зарегистрируйтесь заново'),
      kk.accountDeleted,
    );
    expect(
      kk.localizeKnownMessage('Не удалось сделать снимок. Попробуйте ещё раз'),
      kk.photoCaptureFailed,
    );
  });

  test(
      'один и тот же сырой текст переводится под текущую локаль, '
      'а не остаётся «замороженным» в языке момента ошибки', () {
    const raw = 'Ошибка соединения. Попробуйте позже';
    final ru = lookupAppLocalizations(const Locale('ru'));
    final kk = lookupAppLocalizations(const Locale('kk'));

    // Экраны хранят именно `raw`, а не заранее переведённую строку — иначе
    // при смене языка после ошибки текст остался бы в старом языке.
    expect(ru.localizeKnownMessage(raw), ru.errorConnection);
    expect(kk.localizeKnownMessage(raw), kk.errorConnection);
    expect(ru.errorConnection == kk.errorConnection, isFalse);
  });
}
