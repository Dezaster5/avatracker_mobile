import '../../../../core/country/country.dart';
import '../repositories/preferences_repository.dart';

final class GetCountries {
  const GetCountries(this._repository);

  final PreferencesRepository _repository;

  Future<List<Country>> call() => _repository.countries();
}
