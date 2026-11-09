import '../repositories/auth_repository.dart';

/// Выход: локальная сессия очищается, настройки устройства остаются.
final class SignOut {
  const SignOut(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.clearSession();
}
