import '../../../../core/country/country.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/network_guard.dart';
import '../../domain/entities/app_preferences.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../datasources/countries_remote_data_source.dart';
import '../datasources/preferences_local_data_source.dart';

class PreferencesRepositoryImpl implements PreferencesRepository {
  const PreferencesRepositoryImpl({
    required PreferencesLocalDataSource local,
    required CountriesRemoteDataSource remote,
  })  : _local = local,
        _remote = remote;

  final PreferencesLocalDataSource _local;
  final CountriesRemoteDataSource _remote;

  @override
  Future<AppPreferences> load() async {
    final languageCode = await _local.readLanguageCode();
    final countryIso = await _local.readCountryIso();
    return AppPreferences(
      languageCode: languageCode ?? AppLanguages.defaultCode,
      country: Country.byIso(countryIso),
    );
  }

  @override
  Future<void> saveLanguage(String languageCode) =>
      _local.saveLanguageCode(languageCode);

  @override
  Future<void> saveCountry(Country country) =>
      _local.saveCountryIso(country.isoCode);

  @override
  Future<List<Country>> countries() async {
    // Эндпоинт может быть недоступен до входа — тогда берём резервный список.
    final result = await guardRequest(_remote.fetchCountries);
    final countries = switch (result) {
      Success(:final value) => value
          .map((dto) => dto.toEntity())
          .where((country) => country.isoCode.isNotEmpty)
          .toList(),
      Failed() => const <Country>[],
    };
    return countries.isEmpty ? Country.fallback : countries;
  }
}
