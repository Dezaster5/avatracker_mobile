import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../models/country_dto.dart';

class CountriesRemoteDataSource {
  const CountriesRemoteDataSource(this._dio);

  final Dio _dio;

  /// `GET /countries/` — пагинированный `{results: [...]}` или список.
  Future<List<CountryDto>> fetchCountries() async {
    final response = await _dio.get<dynamic>(ApiEndpoints.countries);
    final data = response.data;
    final results = data is Map ? data['results'] : data;
    if (results is! List) return const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(CountryDto.fromJson)
        .toList();
  }
}
