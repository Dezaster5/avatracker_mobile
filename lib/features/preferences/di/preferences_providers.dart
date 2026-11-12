import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/core_providers.dart';
import '../data/datasources/countries_remote_data_source.dart';
import '../data/datasources/preferences_local_data_source.dart';
import '../data/repositories/preferences_repository_impl.dart';
import '../domain/repositories/preferences_repository.dart';
import '../domain/usecases/change_country.dart';
import '../domain/usecases/change_language.dart';
import '../domain/usecases/get_countries.dart';
import '../domain/usecases/load_preferences.dart';

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepositoryImpl(
    local: PreferencesLocalDataSource(ref.watch(secureStorageProvider)),
    remote: CountriesRemoteDataSource(ref.watch(apiClientProvider).dio),
  );
});

final loadPreferencesProvider = Provider(
  (ref) => LoadPreferences(ref.watch(preferencesRepositoryProvider)),
);

final changeLanguageProvider = Provider(
  (ref) => ChangeLanguage(ref.watch(preferencesRepositoryProvider)),
);

final changeCountryProvider = Provider(
  (ref) => ChangeCountry(ref.watch(preferencesRepositoryProvider)),
);

final getCountriesProvider = Provider(
  (ref) => GetCountries(ref.watch(preferencesRepositoryProvider)),
);
