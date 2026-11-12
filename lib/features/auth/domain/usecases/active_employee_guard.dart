import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/employee.dart';
import '../repositories/auth_repository.dart';

/// Неактивный сотрудник не получает доступ: сессия сразу очищается, а
/// вызывающий получает [EmployeeInactiveFailure].
final class ActiveEmployeeGuard {
  const ActiveEmployeeGuard(this._repository);

  final AuthRepository _repository;

  Future<Result<Employee>> call(Result<Employee> result) async {
    if (result case Success(:final value) when !value.active) {
      await _repository.clearSession();
      return Failed(const EmployeeInactiveFailure());
    }
    return result;
  }
}
