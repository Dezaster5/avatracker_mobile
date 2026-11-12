import '../entities/app_preferences.dart';
import '../repositories/preferences_repository.dart';

final class ChangeLanguage {
  const ChangeLanguage(this._repository);

  final PreferencesRepository _repository;

  Future<AppPreferences> call(
    AppPreferences current,
    String languageCode,
  ) async {
    await _repository.saveLanguage(languageCode);
    return current.copyWith(languageCode: languageCode);
  }
}
