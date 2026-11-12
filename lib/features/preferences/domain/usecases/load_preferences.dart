import '../entities/app_preferences.dart';
import '../repositories/preferences_repository.dart';

/// Настройки до первого кадра — язык и страна без мигания.
final class LoadPreferences {
  const LoadPreferences(this._repository);

  final PreferencesRepository _repository;

  Future<AppPreferences> call() => _repository.load();
}
