/// Конфигурация приложения.
///
/// Базовый URL и mock-режим задаются при сборке:
/// ```
/// flutter run --dart-define=API_BASE_URL=https://avatracker.online/api/v1
/// flutter run --dart-define=MOCK_API=true   # демо без бэкенда
/// ```
abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://avatracker.online/api/v1',
  );

  /// Mock-режим: все запросы к API обслуживаются локальными заглушками.
  static const mockApi = bool.fromEnvironment('MOCK_API', defaultValue: false);

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
