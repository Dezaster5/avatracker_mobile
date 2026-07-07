import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Короткий доступ к строкам: `context.l10n.login`.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String localizedMessage(Object? value) =>
      l10n.localizeKnownMessage(value?.toString() ?? '');
}

extension AppLocalizationsFormatX on AppLocalizations {
  String formatDuration(int value) {
    final minutes = value.abs();
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours == 0) return durationMinutes(remainder);
    if (remainder == 0) return durationHours(hours);
    return durationHoursMinutes(hours, remainder);
  }

  /// Переводит только fallback-сообщения, созданные самим клиентом.
  /// Произвольный текст backend возвращается без изменений.
  String localizeKnownMessage(String message) {
    return switch (message) {
      'Ошибка соединения. Попробуйте позже' => errorConnection,
      'Сессия истекла. Войдите заново' => errorSessionExpired,
      'Нет соединения с сервером' => noServerConnection,
      'Доступ запрещен. Сотрудник неактивен' ||
      'Доступ запрещён. Сотрудник неактивен' =>
        errorEmployeeInactive,
      'Сотрудник не найден в системе' => errorEmployeeNotFound,
      'Нет данных сотрудника' ||
      'Сервер не вернул данные сотрудника' =>
        errorEmployeeDataMissing,
      'Неверный формат ответа сервера' => errorInvalidServerResponse,
      'Табель пока недоступен' => errorTimesheetUnavailable,
      'QR-код не зарегистрирован в системе' => qrNotRegistered,
      'Сервер не вернул токен сброса' => errorResetTokenMissing,
      'Не удалось войти' => errorLoginFailed,
      'Превышено количество попыток. Запросите новый код' =>
        errorAttemptsExceeded,
      'Сначала подтвердите SMS-код' => errorConfirmSmsFirst,
      'Нет доступа к камере' => cameraNoAccess,
      'Не удалось запустить камеру' => cameraStartFailed,
      'Не удалось сделать снимок. Попробуйте еще раз' ||
      'Не удалось сделать снимок. Попробуйте ещё раз' =>
        photoCaptureFailed,
      'Отметка успешно засчитана' => markAccepted,
      'Отметка не засчитана' => markNotAccepted,
      'Аккаунт удалён. Зарегистрируйтесь заново' => accountDeleted,
      _ => message,
    };
  }
}
