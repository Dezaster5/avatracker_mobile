import 'package:avatracker_mobile/core/country/country.dart';
import 'package:avatracker_mobile/core/country/phone_number.dart';
import 'package:avatracker_mobile/core/error/failure.dart';
import 'package:avatracker_mobile/core/error/result.dart';
import 'package:avatracker_mobile/features/auth/di/auth_providers.dart';
import 'package:avatracker_mobile/features/auth/domain/policies/sms_code_policy.dart';
import 'package:avatracker_mobile/features/auth/presentation/controllers/password_reset_controller.dart';
import 'package:avatracker_mobile/features/auth/presentation/controllers/registration_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/fake_auth_repository.dart';

final _phone = PhoneNumber.parse('7001234567', Country.kazakhstan);
const _wrongCode = ValidationFailure(serverMessage: 'Неверный SMS-код');

ProviderContainer _container(FakeAuthRepository repository) {
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

/// Регистрация на шаге ввода SMS-кода.
Future<RegistrationController> _registrationAwaitingCode(
  ProviderContainer container,
) async {
  final controller = container.read(registrationControllerProvider.notifier);
  await controller.sendCode(
    phone: _phone,
    iin: '990101300123',
    password: 'secret1',
  );
  return controller;
}

void main() {
  group('Регистрация: попытки SMS-кода', () {
    test('нет сети или сбой сервера — попытка не списывается', () async {
      final repository = FakeAuthRepository();
      final container = _container(repository);
      final controller = await _registrationAwaitingCode(container);

      repository.verifyRegistrationResult = const Failed(NetworkFailure());
      expect(await controller.verify('1234'), isFalse);
      repository.verifyRegistrationResult = const Failed(ServerFailure());
      expect(await controller.verify('1234'), isFalse);

      final state = container.read(registrationControllerProvider);
      expect(state.attemptsLeft, SmsCodePolicy.maxAttempts);
      expect(state.failure, isA<ServerFailure>());
    });

    test('неверный код списывает попытку, последний — блокирует ввод',
        () async {
      final repository = FakeAuthRepository(
          verifyRegistrationResult: const Failed(_wrongCode));
      final container = _container(repository);
      final controller = await _registrationAwaitingCode(container);

      await controller.verify('1111');
      var state = container.read(registrationControllerProvider);
      expect(state.attemptsLeft, SmsCodePolicy.maxAttempts - 1);
      expect(state.failure, same(_wrongCode));

      for (var i = 1; i < SmsCodePolicy.maxAttempts; i++) {
        await controller.verify('1111');
      }
      state = container.read(registrationControllerProvider);
      expect(state.attemptsExhausted, isTrue);
      expect(state.failure, isA<SmsAttemptsExceededFailure>());
    });

    test('пока идёт проверка, повторный ввод кода не отправляется', () async {
      final repository = FakeAuthRepository();
      final container = _container(repository);
      final controller = await _registrationAwaitingCode(container);

      final first = controller.verify('1234');
      expect(await controller.verify('1234'), isFalse);
      expect(await first, isTrue);
      expect(repository.verifyRegistrationCalls, 1);
    });
  });

  test('сброс пароля: обрыв связи не тратит попытку, неверный код — тратит',
      () async {
    final repository = FakeAuthRepository(
      resetCodeResult: const Failed(TimeoutFailure()),
    );
    final container = _container(repository);
    final controller = container.read(passwordResetControllerProvider.notifier);
    await controller.sendCode(_phone);

    await controller.verify('1234');
    expect(
      container.read(passwordResetControllerProvider).attemptsLeft,
      SmsCodePolicy.maxAttempts,
    );

    repository.resetCodeResult = const Failed(_wrongCode);
    await controller.verify('1111');
    expect(
      container.read(passwordResetControllerProvider).attemptsLeft,
      SmsCodePolicy.maxAttempts - 1,
    );
    expect(repository.verifyResetCodeCalls, 2);
  });
}
