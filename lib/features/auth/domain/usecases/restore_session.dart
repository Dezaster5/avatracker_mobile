import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/session_restoration.dart';
import '../repositories/auth_repository.dart';

/// Проверка сохранённой сессии при запуске (ТЗ 5.1, 19.1).
///
/// Сервер отозвал доступ (401, 404, сотрудник неактивен) — сессия очищается.
/// Прочие ошибки (сеть, 5xx) сессию не трогают: проверку можно повторить.
final class RestoreSession {
  const RestoreSession(this._repository);

  final AuthRepository _repository;

  Future<SessionRestoration> call() async {
    switch (await _repository.hasStoredSession()) {
      case Failed(:final failure):
        return SessionRestoreFailed(failure);
      case Success(value: false):
        return const NoStoredSession();
      case Success():
        break;
    }

    switch (await _repository.fetchCurrentEmployee()) {
      case Success(:final value) when value.active:
        return SessionRestored(value);
      case Success():
        return _revoke(LogoutReason.employeeInactive);
      case Failed(failure: UnauthorizedFailure()):
        return _revoke(LogoutReason.sessionExpired);
      case Failed(failure: NotFoundFailure()):
        return _revoke(LogoutReason.employeeNotFound);
      case Failed(:final failure):
        return SessionRestoreFailed(failure);
    }
  }

  Future<SessionRestoration> _revoke(LogoutReason reason) async {
    await _repository.clearSession();
    return SessionRevoked(reason);
  }
}
