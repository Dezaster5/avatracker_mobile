import '../../../../core/error/failure.dart';

/// Подтверждение SMS-кодом (ТЗ 4, 22): код из 4 цифр, повторная отправка
/// через 60 секунд, не более 5 попыток ввода.
abstract final class SmsCodePolicy {
  static const codeLength = 4;
  static const resendSeconds = 60;
  static const maxAttempts = 5;

  /// Попытку тратит только отказ сервера по самому коду (400: неверный или
  /// истёкший код). Нет сети, таймаут, 429 и 5xx — не ошибка ввода: тот же
  /// код можно отправить ещё раз.
  static bool consumesAttempt(Failure failure) => failure is ValidationFailure;
}
