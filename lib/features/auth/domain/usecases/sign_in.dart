import '../../../../core/country/phone_number.dart';
import '../../../../core/error/result.dart';
import '../entities/employee.dart';
import '../repositories/auth_repository.dart';
import 'active_employee_guard.dart';

/// Вход по телефону и паролю.
final class SignIn {
  const SignIn(this._repository, this._guard);

  final AuthRepository _repository;
  final ActiveEmployeeGuard _guard;

  Future<Result<Employee>> call({
    required PhoneNumber phone,
    required String password,
  }) async =>
      _guard(await _repository.login(phone: phone, password: password));
}
