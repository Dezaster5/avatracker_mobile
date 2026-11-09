import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/country/country.dart';
import '../../di/preferences_providers.dart';
import '../../domain/entities/app_preferences.dart';

/// Язык интерфейса и страна телефона.
class PreferencesController extends Notifier<AppPreferences> {
  @override
  AppPreferences build() => AppPreferences.defaults;

  /// Вызывается в `main` до `runApp`, чтобы первый кадр был на нужном языке.
  Future<void> restore() async {
    _apply(await ref.read(loadPreferencesProvider).call());
  }

  Future<void> selectLanguage(String languageCode) async {
    if (languageCode == state.languageCode) return;
    _apply(await ref.read(changeLanguageProvider).call(state, languageCode));
  }

  Future<void> selectCountry(Country country) async {
    _apply(await ref.read(changeCountryProvider).call(state, country));
  }

  void _apply(AppPreferences preferences) {
    // `intl` форматирует даты по глобальной локали — держим её в синхроне.
    Intl.defaultLocale = preferences.languageCode;
    state = preferences;
  }
}

final preferencesControllerProvider =
    NotifierProvider<PreferencesController, AppPreferences>(
  PreferencesController.new,
);

final localeProvider = Provider<Locale>(
  (ref) => Locale(
    ref.watch(preferencesControllerProvider.select((p) => p.languageCode)),
  ),
);

final selectedCountryProvider = Provider<Country>(
  (ref) => ref.watch(preferencesControllerProvider.select((p) => p.country)),
);

/// Страны для выбора кода телефона (с резервным списком).
final countriesProvider = FutureProvider<List<Country>>(
  (ref) => ref.watch(getCountriesProvider).call(),
);
