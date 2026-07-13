import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/utils/formatters.dart';
import '../domain/employee.dart';

/// Авторизация мобильного API AvaTracker (`…/api/mobile`, SimpleJWT):
/// - регистрация: телефон + ИИН + пароль, подтверждение SMS-кодом;
/// - вход: телефон + пароль; сброс пароля: SMS-код -> reset_token -> новый пароль;
/// - профиль текущего сотрудника `GET /profile/me/`.
///
/// Данные посещаемости (табель, аналитика, скан) и профиль в тест-режиме
/// берутся из data-API `/api/v1` тем же JWT.
class AuthRepository {
  AuthRepository({required ApiClient api, required TokenStorage storage})
      : _dio = api.dio,
        _storage = storage;

  final Dio _dio;
  final TokenStorage _storage;

  String _mobile(String path) => '${AppConfig.mobileApiBaseUrl}$path';

  /// Полный номер с кодом страны без «+» (например `77714322337`).
  /// verify-шаги (`register/verify/`, `password-reset/verify/`) ждут именно
  /// его, тогда как login/register/resend/request берут национальный `phone`
  /// + отдельный `dial_code`. Страна определяется из E.164-номера.
  static String _fullPhone(String phone) =>
      fullPhoneFor(phone, countryOfE164(phone));

  // ─── Регистрация ──────────────────────────────────────────────────────────

  /// Шаг 1: `POST /auth/register/` — заводит challenge и отправляет SMS.
  /// Пароль задаётся уже здесь (бэкенд хранит его до подтверждения кода).
  Future<void> register({
    required String phone,
    required String iin,
    required String password,
  }) async {
    final p = splitPhoneFor(phone, countryOfE164(phone));
    await _postMobile('/auth/register/', {
      'phone': p.number,
      'dial_code': p.dialCode,
      'iin': iin,
      'password': password,
      'password2': password,
    });
  }

  /// Шаг 2: `POST /auth/register/verify/` — код подтверждения.
  /// Если бэкенд вернул JWT — входим сразу; иначе логинимся паролем.
  Future<Employee> verifyRegister({
    required String phone,
    required String code,
    required String password,
  }) async {
    final data = await _postMobile('/auth/register/verify/', {
      'phone': _fullPhone(phone),
      'code': code,
    });
    if (_accessOf(data) != null) {
      return _persistAndLoad(data, phone: phone);
    }
    // Регистрация подтверждена, но токены не пришли — получаем сессию входом.
    return login(phone: phone, password: password);
  }

  /// `POST /auth/register/resend/` — повторная отправка кода регистрации.
  Future<void> resendRegisterCode(String phone) async {
    final p = splitPhoneFor(phone, countryOfE164(phone));
    await _postMobile('/auth/register/resend/', {
      'phone': p.number,
      'dial_code': p.dialCode,
    });
  }

  // ─── Вход ─────────────────────────────────────────────────────────────────

  /// `POST /auth/login/` — вход по телефону и паролю, возвращает JWT.
  Future<Employee> login({
    required String phone,
    required String password,
  }) async {
    final p = splitPhoneFor(phone, countryOfE164(phone));
    final data = await _postMobile('/auth/login/', {
      'phone': p.number,
      'dial_code': p.dialCode,
      'password': password,
    });
    return _persistAndLoad(data, phone: phone);
  }

  // ─── Сброс пароля ─────────────────────────────────────────────────────────

  /// `POST /password-reset/request/` — SMS-код для сброса пароля.
  Future<void> requestPasswordReset(String phone) async {
    final p = splitPhoneFor(phone, countryOfE164(phone));
    await _postMobile('/password-reset/request/', {
      'phone': p.number,
      'dial_code': p.dialCode,
    });
  }

  /// `POST /password-reset/verify/` — проверка кода, возвращает `reset_token`
  /// для финального шага.
  Future<String> verifyPasswordResetCode({
    required String phone,
    required String code,
  }) async {
    final data = await _postMobile('/password-reset/verify/', {
      'phone': _fullPhone(phone),
      'code': code,
    });
    final token = (data['reset_token'] ?? data['token'])?.toString();
    if (token == null || token.isEmpty) {
      throw const ApiException(message: 'Сервер не вернул токен сброса');
    }
    return token;
  }

  /// `POST /password-reset/confirm/` — установка нового пароля по reset_token.
  Future<void> confirmPasswordReset({
    required String resetToken,
    required String newPassword,
  }) async {
    await _postMobile('/password-reset/confirm/', {
      'reset_token': resetToken,
      'password': newPassword,
      'password2': newPassword,
    });
  }

