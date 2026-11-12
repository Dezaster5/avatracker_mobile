import 'package:avatracker_mobile/core/country/country.dart';
import 'package:avatracker_mobile/features/preferences/data/datasources/countries_remote_data_source.dart';
import 'package:avatracker_mobile/features/preferences/data/datasources/preferences_local_data_source.dart';
import 'package:avatracker_mobile/features/preferences/data/models/country_dto.dart';
import 'package:avatracker_mobile/features/preferences/data/repositories/preferences_repository_impl.dart';
import 'package:avatracker_mobile/features/preferences/domain/entities/app_preferences.dart';
import 'package:avatracker_mobile/features/preferences/domain/usecases/change_country.dart';
import 'package:avatracker_mobile/features/preferences/domain/usecases/change_language.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _OfflineCountries extends CountriesRemoteDataSource {
  _OfflineCountries() : super(Dio());

  @override
  Future<List<CountryDto>> fetchCountries() async =>
      throw DioException.connectionError(
          requestOptions: RequestOptions(), reason: 'offline');
}

void main() {
  late PreferencesRepositoryImpl repository;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    repository = PreferencesRepositoryImpl(
      local: const PreferencesLocalDataSource(FlutterSecureStorage()),
      remote: _OfflineCountries(),
    );
  });

  test('по умолчанию — казахский язык и Казахстан', () async {
    expect(await repository.load(), AppPreferences.defaults);
  });

  test('смена страны переключает язык и сохраняется', () async {
    final changed = await ChangeCountry(repository)
        .call(AppPreferences.defaults, Country.uzbekistan);

    expect(changed.country, Country.uzbekistan);
    expect(changed.languageCode, 'uz');
    expect(await repository.load(), changed);
  });

  test('та же страна не сбрасывает выбранный вручную язык', () async {
    final russian =
        await ChangeLanguage(repository).call(AppPreferences.defaults, 'ru');
    final same =
        await ChangeCountry(repository).call(russian, Country.kazakhstan);

    expect(same.languageCode, 'ru');
  });

  test('без API стран используется резервный список', () async {
    expect(await repository.countries(), Country.fallback);
  });

  test('код страны из API нормализуется с плюсом', () {
    final country =
        CountryDto.fromJson({'iso_code': 'uz', 'dial_code': '998'}).toEntity();
    expect(country.isoCode, 'UZ');
    expect(country.dialCode, '+998');
  });
}
