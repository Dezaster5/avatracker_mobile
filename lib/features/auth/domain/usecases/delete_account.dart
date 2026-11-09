import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

/// Удаление мобильного аккаунта (App Store §5.1.1(v)). Данные сотрудника в
/// основной системе сохраняются; для входа нужна повторная регистрация,
/// поэтому локальная сессия сразу очищается.
final class DeleteAccount {
  const DeleteAccount(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() async {
    final result = await _repository.deleteAccount();
    if (result is Success<void>) await _repository.clearSession();
    return result;
  }
}
