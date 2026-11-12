import '../../../../core/country/phone_number.dart';
import '../../../../core/error/result.dart';
import '../entities/employee.dart';
import '../repositories/auth_repository.dart';
import 'active_employee_guard.dart';

/// Регистрация, шаг 2: SMS-код → аккаунт создан, сессия открыта.
final class ConfirmRegistration {
  const ConfirmRegistration(this._repository, this._guard);

  final AuthRepository _repository;
  final ActiveEmployeeGuard _guard;

  Future<Result<Employee>> call({
    required PhoneNumber phone,
    required String code,
    required String password,
  }) async =>
      _guard(
        await _repository.verifyRegistration(
          phone: phone,
          code: code,
          password: password,
        ),
      );
}
