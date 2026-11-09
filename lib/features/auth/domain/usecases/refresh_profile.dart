import '../../../../core/error/result.dart';
import '../entities/employee.dart';
import '../repositories/auth_repository.dart';
import 'active_employee_guard.dart';

/// Обновление профиля текущего сотрудника (pull-to-refresh).
final class RefreshProfile {
  const RefreshProfile(this._repository, this._guard);

  final AuthRepository _repository;
  final ActiveEmployeeGuard _guard;

  Future<Result<Employee>> call() async =>
      _guard(await _repository.fetchCurrentEmployee());
}
