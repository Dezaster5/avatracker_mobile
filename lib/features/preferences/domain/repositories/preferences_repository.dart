import '../../../../core/country/country.dart';
import '../entities/app_preferences.dart';

abstract interface class PreferencesRepository {
  /// Сохранённые настройки, а без них — [AppPreferences.defaults].
  Future<AppPreferences> load();

  Future<void> saveLanguage(String languageCode);

  Future<void> saveCountry(Country country);

  /// Страны для выбора кода телефона; при недоступном API — резервный список.
  Future<List<Country>> countries();
}