  /// `POST /auth/change-password/` — смена пароля внутри приложения (по JWT).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _postMobile('/auth/change-password/', {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirm': newPassword,
    });
  }

  // ─── Профиль и FaceID ─────────────────────────────────────────────────────

  /// Сырой профиль из `GET /profile/me/` (бэкенд НЕ присылает здесь `photo`).
  Future<Map<String, dynamic>> _profileJson() async {
    try {
      final res = await _dio.get<dynamic>(_mobile('/profile/me/'));
      return _unwrap(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> _employeeJson(String iin) async {
    try {
      final res = await _dio.get<dynamic>('/employees/$iin/');
      return _unwrap(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Дополняет профиль полем `photo` из кеша, если бэкенд его не прислал
  /// (`/profile/me/` фото не отдаёт, а `login`/`register` — отдают).
  Future<Map<String, dynamic>> _withCachedPhoto(
    Map<String, dynamic> json,
  ) async {
    if ((json['photo'] ?? json['photo_url']) != null) return json;
    final cached = await _storage.readEmployeeJson();
    final photo = cached?['photo'] ?? cached?['photo_url'];
    return photo == null ? json : {...json, 'photo': photo};
  }

  /// Профиль текущего сотрудника по JWT. Базовые данные приходят из
  /// `/profile/me/`, а график и полные кадровые поля дополняются из
  /// `/api/v1/employees/{iin}/`. Дополнительный запрос не блокирует вход.
  Future<Employee> fetchProfile() async {
    final profile = await _profileJson();
    var merged = profile;
    final iin = '${profile['iin'] ?? ''}';
    if (iin.isNotEmpty) {
      try {
        merged = {...profile, ...await _employeeJson(iin)};
      } catch (_) {
        // Mobile profile достаточен для входа; employee API — обогащение.
      }
    }
    final employee = Employee.fromJson(await _withCachedPhoto(merged));
    await _storage.saveEmployeeJson(employee.toJson());
    return employee;
  }

  /// `GET /api/v1/employees/{iin}/` — профиль из data-API (тест-режим).
  Future<Employee> fetchEmployee(String iin) async {
    final employee = Employee.fromJson(await _employeeJson(iin));
    await _storage.saveEmployeeJson(employee.toJson());
    return employee;
  }

  /// `DELETE /api/mobile/profile/delete/` — полное удаление мобильного аккаунта
  /// (по JWT). Данные сотрудника в основной системе сохраняются; для входа
  /// нужна повторная регистрация. Локальная сессия очищается при успехе.
  Future<void> deleteAccount() async {
    try {
      await _dio.delete<dynamic>(_mobile('/profile/delete/'));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
    await _storage.clearSession();
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

  // ─── Внутреннее ───────────────────────────────────────────────────────────

  /// POST на мобильный auth-API. Ошибки DRF (`detail` / поля) превращаются
  /// в [ApiException]. Возвращает тело-Map (или пустую Map, если тела нет).
  Future<Map<String, dynamic>> _postMobile(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _dio.post<dynamic>(_mobile(path), data: body);
      final data = res.data;
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  static String? _accessOf(Map<String, dynamic> data) =>
      (data['access'] ?? data['access_token'])?.toString();

  /// Сохраняет JWT и собирает сотрудника из ответа входа + `/profile/me/`.
  ///
  /// Ответ `login`/`register` содержит `employee` с `photo` (но без парка),
  /// а `/profile/me/` — с парком, но без `photo`. Сливаем оба, чтобы было
  /// и фото (профиль + FaceID), и парк.
  Future<Employee> _persistAndLoad(
    Map<String, dynamic> data, {
    required String phone,
  }) async {
    final access = _accessOf(data);
    final refresh = (data['refresh'] ?? data['refresh_token'])?.toString();
    if (access == null || access.isEmpty) {
      throw ApiException(
        message: data['detail']?.toString() ?? 'Не удалось войти',
      );
    }
    // Токен нужен раньше профиля — сохраняем, чтобы запрос /profile/me/ его нёс.
    await _storage.saveTokens(access: access, refresh: refresh ?? access);

    final authEmployee = data['employee'] is Map
        ? Map<String, dynamic>.from(data['employee'] as Map)
        : <String, dynamic>{};
    Map<String, dynamic> profile;
    try {
      profile = await _profileJson();
    } catch (_) {
      profile = const {}; // профиль не критичен — фолбэк на employee из входа
    }
    // Поля профиля имеют приоритет, но photo (только у authEmployee) сохраняется.
    final merged = {...authEmployee, ...profile};
    if (merged.isEmpty) {
      throw const ApiException(message: 'Сервер не вернул данные сотрудника');
    }
    final employee = Employee.fromJson(merged);

    await _storage.saveSession(
      accessToken: access,
      refreshToken: refresh ?? access,
      iin: employee.iin,
      phone: phone,
    );
    await _storage.saveEmployeeJson(employee.toJson());
    return employee;
  }

  static Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final inner = data['data'] ?? data['employee'] ?? data['profile'];
      if (inner is Map<String, dynamic> && inner.containsKey('iin')) {
        return inner;
      }
      return data;
    }
    throw const ApiException(message: 'Неверный формат ответа сервера');
  }
}
