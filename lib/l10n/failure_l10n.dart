import '../core/error/failure.dart';
import 'app_localizations.dart';

extension FailureL10n on AppLocalizations {
  /// Текст ошибки для пользователя. Сообщение сервера показывается как есть,
  /// остальные ошибки переводятся на текущий язык интерфейса.
  String failureMessage(Failure failure) {
    if (failure case ServerResponseFailure(:final serverMessage?)) {
      return serverMessage;
    }
    return switch (failure) {
      NetworkFailure() || TimeoutFailure() => errorConnection,
      // Сбой клиента или ответ вне контракта — не «нет связи».
      UnknownFailure() => errorUnexpected,
      InvalidResponseFailure() => errorInvalidServerResponse,
      // Сервер ответил, но без текста: связь есть, сообщаем суть отказа.
      UnauthorizedFailure() => errorSessionExpired,
      ForbiddenFailure() => errorForbidden,
      NotFoundFailure() => errorNotFound,
      ValidationFailure() => errorValidation,
      ServerFailure() => errorServer,
      EmployeeInactiveFailure() => errorEmployeeInactive,
      EmployeeNotFoundFailure() => errorEmployeeNotFound,
      EmployeeDataMissingFailure() => errorEmployeeDataMissing,
      LoginFailedFailure() => errorLoginFailed,
      ResetTokenMissingFailure() => errorResetTokenMissing,
      SmsAttemptsExceededFailure() => errorAttemptsExceeded,
      SmsCodeNotVerifiedFailure() => errorConfirmSmsFirst,
      QrNotRegisteredFailure(:final qrId) =>
        '$qrNotRegistered\n${qrCodeValue(qrId)}',
      QrPointDisabledFailure() => pointDisabled,
      LocationFailure(:final code, :final accuracyMeters) => switch (code) {
          LocationFailureCode.serviceDisabled => locationEnableGps,
          LocationFailureCode.permissionDenied => locationPermissionRequired,
          LocationFailureCode.unavailable => locationUnavailable,
          LocationFailureCode.mocked => locationMocked,
          LocationFailureCode.lowAccuracy =>
            locationLowAccuracy(accuracyMeters ?? 0),
        },
    };
  }

  /// Текст для ошибки из `AsyncValue.error`: [Failure] переводится, прочее —
  /// непредвиденная ошибка (исключение вне data-слоя, то есть баг клиента).
  String errorMessage(Object error) =>
      error is Failure ? failureMessage(error) : errorUnexpected;
}
