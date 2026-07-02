import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers.dart';
import 'country.dart';

/// Список стран из `GET /api/v1/countries/` с фолбэком на статический список.
final countriesProvider = FutureProvider<List<Country>>((ref) async {
  try {
    final dio = ref.watch(apiClientProvider).dio;
    final res = await dio.get<dynamic>('/countries/');
    final data = res.data;
    final results = data is Map ? data['results'] : data;
    if (results is List) {
      final list = results
          .whereType<Map<String, dynamic>>()
          .map(Country.fromJson)
          .where((c) => c.isoCode.isNotEmpty)
          .toList();
      if (list.isNotEmpty) return list;
    }
  } catch (_) {/* эндпоинт недоступен/без авторизации — берём фолбэк */}
  return Country.fallback;
});

/// Выбранная страна для кода телефона. По умолчанию KZ; в main
/// перекрывается сохранённым значением из хранилища.
final selectedCountryProvider =
    StateProvider<Country>((ref) => Country.fallback.first);
