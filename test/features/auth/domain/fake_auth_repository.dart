import 'package:avatracker_mobile/core/country/phone_number.dart';
import 'package:avatracker_mobile/core/error/result.dart';
import 'package:avatracker_mobile/features/auth/domain/entities/employee.dart';
import 'package:avatracker_mobile/features/auth/domain/repositories/auth_repository.dart';

const activeEmployee =
    Employee(iin: '990101300123', fullName: 'Тестовый Сотрудник', active: true);
const inactiveEmployee = Employee(
    iin: '990101300123', fullName: 'Тестовый Сотрудник', active: false);

/// Репозиторий с заданными ответами; запоминает побочные эффекты.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.storedSession = const Success(true),
    this.currentEmployee = const Success(activeEmployee),
    this.loginResult = const Success(activeEmployee),
    this.registrationResult = const Success(null),
    this.consentResult = const Success(null),
    this.deleteResult = const Success(null),
    this.verifyRegistrationResult = const Success(activeEmployee),
    this.passwordResetRequestResult = const Success(null),
    this.resetCodeResult = const Success('reset-token'),
    this.changePasswordResult = const Success(null),
  });

  Result<bool> storedSession;
  Result<Employee> currentEmployee;
  Result<Employee> loginResult;
  Result<void> registrationResult;
  Result<void> consentResult;
  Result<void> deleteResult;
  Result<Employee> verifyRegistrationResult;
  Result<void> passwordResetRequestResult;
  Result<String> resetCodeResult;
  Result<void> changePasswordResult;

  int clearSessionCalls = 0;
  int verifyRegistrationCalls = 0;
  int verifyResetCodeCalls = 0;
  final consents = <({String iin, String policyVersion})>[];

  @override
  Future<Result<bool>> hasStoredSession() async => storedSession;

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async =>
      changePasswordResult;

  @override
  Future<Result<Employee>> fetchCurrentEmployee() async => currentEmployee;

  @override
  Future<Result<Employee>> login({
    required PhoneNumber phone,
    required String password,
  }) async =>
      loginResult;

  @override
  Future<Result<void>> requestRegistrationCode({
    required PhoneNumber phone,
    required String iin,
    required String password,
  }) async =>
      registrationResult;

  @override
  Future<Result<Employee>> verifyRegistration({
    required PhoneNumber phone,
    required String code,
    required String password,
  }) async {
    verifyRegistrationCalls++;
    return verifyRegistrationResult;
  }

  @override
  Future<Result<void>> requestPasswordReset(PhoneNumber phone) async =>
      passwordResetRequestResult;

  @override
  Future<Result<String>> verifyPasswordResetCode({
    required PhoneNumber phone,
    required String code,
  }) async {
    verifyResetCodeCalls++;
    return resetCodeResult;
  }

  @override
  Future<Result<void>> saveConsent({
    required String iin,
    required String policyVersion,
  }) async {
    consents.add((iin: iin, policyVersion: policyVersion));
    return consentResult;
  }

  @override
  Future<Result<void>> deleteAccount() async => deleteResult;

  @override
  Future<void> clearSession() async => clearSessionCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
