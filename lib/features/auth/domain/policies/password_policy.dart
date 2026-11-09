/// Требования к паролю: от 6 символов, без пробелов.
abstract final class PasswordPolicy {
  static const minLength = 6;

  static bool isValid(String password) =>
      password.length >= minLength && !password.contains(' ');
}
