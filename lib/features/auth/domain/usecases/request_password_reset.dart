import '../../../../core/country/phone_number.dart';
import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

/// Сброс пароля, шаг 1: SMS-код на номер.
final class RequestPasswordReset {
  const RequestPasswordReset(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call(PhoneNumber phone) =>
      _repository.requestPasswordReset(phone);
}
