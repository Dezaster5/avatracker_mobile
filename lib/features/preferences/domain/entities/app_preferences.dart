import 'package:flutter/foundation.dart' show immutable;

import '../../../../core/country/country.dart';

/// Языки интерфейса и правило выбора языка по стране.
abstract final class AppLanguages {
  /// Язык по умолчанию — казахский (первым в списке выбора).
  static const defaultCode = 'kk';

  /// Порядок языков в выборе: Қазақша, Oʻzbekcha, Русский.
  static const ordered = ['kk', 'uz', 'ru'];

  /// Язык, который выбирается автоматически вместе со страной.
  static String forCountry(Country country) =>
      country.isUzbekistan ? 'uz' : 'kk';
}

/// Настройки устройства: язык интерфейса и страна телефона. Переживают
/// выход из аккаунта.
@immutable
final class AppPreferences {
  const AppPreferences({required this.languageCode, required this.country});

  static const defaults = AppPreferences(
    languageCode: AppLanguages.defaultCode,
    country: Country.kazakhstan,
  );

  final String languageCode;
  final Country country;

  AppPreferences copyWith({String? languageCode, Country? country}) =>
      AppPreferences(
        languageCode: languageCode ?? this.languageCode,
        country: country ?? this.country,
      );

  @override
  bool operator ==(Object other) =>
      other is AppPreferences &&
      other.languageCode == languageCode &&
      other.country == country;

  @override
  int get hashCode => Object.hash(languageCode, country);
}
