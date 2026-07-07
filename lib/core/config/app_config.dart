import 'package:flutter/foundation.dart' show kDebugMode;

/// Конфигурация приложения.
///
/// Базовый URL и mock-режим задаются при сборке:
/// ```
/// flutter run --dart-define=API_BASE_URL=https://avatracker.online/api/v1
/// flutter run --dart-define=MOCK_API=true   # демо без бэкенда
/// flutter run --dart-define=TEST_IIN=... --dart-define=TEST_BEARER_TOKEN=...
/// flutter build apk --release --dart-define=DEV_TOOLS=true   # dev-сборка с панелью логов
/// ```
abstract final class AppConfig {
  /// База data-API (профиль в тест-режиме, табель, аналитика, скан).
  /// Авторизация и `profile/me` живут на отдельной мобильной базе [mobileApiBaseUrl].
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://avatracker.online/api/v1',
  );

  static const _mobileApiBaseUrlOverride =
      String.fromEnvironment('MOBILE_API_BASE_URL');

  /// База мобильного API авторизации (SimpleJWT): `…/api/mobile`.
  /// Выводится из [apiBaseUrl] заменой `/api/<...>` на `/api/mobile`,
  /// либо задаётся явно через `--dart-define=MOBILE_API_BASE_URL=`.
  static String get mobileApiBaseUrl {
    if (_mobileApiBaseUrlOverride.isNotEmpty) {
      return _stripTrailingSlash(_mobileApiBaseUrlOverride);
    }
    final base = _stripTrailingSlash(apiBaseUrl);
    final marker = base.indexOf('/api/');
    if (marker >= 0) return '${base.substring(0, marker)}/api/mobile';
    return 'https://avatracker.online/api/mobile';
  }

  /// База core-API без версии: `…/api` (QR-скан и точки отметки).
  /// `POST /api/qr/scan/`, `GET /api/qr/points/{id}/`.
  static String get coreApiBaseUrl {
    final base = _stripTrailingSlash(apiBaseUrl);
    final marker = base.indexOf('/api/');
    if (marker >= 0) return '${base.substring(0, marker)}/api';
    return 'https://avatracker.online/api';
  }

  /// Код страны для поля `dial_code`. Пока Казахстан (`+7`);
  /// позже добавим Узбекистан (`+998`) — выбор по введённому номеру.
  static const defaultDialCode = '+7';

  static String _stripTrailingSlash(String value) {
    final trimmed = value.trim();
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  /// Версия сборки, видимая на экране входа.
  static const appVersion = 'v1.0.0';

  // ─── Юридическое / App Store ───────────────────────────────────────────────
  /// Версия Политики конфиденциальности (фиксируется в записи согласия).
  static const privacyPolicyVersion = '1.0';

  /// Компания-оператор данных и контакты ответственного лица.
  static const companyName = 'ТОО "AVA TECH.IO"';
  static const supportEmail = 'info@avtch.io';

  /// Публичный URL Политики (нужен для метаданных App Store Connect / Google Play).
  static const privacyPolicyUrl = 'https://avatracker.online/privacy-policy/';

  /// Mock-режим: все запросы к API обслуживаются локальными заглушками.
  static const mockApi = bool.fromEnvironment('MOCK_API', defaultValue: false);

  /// Панель разработчика (плавающая шестерёнка → лог сети и приложения).
  /// Включена автоматически в debug-режиме и в release-сборках, собранных
  /// с `--dart-define=DEV_TOOLS=true` (отдельная "dev"-сборка для тестов,
  /// не путать с обычным альфа-APK для сотрудников).
  static const _devToolsFlag = bool.fromEnvironment('DEV_TOOLS');
  static const devToolsEnabled = _devToolsFlag || kDebugMode;

  /// Локальный тест без готовой auth-апишки: приложение на splash сохранит
  /// этот ИИН и Bearer-токен как текущую сессию и пойдет в реальные эндпоинты.
  static const testIin = String.fromEnvironment('TEST_IIN');
  static const testPhone = String.fromEnvironment(
    'TEST_PHONE',
    defaultValue: '+77000000000',
  );
  static const _rawTestBearerToken =
      String.fromEnvironment('TEST_BEARER_TOKEN');
  static const _rawTestRefreshToken =
      String.fromEnvironment('TEST_REFRESH_TOKEN');
  static const _rawTestToday = String.fromEnvironment('TEST_TODAY');

  static bool get testAuthEnabled =>
      !mockApi && testIin.isNotEmpty && testBearerToken.isNotEmpty;

  static String get testBearerToken => _stripBearer(_rawTestBearerToken);

  static String get testRefreshToken {
    final refresh = _stripBearer(_rawTestRefreshToken);
    return refresh.isEmpty ? testBearerToken : refresh;
  }

  static DateTime get today {
    final parsed = DateTime.tryParse(_rawTestToday);
    final value = parsed ?? DateTime.now();
    return DateTime(value.year, value.month, value.day);
  }

  static String _stripBearer(String value) {
    final trimmed = value.trim();
    if (trimmed.toLowerCase().startsWith('bearer ')) {
      return trimmed.substring(7).trim();
    }
    return trimmed;
  }

  // Требования ТЗ, раздел 4.3 и 22.
  static const smsResendSeconds = 60;

  /// Длина кода в SMS (сегментированный ввод).
  static const smsCodeLength = 4;
  static const smsCodeMinLength = 4;
  static const smsCodeMaxLength = 6;
  static const smsMaxAttempts = 5;
  static const faceIdMaxAttempts = 3;
  static const passwordMinLength = 6;

  // Геолокация (ТЗ, разделы 7.3 и 17).
  static const maxGpsAccuracyMeters = 50.0;
  static const locationTimeout = Duration(seconds: 15);

  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 25);
}
