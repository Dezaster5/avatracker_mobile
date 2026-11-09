import '../../../../core/country/country.dart';
import '../entities/app_preferences.dart';
import '../repositories/preferences_repository.dart';

/// Смена страны. Если страна действительно сменилась, язык переключается на
/// язык этой страны (UZ — узбекский, KZ — казахский); дальше пользователь
/// может выбрать язык вручную.
final class ChangeCountry {
  const ChangeCountry(this._repository);

  final PreferencesRepository _repository;

  Future<AppPreferences> call(AppPreferences current, Country country) async {
    await _repository.saveCountry(country);
    if (country == current.country) return current.copyWith(country: country);

    final languageCode = AppLanguages.forCountry(country);
    await _repository.saveLanguage(languageCode);
    return AppPreferences(languageCode: languageCode, country: country);
  }
}
