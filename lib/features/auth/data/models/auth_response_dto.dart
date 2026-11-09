/// Ответ входа и подтверждения регистрации: JWT-пара (SimpleJWT
/// `access`/`refresh` или `access_token`/`refresh_token`) и сотрудник.
///
/// `employee` из ответа входа содержит `photo`, но не парк — поэтому
/// профиль дополняется из `/profile/me/`.
final class AuthResponseDto {
  const AuthResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.employeeJson,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'];
    return AuthResponseDto(
      accessToken: (json['access'] ?? json['access_token'])?.toString(),
      refreshToken: (json['refresh'] ?? json['refresh_token'])?.toString(),
      employeeJson: employee is Map
          ? Map<String, dynamic>.from(employee)
          : const <String, dynamic>{},
    );
  }

  final String? accessToken;
  final String? refreshToken;
  final Map<String, dynamic> employeeJson;

  /// Ответ содержит сессию (verify может подтвердить регистрацию без неё).
  bool get hasSession => accessToken != null;
}
