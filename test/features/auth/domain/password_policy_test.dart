import 'package:avatracker_mobile/features/auth/domain/policies/password_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('пароль: от 6 символов без пробелов', () {
    expect(PasswordPolicy.isValid('123456'), isTrue);
    expect(PasswordPolicy.isValid('qwerty12'), isTrue);
    expect(PasswordPolicy.isValid('12345'), isFalse);
    expect(PasswordPolicy.isValid('пароль с пробелом'), isFalse);
  });
}
