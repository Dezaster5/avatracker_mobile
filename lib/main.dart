import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/devtools/dev_log_store.dart';
import 'features/preferences/presentation/controllers/preferences_controller.dart';

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

  final container = ProviderContainer();
  // Язык и страна берутся из хранилища до первого кадра (без мигания).
  await container.read(preferencesControllerProvider.notifier).restore();
  await Future.wait([
    initializeDateFormatting('kk'),
    initializeDateFormatting('ru'),
    initializeDateFormatting('uz'),
  ]);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AvaTrackerApp(),
    ),
  );
}
