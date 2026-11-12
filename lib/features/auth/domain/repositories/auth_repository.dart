import '../../../../core/country/phone_number.dart';
import '../../../../core/error/result.dart';
import '../entities/employee.dart';

/// Учётная запись сотрудника в мобильном API и локальная сессия.
abstract interface class AuthRepository {
  /// Есть ли сохранённая сессия: токен и идентификатор сотрудника.
  Future<Result<bool>> hasStoredSession();

  /// Профиль сотрудника текущей сессии.
  Future<Result<Employee>> fetchCurrentEmployee();

  /// Вход по телефону и паролю; при успехе сессия сохранена.
  Future<Result<Employee>> login({
    required PhoneNumber phone,
    required String password,
  });

  /// Регистрация, шаг 1: заводит заявку и отправляет SMS-код.
  Future<Result<void>> requestRegistrationCode({
    required PhoneNumber phone,
    required String iin,
    required String password,
  });

  Future<Result<void>> resendRegistrationCode(PhoneNumber phone);

  /// Регистрация, шаг 2: подтверждение кодом; при успехе сессия сохранена.
  Future<Result<Employee>> verifyRegistration({
    required PhoneNumber phone,
    required String code,
    required String password,
  });

  Future<Result<void>> requestPasswordReset(PhoneNumber phone);

  /// Проверка SMS-кода сброса; возвращает `reset_token` для финального шага.
  Future<Result<String>> verifyPasswordResetCode({
    required PhoneNumber phone,
    required String code,
  });

  Future<Result<void>> confirmPasswordReset({
    required String resetToken,
    required String newPassword,
  });

  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Удаляет мобильный аккаунт на сервере.
  Future<Result<void>> deleteAccount();

  /// Факт согласия на обработку персональных данных (App Store §5.1.1).
  Future<Result<void>> saveConsent({
    required String iin,
    required String policyVersion,
  });

  Future<void> clearSession();

  /// Пользовательский выход; постоянный ключ сначала отзывается на сервере.
  Future<Result<void>> logout();
}
