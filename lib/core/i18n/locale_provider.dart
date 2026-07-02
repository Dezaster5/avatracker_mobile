import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Язык по умолчанию — казахский (первым в списке выбора).
const defaultLocaleCode = 'kk';

/// Порядок языков в выборе: Қазақша, Oʻzbekcha, Русский.
const localeOrder = ['kk', 'uz', 'ru'];

/// Текущий язык интерфейса. По умолчанию [defaultLocaleCode]; в main
/// перекрывается сохранённым значением из хранилища.
final localeProvider =
    StateProvider<Locale>((ref) => const Locale(defaultLocaleCode));

/// Поддерживаемые языки приложения.
const appSupportedLocales = [
  Locale('kk'),
  Locale('uz'),
  Locale('ru'),
];
