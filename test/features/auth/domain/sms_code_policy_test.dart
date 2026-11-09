import 'package:avatracker_mobile/core/error/failure.dart';
import 'package:avatracker_mobile/features/auth/domain/policies/sms_code_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('попытку тратит только отказ сервера по самому коду', () {
    expect(
      SmsCodePolicy.consumesAttempt(
        const ValidationFailure(serverMessage: 'Неверный SMS-код'),
      ),
      isTrue,
    );
    for (final failure in const <Failure>[
      NetworkFailure(),
      TimeoutFailure(),
      ServerFailure(serverMessage: 'Повторная отправка через 60 секунд'),
      UnknownFailure(),
    ]) {
      expect(
        SmsCodePolicy.consumesAttempt(failure),
        isFalse,
        reason: '${failure.runtimeType}',
      );
    }
  });
}
