import '../../../../core/country/phone_number.dart';
import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

/// Регистрация, шаг 1: телефон + ИИН + пароль → SMS-код (ТЗ 3, 4).
/// Пользователь уже дал согласие на обработку ПДн — фиксируем его.
final class RequestRegistrationCode {
  const RequestRegistrationCode(
    this._repository, {
    required String privacyPolicyVersion,
  }) : _privacyPolicyVersion = privacyPolicyVersion;

  final AuthRepository _repository;
  final String _privacyPolicyVersion;

  Future<Result<void>> call({
    required PhoneNumber phone,
    required String iin,
    required String password,
  }) async {
    final requested = await _repository.requestRegistrationCode(
      phone: phone,
      iin: iin,
      password: password,
    );
    if (requested is Failed<void>) return requested;
    return _repository.saveConsent(
      iin: iin,
      policyVersion: _privacyPolicyVersion,
    );
  }
}
