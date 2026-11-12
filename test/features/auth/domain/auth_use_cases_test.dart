import 'package:avatracker_mobile/core/country/country.dart';
import 'package:avatracker_mobile/core/country/phone_number.dart';
import 'package:avatracker_mobile/core/error/failure.dart';
import 'package:avatracker_mobile/core/error/result.dart';
import 'package:avatracker_mobile/features/auth/domain/entities/employee.dart';
import 'package:avatracker_mobile/features/auth/domain/entities/session_restoration.dart';
import 'package:avatracker_mobile/features/auth/domain/usecases/active_employee_guard.dart';
import 'package:avatracker_mobile/features/auth/domain/usecases/delete_account.dart';
import 'package:avatracker_mobile/features/auth/domain/usecases/request_registration_code.dart';
import 'package:avatracker_mobile/features/auth/domain/usecases/restore_session.dart';
import 'package:avatracker_mobile/features/auth/domain/usecases/sign_in.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_repository.dart';

void main() {
  final phone = PhoneNumber.parse('7001234567', Country.kazakhstan);

  group('RestoreSession', () {
    test('нет сохранённой сессии — нужен вход', () async {
      final repository =
          FakeAuthRepository(storedSession: const Success(false));
      expect(await RestoreSession(repository).call(), isA<NoStoredSession>());
    });

    test('активный сотрудник — сессия восстановлена', () async {
      final restoration = await RestoreSession(FakeAuthRepository()).call();
      expect((restoration as SessionRestored).employee, activeEmployee);
    });

    test('сервер отозвал доступ — сессия очищается', () async {
      final cases = <Result<Employee>, LogoutReason>{
        const Failed(UnauthorizedFailure()): LogoutReason.sessionExpired,
        const Failed(NotFoundFailure()): LogoutReason.employeeNotFound,
        const Success(inactiveEmployee): LogoutReason.employeeInactive,
      };
      for (final MapEntry(key: response, value: reason) in cases.entries) {
        final repository = FakeAuthRepository(currentEmployee: response);
        final restoration = await RestoreSession(repository).call();
        expect((restoration as SessionRevoked).reason, reason);
        expect(repository.clearSessionCalls, 1);
      }
    });

    test('нет сети или 5xx — сессия сохраняется, можно повторить', () async {
      for (final failure in const [NetworkFailure(), ServerFailure()]) {
        final repository = FakeAuthRepository(currentEmployee: Failed(failure));
        final restoration = await RestoreSession(repository).call();
        expect((restoration as SessionRestoreFailed).failure, failure);
        expect(repository.clearSessionCalls, 0);
      }
    });
  });

  group('ActiveEmployeeGuard', () {
    test('неактивный сотрудник не входит, сессия очищается', () async {
      final repository =
          FakeAuthRepository(loginResult: const Success(inactiveEmployee));
      final signIn = SignIn(repository, ActiveEmployeeGuard(repository));

      final result = await signIn(phone: phone, password: '123456');

      expect((result as Failed).failure, isA<EmployeeInactiveFailure>());
      expect(repository.clearSessionCalls, 1);
    });

    test('ошибка входа передаётся как есть', () async {
      const failure = UnauthorizedFailure(serverMessage: 'Неверный пароль');
      final repository = FakeAuthRepository(loginResult: const Failed(failure));
      final signIn = SignIn(repository, ActiveEmployeeGuard(repository));

      final result = await signIn(phone: phone, password: 'x');

      expect((result as Failed).failure, failure);
      expect(repository.clearSessionCalls, 0);
    });
  });

  group('RequestRegistrationCode', () {
    test('после отправки кода фиксируется согласие на обработку ПДн', () async {
      final repository = FakeAuthRepository();
      final request =
          RequestRegistrationCode(repository, privacyPolicyVersion: '2.0');

      final result =
          await request(phone: phone, iin: '642918307154', password: '123456');

      expect(result, isA<Success<void>>());
      expect(repository.consents.single.iin, '642918307154');
      expect(repository.consents.single.policyVersion, '2.0');
    });

    test('без отправленного кода согласие не сохраняется', () async {
      final repository = FakeAuthRepository(
        registrationResult: const Failed(ValidationFailure()),
      );
      final request =
          RequestRegistrationCode(repository, privacyPolicyVersion: '2.0');

      final result =
          await request(phone: phone, iin: '642918307154', password: '123456');

      expect((result as Failed).failure, isA<ValidationFailure>());
      expect(repository.consents, isEmpty);
    });
  });

  group('DeleteAccount', () {
    test('удалённый аккаунт не оставляет локальной сессии', () async {
      final repository = FakeAuthRepository();
      expect(await DeleteAccount(repository).call(), isA<Success<void>>());
      expect(repository.clearSessionCalls, 1);
    });

    test('ошибка удаления сессию не трогает', () async {
      final repository =
          FakeAuthRepository(deleteResult: const Failed(NetworkFailure()));
      expect(await DeleteAccount(repository).call(), isA<Failed<void>>());
      expect(repository.clearSessionCalls, 0);
    });
  });
}
