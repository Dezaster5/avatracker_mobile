import 'package:avatracker_mobile/core/country/country.dart';
import 'package:avatracker_mobile/core/error/failure.dart';
import 'package:avatracker_mobile/features/auth/domain/entities/session_restoration.dart';
import 'package:avatracker_mobile/features/auth/presentation/logout_reason_l10n.dart';
import 'package:avatracker_mobile/features/preferences/domain/entities/app_preferences.dart';
import 'package:avatracker_mobile/l10n/app_localizations.dart';
import 'package:avatracker_mobile/l10n/failure_l10n.dart';
import 'package:avatracker_mobile/l10n/l10n_ext.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('приложение поддерживает казахский, русский и узбекский', () {
    expect(
      AppLocalizations.supportedLocales.map((locale) => locale.languageCode),
      containsAll(<String>['kk', 'ru', 'uz']),
    );
  });

  test('страна автоматически выбирает локальный язык', () {
    expect(AppLanguages.forCountry(Country.kazakhstan), 'kk');
    expect(AppLanguages.forCountry(Country.uzbekistan), 'uz');
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

  test('ошибки клиента переводятся, текст сервера показывается как есть', () {
    final uz = lookupAppLocalizations(const Locale('uz'));

    expect(
      uz.failureMessage(const UnauthorizedFailure()),
      uz.errorSessionExpired,
    );
    expect(
      uz.failureMessage(
        const ValidationFailure(serverMessage: 'Специальное сообщение backend'),
      ),
      'Специальное сообщение backend',
    );
  });

  test('текст ошибки зависит от текущего языка, а не от момента ошибки', () {
    final ru = lookupAppLocalizations(const Locale('ru'));
    final kk = lookupAppLocalizations(const Locale('kk'));

    expect(ru.failureMessage(const NetworkFailure()), ru.errorConnection);
    expect(kk.failureMessage(const TimeoutFailure()), kk.errorConnection);
    expect(ru.errorConnection == kk.errorConnection, isFalse);
  });

  test('ответ сервера без текста не выдаётся за обрыв связи', () {
    final ru = lookupAppLocalizations(const Locale('ru'));

    expect(ru.failureMessage(const ForbiddenFailure()), ru.errorForbidden);
    expect(ru.failureMessage(const NotFoundFailure()), ru.errorNotFound);
    expect(ru.failureMessage(const ValidationFailure()), ru.errorValidation);
    expect(ru.failureMessage(const ServerFailure()), ru.errorServer);
    expect(ru.failureMessage(const UnknownFailure()), ru.errorUnexpected);
  });

  test('ошибки отметки и геолокации', () {
    final kk = lookupAppLocalizations(const Locale('kk'));

    expect(
      kk.failureMessage(const QrNotRegisteredFailure('park-1')),
      '${kk.qrNotRegistered}\n${kk.qrCodeValue('park-1')}',
    );
    expect(
      kk.failureMessage(
        const LocationFailure(
          LocationFailureCode.lowAccuracy,
          accuracyMeters: 120,
        ),
      ),
      kk.locationLowAccuracy(120),
    );
    expect(kk.errorMessage(StateError('bug')), kk.errorUnexpected);
  });

  test('причина выхода из аккаунта переводится', () {
    final kk = lookupAppLocalizations(const Locale('kk'));

    expect(
      kk.logoutReasonMessage(LogoutReason.accountDeleted),
      kk.accountDeleted,
    );
    expect(
      kk.logoutReasonMessage(LogoutReason.sessionExpired),
      kk.errorSessionExpired,
    );
  });
}
