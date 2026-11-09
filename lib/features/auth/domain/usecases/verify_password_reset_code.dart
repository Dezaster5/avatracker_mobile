import '../../../../core/country/phone_number.dart';
import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

/// Сброс пароля, шаг 2: проверка кода; возвращает `reset_token`.
final class VerifyPasswordResetCode {
  const VerifyPasswordResetCode(this._repository);

  final AuthRepository _repository;

  Future<Result<String>> call({
    required PhoneNumber phone,
    required String code,
  }) =>
      _repository.verifyPasswordResetCode(phone: phone, code: code);
}
