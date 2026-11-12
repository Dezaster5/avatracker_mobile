import 'package:flutter/foundation.dart' show immutable;

import '../../../../core/country/phone_number.dart';
import '../../../../core/error/failure.dart';
import '../../domain/policies/sms_code_policy.dart';

/// Общее состояние шага «отправили SMS и ждём код» — регистрации и сброса
/// пароля. Экран SMS-кода работает с любым из них.
@immutable
abstract class SmsFlowState {
  const SmsFlowState({
    this.phone,
    this.sending = false,
    this.verifying = false,
    this.failure,
    this.codeSentAt,
    this.attemptsLeft = SmsCodePolicy.maxAttempts,
  });

  final PhoneNumber? phone;
  final bool sending;
  final bool verifying;
  final Failure? failure;
  final DateTime? codeSentAt;
  final int attemptsLeft;

  /// Попытки исчерпаны — нужен новый код.
  bool get attemptsExhausted => attemptsLeft <= 0;

  /// Остаток попыток и ошибка для показа после неудачной проверки кода.
  /// Последняя попытка, потраченная на неверный код, превращается в
  /// [SmsAttemptsExceededFailure].
  ({int attemptsLeft, Failure failure}) afterFailedVerification(
    Failure failure,
  ) {
    final left = SmsCodePolicy.consumesAttempt(failure)
        ? attemptsLeft - 1
        : attemptsLeft;
    return (
      attemptsLeft: left,
      failure: left <= 0 ? const SmsAttemptsExceededFailure() : failure,
    );
  }
}

/// Маркер «поле не передано» для `copyWith` nullable-полей.
const unset = Object();
