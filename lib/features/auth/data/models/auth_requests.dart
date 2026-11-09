import '../../../../core/country/phone_number.dart';

/// Тела запросов мобильного auth-API.
///
/// Формат `phone` зависит от шага (проверено рабочими запросами):
/// login/register/resend/password-reset/request ждут национальный номер и
/// отдельный `dial_code`, а verify-шаги — полный номер без «+».

/// `POST /auth/login/`.
final class LoginRequest {
  const LoginRequest({required this.phone, required this.password});

  final PhoneNumber phone;
  final String password;

  Map<String, dynamic> toJson() => {
        ..._nationalPhone(phone),
        'password': password,
      };
}

/// `POST /auth/register/` — пароль задаётся уже здесь (бэкенд хранит его до
/// подтверждения кода).
final class RegisterRequest {
  const RegisterRequest({
    required this.phone,
    required this.iin,
    required this.password,
  });

  final PhoneNumber phone;
  final String iin;
  final String password;

  Map<String, dynamic> toJson() => {
        ..._nationalPhone(phone),
        'iin': iin,
        'password': password,
        'password2': password,
      };
}

/// `POST /auth/register/resend/` и `POST /password-reset/request/`.
final class PhoneRequest {
  const PhoneRequest(this.phone);

  final PhoneNumber phone;

  Map<String, dynamic> toJson() => _nationalPhone(phone);
}

/// `POST /auth/register/verify/` и `POST /password-reset/verify/`.
final class VerifyCodeRequest {
  const VerifyCodeRequest({required this.phone, required this.code});

  final PhoneNumber phone;
  final String code;

  Map<String, dynamic> toJson() => {'phone': phone.fullDigits, 'code': code};
}

/// `POST /password-reset/confirm/`.
final class ConfirmPasswordResetRequest {
  const ConfirmPasswordResetRequest({
    required this.resetToken,
    required this.password,
  });

  final String resetToken;
  final String password;

  Map<String, dynamic> toJson() => {
        'reset_token': resetToken,
        'password': password,
        'password2': password,
      };
}

/// `POST /auth/change-password/`.
final class ChangePasswordRequest {
  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  Map<String, dynamic> toJson() => {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirm': newPassword,
      };
}

Map<String, dynamic> _nationalPhone(PhoneNumber phone) => {
      'phone': phone.national,
      'dial_code': phone.country.dialCode,
    };
