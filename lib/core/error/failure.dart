/// Каталог ошибок приложения.
///
/// Data-слой переводит исключения (Dio, парсинг, платформа) в [Failure];
/// domain и presentation работают только с этими типами. Иерархия `sealed`,
/// поэтому switch по ней исчерпывающий: новая ошибка не останется без текста
/// в UI (см. `lib/l10n/failure_l10n.dart`).
sealed class Failure implements Exception {
  const Failure();
}

// ─── Транспорт ───────────────────────────────────────────────────────────────

/// Нет соединения с сервером: сеть недоступна, DNS, TLS.
final class NetworkFailure extends Failure {
  const NetworkFailure();
}

/// Сервер не ответил за отведённое время.
final class TimeoutFailure extends Failure {
  const TimeoutFailure();
}

/// Ответ сервера не соответствует контракту API.
final class InvalidResponseFailure extends Failure {
  const InvalidResponseFailure();
}

/// Непредвиденная ошибка; [cause] — исходное исключение для диагностики.
final class UnknownFailure extends Failure {
  const UnknownFailure([this.cause]);

  final Object? cause;
}

// ─── Ответы сервера с ошибкой ────────────────────────────────────────────────

/// Сервер ответил ошибкой. [serverMessage] — текст из тела ответа (DRF
/// `detail`/`message`/ошибка поля), его показываем пользователю как есть;
/// [code] — машинный `error_code`, например `OUT_OF_RADIUS`.
sealed class ServerResponseFailure extends Failure {
  const ServerResponseFailure({this.serverMessage, this.code});

  final String? serverMessage;
  final String? code;
}

/// 401: токен недействителен или неверные учётные данные.
final class UnauthorizedFailure extends ServerResponseFailure {
  const UnauthorizedFailure({super.serverMessage, super.code});
}

/// 403: доступ запрещён.
final class ForbiddenFailure extends ServerResponseFailure {
  const ForbiddenFailure({super.serverMessage, super.code});
}

/// 404: ресурс не найден.
final class NotFoundFailure extends ServerResponseFailure {
  const NotFoundFailure({super.serverMessage, super.code});
}

/// 400/409/422: сервер отклонил данные запроса.
final class ValidationFailure extends ServerResponseFailure {
  const ValidationFailure({super.serverMessage, super.code});
}

/// 5xx и прочие ответы с ошибкой.
final class ServerFailure extends ServerResponseFailure {
  const ServerFailure({super.serverMessage, super.code});
}

// ─── Сотрудник и вход ────────────────────────────────────────────────────────

/// Сотрудник отключён в AvaTracker — доступ запрещён.
final class EmployeeInactiveFailure extends Failure {
  const EmployeeInactiveFailure();
}

/// Сотрудника с таким идентификатором нет в системе.
final class EmployeeNotFoundFailure extends Failure {
  const EmployeeNotFoundFailure();
}

/// Сервер не вернул данные сотрудника, или в сессии нет сотрудника.
final class EmployeeDataMissingFailure extends Failure {
  const EmployeeDataMissingFailure();
}

/// Ответ на вход/подтверждение пришёл без токенов.
final class LoginFailedFailure extends Failure {
  const LoginFailedFailure();
}

/// Проверка SMS-кода сброса не вернула `reset_token`.
final class ResetTokenMissingFailure extends Failure {
  const ResetTokenMissingFailure();
}

/// Исчерпаны попытки ввода SMS-кода.
final class SmsAttemptsExceededFailure extends Failure {
  const SmsAttemptsExceededFailure();
}

/// Новый пароль задаётся только после подтверждения SMS-кода.
final class SmsCodeNotVerifiedFailure extends Failure {
  const SmsCodeNotVerifiedFailure();
}

// ─── Отметка ─────────────────────────────────────────────────────────────────

/// QR-кода нет в системе; [qrId] показываем, чтобы было видно расхождение.
final class QrNotRegisteredFailure extends Failure {
  const QrNotRegisteredFailure(this.qrId);

  final String qrId;
}

/// Точка отметки отключена.
final class QrPointDisabledFailure extends Failure {
  const QrPointDisabledFailure();
}

enum LocationFailureCode {
  serviceDisabled,
  permissionDenied,
  unavailable,
  mocked,
  lowAccuracy,
}

/// Какой экран системных настроек поможет исправить ошибку геолокации.
enum LocationSettingsAction { none, appSettings, locationSettings }

/// Геолокация недоступна или не прошла проверки ТЗ 17.
final class LocationFailure extends Failure {
  const LocationFailure(
    this.code, {
    this.settings = LocationSettingsAction.none,
    this.accuracyMeters,
  });

  final LocationFailureCode code;
  final LocationSettingsAction settings;
  final int? accuracyMeters;
}
