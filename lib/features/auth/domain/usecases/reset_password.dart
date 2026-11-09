import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

/// Сброс пароля, шаг 3: новый пароль по `reset_token`.
final class ResetPassword {
  const ResetPassword(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({
    required String resetToken,
    required String newPassword,
  }) =>
      _repository.confirmPasswordReset(
        resetToken: resetToken,
        newPassword: newPassword,
      );
}
