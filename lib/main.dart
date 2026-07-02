import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'core/country/country.dart';
import 'core/country/country_providers.dart';
import 'core/i18n/locale_provider.dart';
import 'core/storage/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Язык и страна берутся из хранилища до первого кадра (без мигания).
  final storage = TokenStorage();
  final localeCode = await storage.localeCode ?? defaultLocaleCode;
  final countryIso = await storage.countryIso;

  await Future.wait([
    initializeDateFormatting('kk'),
    initializeDateFormatting('ru'),
    initializeDateFormatting('uz'),
  ]);
  Intl.defaultLocale = localeCode;

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => Locale(localeCode)),
        selectedCountryProvider
            .overrideWith((ref) => Country.byIso(countryIso)),
      ],
      child: const AvaTrackerApp(),
    ),
  );
}
