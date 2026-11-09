import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/country/phone_number.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../di/auth_providers.dart';
import '../../domain/policies/sms_code_policy.dart';
import 'sms_flow_state.dart';

/// Сброс пароля: телефон → SMS-код → новый пароль.
class PasswordResetState extends SmsFlowState {
  const PasswordResetState({
    super.phone,
    super.sending,
    super.verifying,
    super.failure,
    super.codeSentAt,
    super.attemptsLeft,
    this.resetToken,
    this.saving = false,
  });

  /// Токен, выданный после проверки кода, — нужен для финального шага.
  final String? resetToken;
  final bool saving;

  PasswordResetState copyWith({
    bool? sending,
    bool? verifying,
    Object? failure = unset,
    DateTime? codeSentAt,
    int? attemptsLeft,
    Object? resetToken = unset,
    bool? saving,
  }) {
    return PasswordResetState(
      phone: phone,
      sending: sending ?? this.sending,
      verifying: verifying ?? this.verifying,
      failure: identical(failure, unset) ? this.failure : failure as Failure?,
      codeSentAt: codeSentAt ?? this.codeSentAt,
      attemptsLeft: attemptsLeft ?? this.attemptsLeft,
      resetToken: identical(resetToken, unset)
          ? this.resetToken
          : resetToken as String?,
      saving: saving ?? this.saving,
    );
  }
}

class PasswordResetController extends Notifier<PasswordResetState> {
  @override
  PasswordResetState build() => const PasswordResetState();

  Future<bool> sendCode(PhoneNumber phone) async {
    state = PasswordResetState(phone: phone, sending: true);
    final result = await ref.read(requestPasswordResetProvider).call(phone);
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

  Future<bool> resend() async {
    final phone = state.phone;
    return phone == null ? false : sendCode(phone);
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
        .read(verifyPasswordResetCodeProvider)
        .call(phone: phone, code: code);
    switch (result) {
      case Success(:final value):
        state = state.copyWith(verifying: false, resetToken: value);
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

  /// Финальный шаг: новый пароль по выданному `reset_token`.
  Future<bool> setNewPassword(String newPassword) async {
    final token = state.resetToken;
    if (token == null) {
      state = state.copyWith(failure: const SmsCodeNotVerifiedFailure());
      return false;
    }
    state = state.copyWith(saving: true, failure: null);
    final result = await ref
        .read(resetPasswordProvider)
        .call(resetToken: token, newPassword: newPassword);
    switch (result) {
      case Success():
        state = const PasswordResetState();
        return true;
      case Failed(:final failure):
        state = state.copyWith(saving: false, failure: failure);
        return false;
    }
  }
}

final passwordResetControllerProvider =
    NotifierProvider<PasswordResetController, PasswordResetState>(
  PasswordResetController.new,
);
