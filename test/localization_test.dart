import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avatracker_mobile/l10n/app_localizations.dart';
import 'package:avatracker_mobile/l10n/l10n_ext.dart';

void main() {
  test('приложение поддерживает казахский, русский и узбекский', () {
    expect(
      AppLocalizations.supportedLocales.map((locale) => locale.languageCode),
      containsAll(<String>['kk', 'ru', 'uz']),
    );
  });

  test('основная навигация переведена для всех локалей', () {
    final kk = lookupAppLocalizations(const Locale('kk'));
    final ru = lookupAppLocalizations(const Locale('ru'));
    final uz = lookupAppLocalizations(const Locale('uz'));

    expect(kk.tabScanner, 'Сканер');
    expect(ru.tabAnalytics, 'Аналитика');
    expect(uz.tabProfile, 'Profil');
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
}
