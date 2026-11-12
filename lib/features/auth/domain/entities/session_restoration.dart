import '../../../../core/error/failure.dart';
import 'employee.dart';

/// Почему сессия завершилась без действия пользователя — экран входа
/// объясняет причину.
enum LogoutReason {
  sessionExpired,
  employeeInactive,
  employeeNotFound,
  accountDeleted,
}

/// Итог восстановления сессии при запуске приложения.
sealed class SessionRestoration {
  const SessionRestoration();
}

final class SessionRestored extends SessionRestoration {
  const SessionRestored(this.employee);

  final Employee employee;
}

/// Сохранённой сессии нет — нужен вход.
final class NoStoredSession extends SessionRestoration {
  const NoStoredSession();
}

/// Сервер отозвал доступ; локальная сессия уже очищена.
final class SessionRevoked extends SessionRestoration {
  const SessionRevoked(this.reason);

  final LogoutReason reason;
}

/// Проверить сессию не удалось (сеть, сервер) — сессия сохранена, можно
/// повторить.
final class SessionRestoreFailed extends SessionRestoration {
  const SessionRestoreFailed(this.failure);

  final Failure failure;
}
