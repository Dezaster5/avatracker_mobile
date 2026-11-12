import '../../../../core/country/phone_number.dart';
import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

final class ResendRegistrationCode {
  const ResendRegistrationCode(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call(PhoneNumber phone) =>
      _repository.resendRegistrationCode(phone);
}
