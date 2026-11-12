import '../../../../core/storage/token_storage.dart';

/// Ответ входа и регистрации: постоянный ключ v2 либо прежняя JWT-пара.
///
/// `employee` из ответа входа содержит `photo`, но не парк — поэтому
/// профиль дополняется из `/profile/me/`.
final class AuthResponseDto {
  const AuthResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.employeeJson,
    this.scheme = AuthScheme.jwt,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'];
    final token = json['token']?.toString();
    final isOpaque = token != null && token.isNotEmpty;
    return AuthResponseDto(
      accessToken: isOpaque
          ? token
          : (json['access'] ?? json['access_token'])?.toString(),
      refreshToken: isOpaque
          ? null
          : (json['refresh'] ?? json['refresh_token'])?.toString(),
      scheme: isOpaque ? AuthScheme.opaque : AuthScheme.jwt,
      employeeJson: employee is Map
          ? Map<String, dynamic>.from(employee)
          : const <String, dynamic>{},
    );
  }

  final String? accessToken;
  final String? refreshToken;
  final Map<String, dynamic> employeeJson;
  final AuthScheme scheme;

  /// Ответ содержит сессию (verify может подтвердить регистрацию без неё).
  bool get hasSession => accessToken?.isNotEmpty ?? false;
}
