/// Правило для пароля. Каждое правило само проверяет пароль, поэтому валидатор
/// формы и подсказки под полем строятся из одного списка [PasswordPolicy.rules]
/// и не расходятся. Класс закрытый (`sealed`): подпись нового правила
/// на экране не забудется — без неё код не скомпилируется.
sealed class PasswordRule {
  const PasswordRule();

  /// Пароль удовлетворяет правилу.
  bool isSatisfiedBy(String password);
}

/// Пароль не короче [length] символов.
final class MinLengthRule extends PasswordRule {
  const MinLengthRule(this.length);

  final int length;

  @override
  bool isSatisfiedBy(String password) => password.length >= length;
}

/// В пароле нет пробелов.
final class NoSpacesRule extends PasswordRule {
  const NoSpacesRule();

  @override
  bool isSatisfiedBy(String password) => !password.contains(' ');
}

/// Требования к паролю (API_CONTRACT: от 6 символов, без пробелов).
abstract final class PasswordPolicy {
  static const minLength = 6;

  static const List<PasswordRule> rules = [
    MinLengthRule(minLength),
    NoSpacesRule(),
  ];

  static bool isValid(String password) =>
      rules.every((rule) => rule.isSatisfiedBy(password));
}
