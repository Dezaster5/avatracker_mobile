import 'package:avatracker_mobile/features/auth/domain/policies/password_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('пароль: от 6 символов без пробелов', () {
    expect(PasswordPolicy.isValid('123456'), isTrue);
    expect(PasswordPolicy.isValid('qwerty12'), isTrue);
    expect(PasswordPolicy.isValid('12345'), isFalse);
    expect(PasswordPolicy.isValid('пароль с пробелом'), isFalse);
  });

  test('каждое правило проверяет свою часть требований', () {
    const minLength = MinLengthRule(6);
    expect(minLength.isSatisfiedBy('12345'), isFalse);
    expect(minLength.isSatisfiedBy('123456'), isTrue);

    const noSpaces = NoSpacesRule();
    expect(noSpaces.isSatisfiedBy('секрет'), isTrue);
    expect(noSpaces.isSatisfiedBy('сек рет'), isFalse);
  });

  test('подсказки и валидатор строятся из одних правил политики', () {
    expect(PasswordPolicy.rules, [
      isA<MinLengthRule>()
          .having((rule) => rule.length, 'length', PasswordPolicy.minLength),
      isA<NoSpacesRule>(),
    ]);
  });
}
