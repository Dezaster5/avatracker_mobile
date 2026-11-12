import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/auth_requests.dart';
import '../models/auth_response_dto.dart';
import '../models/employee_dto.dart';

/// HTTP-вызовы мобильного auth-API и карточки сотрудника из
/// data-API `/api/v1`. Ошибки не обрабатывает — это делает репозиторий.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<void> register(RegisterRequest request) async {
    await _post(ApiEndpoints.register, request.toJson());
  }

  Future<AuthResponseDto> verifyRegistration(VerifyCodeRequest request) async =>
      AuthResponseDto.fromJson(
        await _post(ApiEndpoints.registerVerify, request.toJson()),
      );

  Future<void> resendRegistrationCode(PhoneRequest request) async {
    await _post(ApiEndpoints.registerResend, request.toJson());
  }

  Future<AuthResponseDto> login(LoginRequest request) async =>
      AuthResponseDto.fromJson(
        await _post(ApiEndpoints.login, request.toJson()),
      );

  Future<void> requestPasswordReset(PhoneRequest request) async {
    await _post(ApiEndpoints.passwordResetRequest, request.toJson());
  }

  /// Проверка кода сброса; код не сжигается до финального шага.
  Future<String> verifyPasswordResetCode(VerifyCodeRequest request) async {
    final data =
        await _post(ApiEndpoints.passwordResetVerify, request.toJson());
    final token = (data['reset_token'] ?? data['token'])?.toString();
    if (token == null || token.isEmpty) {
      throw const ResetTokenMissingFailure();
    }
    return token;
  }

  Future<void> confirmPasswordReset(ConfirmPasswordResetRequest request) async {
    await _post(ApiEndpoints.passwordResetConfirm, request.toJson());
  }

  Future<void> changePassword(ChangePasswordRequest request) async {
    await _post(ApiEndpoints.changePassword, request.toJson());
  }

  Future<void> logout(String token) async {
    try {
      await _dio.post<dynamic>(
        ApiEndpoints.logout,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (error) {
      // Уже отозванный ключ также позволяет завершить локальную сессию.
      if (error.response?.statusCode != 401) rethrow;
    }
  }

  /// `GET /profile/me/` — бэкенд не присылает здесь `photo`.
  Future<Map<String, dynamic>> fetchProfileJson() async {
    final response = await _dio.get<dynamic>(ApiEndpoints.profile);
    return _unwrap(response.data);
  }

  /// Карточка сотрудника из data-API. Если detail-ответ без графика,
  /// используется поиск по ИИН: в production график есть в пагинированном
  /// `/employees/`.
  Future<Map<String, dynamic>> fetchEmployeeJson(String iin) async {
    Map<String, dynamic>? detail;
    DioException? detailError;
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.employee(iin));
      detail = _unwrap(response.data);
      if (EmployeeDto.hasSchedule(detail)) return detail;
    } on DioException catch (error) {
      detailError = error;
    }

    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.employees,
        queryParameters: {'search': iin},
      );
      final match = _findByIin(response.data, iin);
      if (match != null) return match;
    } on DioException catch (error) {
      if (detail == null) throw detailError ?? error;
    }
    if (detail != null) return detail;
    throw const EmployeeNotFoundFailure();
  }

  /// `DELETE /profile/delete/` — полное удаление мобильного аккаунта.
  Future<void> deleteProfile() async {
    await _dio.delete<dynamic>(ApiEndpoints.deleteProfile);
  }

  Future<Map<String, dynamic>> _post(
    String url,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<dynamic>(url, data: body);
    final data = response.data;
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  static Map<String, dynamic>? _findByIin(dynamic data, String iin) {
    if (data is! Map<String, dynamic> || data['results'] is! List) return null;
    for (final employee
        in (data['results'] as List).whereType<Map<String, dynamic>>()) {
      if ('${employee['iin'] ?? ''}' == iin) return employee;
    }
    return null;
  }

  /// Профиль бывает обёрнут в `data`/`employee`/`profile`.
  static Map<String, dynamic> _unwrap(dynamic data) {
    if (data is! Map<String, dynamic>) throw const InvalidResponseFailure();
    final inner = data['data'] ?? data['employee'] ?? data['profile'];
    if (inner is Map<String, dynamic> && inner.containsKey('iin')) return inner;
    return data;
  }
}
