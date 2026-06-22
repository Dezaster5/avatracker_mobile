import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/employee.dart';

class FaceVerifyResult {
  const FaceVerifyResult({
    required this.success,
    required this.accessGranted,
    this.verificationToken,
    this.matchPercent,
    this.message,
  });

  final bool success;
  final bool accessGranted;
  final String? verificationToken;
  final double? matchPercent;
  final String? message;

  factory FaceVerifyResult.fromJson(Map<String, dynamic> json) {
    final success = json['success'] == true;
    final granted = json.containsKey('access_granted')
        ? json['access_granted'] == true
        : success;
    return FaceVerifyResult(
      success: success,
      accessGranted: granted,
      verificationToken:
          (json['verification_token'] ?? json['face_token'])?.toString(),
      matchPercent: (json['match_percent'] as num?)?.toDouble(),
      message: json['message']?.toString(),
    );
  }
}

/// Авторизация AvaTracker:
/// - регистрация: телефон + ИИН + пароль, подтверждение SMS-кодом;
/// - вход: телефон + пароль;
/// - сброс пароля: SMS-код -> новый пароль;
/// - смена пароля: текущий + новый (внутри приложения);
/// - FaceID-сверка и данные сотрудника (ТЗ 13.1–13.4).
class AuthRepository {
  AuthRepository({required ApiClient api, required TokenStorage storage})
      : _dio = api.dio,
        _storage = storage;

  final Dio _dio;
  final TokenStorage _storage;

  /// `POST /mobile/auth/register/send-code` — SMS для подтверждения регистрации.
  Future<void> sendRegisterCode({
    required String phone,
    required String iin,
  }) =>
      _postExpectSuccess('/mobile/auth/register/send-code', {
        'phone': phone,
        'iin': iin,
      });

  /// `POST /mobile/auth/register/verify` — код + пароль, создает аккаунт
  /// и возвращает сессию.
  Future<Employee?> verifyRegister({
    required String phone,
    required String iin,
    required String code,
    required String password,
  }) async {
    final data = await _post('/mobile/auth/register/verify', {
      'phone': phone,
      'iin': iin,
      'code': code,
      'password': password,
    });
    return _saveSession(data, phone: phone, fallbackIin: iin);
  }

  /// `POST /mobile/auth/login` — вход по телефону и паролю.
  Future<Employee?> login({
    required String phone,
    required String password,
  }) async {
    final data = await _post('/mobile/auth/login', {
      'phone': phone,
      'password': password,
    });
    return _saveSession(data, phone: phone);
  }

  /// `POST /mobile/auth/password/forgot` — SMS-код для сброса пароля.
  Future<void> sendResetCode(String phone) =>
      _postExpectSuccess('/mobile/auth/password/forgot', {'phone': phone});

  /// `POST /mobile/auth/password/verify-code` — проверка кода сброса.
  Future<void> verifyResetCode({
    required String phone,
    required String code,
  }) =>
      _postExpectSuccess('/mobile/auth/password/verify-code', {
        'phone': phone,
        'code': code,
      });

  /// `POST /mobile/auth/password/reset` — установка нового пароля по коду.
  Future<void> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  }) =>
      _postExpectSuccess('/mobile/auth/password/reset', {
        'phone': phone,
        'code': code,
        'new_password': newPassword,
      });

  /// `POST /mobile/auth/password/change` — смена пароля внутри приложения.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _postExpectSuccess('/mobile/auth/password/change', {
        'current_password': currentPassword,
        'new_password': newPassword,
      });

  /// `GET /employees/{iin}/` — данные и активность сотрудника (ТЗ 13.1).
  Future<Employee> fetchEmployee(String iin) async {
    try {
      final res = await _dio.get<dynamic>('/employees/$iin/');
      final employee = Employee.fromJson(_unwrap(res.data));
      await _storage.saveEmployeeJson(employee.toJson());
      return employee;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// `POST /mobile/auth/face-verify` (ТЗ 13.4).
  Future<FaceVerifyResult> faceVerify({
    required String iin,
    required String imageBase64,
    required String qrId,
  }) async {
    final data = await _post(
        '/mobile/auth/face-verify',
        {
          'iin': iin,
          'image': imageBase64,
          'qr_id': qrId,
        },
        validateSuccess: false);
    return FaceVerifyResult.fromJson(data);
  }

  Future<Employee?> cachedEmployee() async {
    final json = await _storage.readEmployeeJson();
    if (json == null) return null;
    try {
      return Employee.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() => _storage.clearSession();

  /// POST с разбором ответа: `success: false` превращается в [ApiException].
  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    bool validateSuccess = true,
  }) async {
    try {
      final res = await _dio.post<dynamic>(path, data: body);
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Неверный формат ответа сервера');
      }
      if (validateSuccess && data['success'] == false) {
        throw ApiException(
          message: data['message']?.toString() ?? 'Запрос отклонен сервером',
        );
      }
      return data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> _postExpectSuccess(String path, Map<String, dynamic> body) =>
      _post(path, body);

  /// Сохраняет токены и профиль из ответа авторизации.
  Future<Employee?> _saveSession(
    Map<String, dynamic> data, {
    required String phone,
    String? fallbackIin,
  }) async {
    final access = data['access_token']?.toString();
    final refresh = data['refresh_token']?.toString();
    if (data['success'] != true || access == null || refresh == null) {
      throw ApiException(
        message: data['message']?.toString() ?? 'Не удалось войти',
      );
    }

    Employee? employee;
    final employeeJson = data['employee'];
    if (employeeJson is Map<String, dynamic>) {
      employee = Employee.fromJson(employeeJson);
    }
    final iin = employee?.iin.isNotEmpty == true
        ? employee!.iin
        : (data['iin']?.toString() ?? fallbackIin ?? '');
    if (iin.isEmpty) {
      throw const ApiException(message: 'Сервер не вернул ИИН сотрудника');
    }

    await _storage.saveSession(
      accessToken: access,
      refreshToken: refresh,
      iin: iin,
      phone: phone,
    );
    if (employee != null) {
      await _storage.saveEmployeeJson(employee.toJson());
    }
    return employee;
  }

  static Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is Map<String, dynamic> && inner.containsKey('iin')) {
        return inner;
      }
      return data;
    }
    throw const ApiException(message: 'Неверный формат ответа сервера');
  }
}
