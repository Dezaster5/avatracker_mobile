import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/country/phone_number.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../di/auth_providers.dart';
import '../../domain/policies/sms_code_policy.dart';
import 'auth_controller.dart';
import 'sms_flow_state.dart';

/// Регистрация: телефон + ИИН + пароль → SMS-код → аккаунт создан (ТЗ 3, 4).
class RegistrationState extends SmsFlowState {
  const RegistrationState({
    super.phone,
    this.iin = '',
    this.password = '',
    super.sending,
    super.verifying,
    super.failure,
    super.codeSentAt,
    super.attemptsLeft,
  });

  final String iin;
  final String password;

  RegistrationState copyWith({
    PhoneNumber? phone,
    String? iin,
    String? password,
    bool? sending,
    bool? verifying,
    Object? failure = unset,
    DateTime? codeSentAt,
    int? attemptsLeft,
  }) {
    return RegistrationState(
      phone: phone ?? this.phone,
      iin: iin ?? this.iin,
      password: password ?? this.password,
      sending: sending ?? this.sending,
      verifying: verifying ?? this.verifying,
      failure: identical(failure, unset) ? this.failure : failure as Failure?,
      codeSentAt: codeSentAt ?? this.codeSentAt,
      attemptsLeft: attemptsLeft ?? this.attemptsLeft,
    );
  }
}

class RegistrationController extends Notifier<RegistrationState> {
  @override
  RegistrationState build() => const RegistrationState();

  Future<bool> sendCode({
    required PhoneNumber phone,
    required String iin,
    required String password,
  }) async {
    state = state.copyWith(
      phone: phone,
      iin: iin,
      password: password,
      sending: true,
      failure: null,
    );
    final result = await ref
        .read(requestRegistrationCodeProvider)
        .call(phone: phone, iin: iin, password: password);
    return _onCodeSent(result);
  }

  Future<bool> resend() async {
    final phone = state.phone;
    if (phone == null) return false;
    state = state.copyWith(sending: true, failure: null);
    return _onCodeSent(
      await ref.read(resendRegistrationCodeProvider).call(phone),
    );
  }

  void clearError() => state = state.copyWith(failure: null);

  Future<bool> verify(String code) async {
    final phone = state.phone;
    // Повторный ввод, пока сервер проверяет первый, не отправляем.
    if (phone == null || state.verifying) return false;
    if (state.attemptsExhausted) {
      state = state.copyWith(failure: const SmsAttemptsExceededFailure());
      return false;
    }
    state = state.copyWith(verifying: true, failure: null);
    final result = await ref
        .read(confirmRegistrationProvider)
        .call(phone: phone, code: code, password: state.password);
    switch (result) {
      case Success(:final value):
        // Роутер сам откроет сканер — статус сессии изменится.
        ref.read(authControllerProvider.notifier).signedIn(value);
        state = state.copyWith(verifying: false);
        return true;
      case Failed(:final failure):
        final rejected = state.afterFailedVerification(failure);
        state = state.copyWith(
          verifying: false,
          attemptsLeft: rejected.attemptsLeft,
          failure: rejected.failure,
        );
        return false;
    }
  }

  bool _onCodeSent(Result<void> result) {
    switch (result) {
      case Success():
        state = state.copyWith(
          sending: false,
          codeSentAt: DateTime.now(),
          attemptsLeft: SmsCodePolicy.maxAttempts,
        );
        return true;
      case Failed(:final failure):
        state = state.copyWith(sending: false, failure: failure);
        return false;
    }
  }
}

final registrationControllerProvider =
    NotifierProvider<RegistrationController, RegistrationState>(
  RegistrationController.new,
);
