import '../config/app_config.dart';

/// Все адреса API в одном месте.
///
/// - мобильный auth-API — абсолютные адреса на
///   [AppConfig.mobileApiBaseUrl];
/// - data-API `/api/v1` — пути относительно `baseUrl` Dio;
/// - core-API `/api` (QR) — абсолютные адреса на [AppConfig.coreApiBaseUrl].
abstract final class ApiEndpoints {
  static String get register => _mobile('/v2/auth/register/');
  static String get registerVerify => _mobile('/v2/auth/register/verify/');
  static String get registerResend => _mobile('/v2/auth/register/resend/');
  static String get login => _mobile('/v2/auth/login/');
  static String get logout => _mobile('/v2/auth/logout/');
  static String get tokenRefresh => _mobile('/auth/token/refresh/');
  static String get changePassword => _mobile('/auth/change-password/');
  static String get passwordResetRequest => _mobile('/password-reset/request/');
  static String get passwordResetVerify => _mobile('/password-reset/verify/');
  static String get passwordResetConfirm => _mobile('/password-reset/confirm/');
  static String get profile => _mobile('/profile/me/');
  static String get deleteProfile => _mobile('/profile/delete/');

  static const employees = '/employees/';
  static String employee(String iin) => '/employees/$iin/';
  static const attendanceMarks = '/employee-identification-list/';
  static const tardiness = '/tardiness/';
  static const countries = '/countries/';

  static String qrPoint(String qrId) => '${AppConfig.coreApiBaseUrl}/qr/$qrId/';
  static String get qrScan => '${AppConfig.coreApiBaseUrl}/qr/scan/';

  static String _mobile(String path) => '${AppConfig.mobileApiBaseUrl}$path';
}
