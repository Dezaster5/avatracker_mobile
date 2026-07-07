import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/country/country.dart';
import 'core/country/country_providers.dart';
import 'core/devtools/dev_log_store.dart';
import 'core/i18n/locale_provider.dart';
import 'core/storage/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Зеркалим debugPrint (в т.ч. существующие вызовы по коду) в панель
  // разработчика — работает и в release-сборке с DEV_TOOLS=true, где
  // обычный вывод в консоль/logcat недоступен тестировщику.
  if (AppConfig.devToolsEnabled) {
    final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) devLogStore.addLog(message);
      originalDebugPrint(message, wrapWidth: wrapWidth);
    };
  }

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
