import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

/// Смена пароля в профиле (по текущей сессии).
final class ChangePassword {
  const ChangePassword(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({
    required String currentPassword,
    required String newPassword,
  }) =>
      _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
}
