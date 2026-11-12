import '../../../../core/config/app_config.dart';
import '../../../../core/country/phone_number.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/network_guard.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/employee.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_requests.dart';
import '../models/auth_response_dto.dart';
import '../models/employee_dto.dart';

/// Профиль собирается из нескольких источников: ответ входа содержит `photo`,
/// `/profile/me/` — парк, а `/api/v1/employees/{iin}/` — график и кадровые
/// поля. Дополнительные источники не критичны и не блокируют вход.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<Result<bool>> hasStoredSession() => guardRequest(() async {
        // Тест-режим без auth-API: сессия берётся из dart-define.
        if (AppConfig.testAuthEnabled) {
          await _local.saveSession(
            accessToken: AppConfig.testBearerToken,
            refreshToken: AppConfig.testRefreshToken,
            iin: AppConfig.testIin,
            phone: AppConfig.testPhone,
          );
        }
        final access = await _local.accessToken;
        final iin = await _local.iin;
        return (access?.isNotEmpty ?? false) && (iin?.isNotEmpty ?? false);
      });

  @override
  Future<Result<Employee>> fetchCurrentEmployee() => guardRequest(() async {
        if (AppConfig.testAuthEnabled) {
          final iin = await _local.iin ?? AppConfig.testIin;
          return _cache(
            EmployeeDto.fromJson(await _remote.fetchEmployeeJson(iin)),
          );
        }
        final profile = await _remote.fetchProfileJson();
        final merged = await _withEnrichment(profile);
        return _cache(EmployeeDto.fromJson(await _withCachedPhoto(merged)));
      });

  @override
  Future<Result<Employee>> login({
    required PhoneNumber phone,
    required String password,
  }) =>
      guardRequest(() async {
        final response = await _remote.login(
          LoginRequest(phone: phone, password: password),
        );
        return _openSession(response, phone);
      });

  @override
  Future<Result<void>> requestRegistrationCode({
    required PhoneNumber phone,
    required String iin,
    required String password,
  }) =>
      guardRequest(
        () => _remote.register(
          RegisterRequest(phone: phone, iin: iin, password: password),
        ),
      );

  @override
  Future<Result<void>> resendRegistrationCode(PhoneNumber phone) =>
      guardRequest(() => _remote.resendRegistrationCode(PhoneRequest(phone)));

  @override
  Future<Result<Employee>> verifyRegistration({
    required PhoneNumber phone,
    required String code,
    required String password,
  }) =>
      guardRequest(() async {
        final verified = await _remote.verifyRegistration(
          VerifyCodeRequest(phone: phone, code: code),
        );
        if (verified.hasSession) return _openSession(verified, phone);
        // Регистрация подтверждена без токенов — получаем сессию входом.
        final login = await _remote.login(
          LoginRequest(phone: phone, password: password),
        );
        return _openSession(login, phone);
      });

  @override
  Future<Result<void>> requestPasswordReset(PhoneNumber phone) =>
      guardRequest(() => _remote.requestPasswordReset(PhoneRequest(phone)));

  @override
  Future<Result<String>> verifyPasswordResetCode({
    required PhoneNumber phone,
    required String code,
  }) =>
      guardRequest(
        () => _remote.verifyPasswordResetCode(
          VerifyCodeRequest(phone: phone, code: code),
        ),
      );

  @override
  Future<Result<void>> confirmPasswordReset({
    required String resetToken,
    required String newPassword,
  }) =>
      guardRequest(
        () => _remote.confirmPasswordReset(
          ConfirmPasswordResetRequest(
            resetToken: resetToken,
            password: newPassword,
          ),
        ),
      );

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      guardRequest(
        () => _remote.changePassword(
          ChangePasswordRequest(
            currentPassword: currentPassword,
            newPassword: newPassword,
          ),
        ),
      );

  @override
  Future<Result<void>> deleteAccount() => guardRequest(_remote.deleteProfile);

  @override
  Future<Result<void>> saveConsent({
    required String iin,
    required String policyVersion,
  }) =>
      guardRequest(
        () => _local.saveConsent(iin: iin, policyVersion: policyVersion),
      );

  @override
  Future<void> clearSession() => _local.clearSession();

  @override
  Future<Result<void>> logout() => guardRequest(() async {
        final session = await _local.tokenSession;
        if (session.scheme == AuthScheme.opaque && session.access != null) {
          await _remote.logout(session.access!);
        }
        // Поздний ответ выхода не должен очищать уже открытый новый аккаунт.
        if (await _local.accessToken == session.access) {
          await _local.clearSession();
        }
      });

  /// Сохраняет ключ до запросов профиля, не подменяя refresh постоянным ключом.
  Future<Employee> _openSession(
    AuthResponseDto response,
    PhoneNumber phone,
  ) async {
    final access = response.accessToken;
    if (access == null || access.isEmpty) throw const LoginFailedFailure();
    await _local.saveTokens(
      access: access,
      refresh: response.refreshToken,
      scheme: response.scheme,
    );

    // Поля профиля приоритетнее, но `photo` есть только в ответе входа.
    final merged = {...response.employeeJson, ...await _profileOrEmpty()};
    if (merged.isEmpty) throw const EmployeeDataMissingFailure();
    final employee = EmployeeDto.fromJson(await _withEnrichment(merged));

    if (response.scheme == AuthScheme.opaque &&
        await _local.accessToken != access) {
      throw const UnauthorizedFailure();
    }
    // Не записываем токен повторно: HTTP-клиент мог уже обновить/отозвать его.
    await _local.saveIdentity(iin: employee.iin, phone: phone.e164);
    await _local.saveEmployeeJson(employee.toJson());
    return employee.toEntity();
  }

  Future<Map<String, dynamic>> _profileOrEmpty() async {
    try {
      return await _remote.fetchProfileJson();
    } catch (_) {
      // Профиль не критичен — остаётся сотрудник из ответа входа.
      return const {};
    }
  }

  /// Дополняет карточку графиком и кадровыми полями из data-API.
  Future<Map<String, dynamic>> _withEnrichment(
    Map<String, dynamic> json,
  ) async {
    final iin = '${json['iin'] ?? ''}';
    if (iin.isEmpty) return json;
    try {
      return {...json, ...await _remote.fetchEmployeeJson(iin)};
    } catch (_) {
      // Mobile-профиля достаточно для входа; data-API — только обогащение.
      return json;
    }
  }

  /// `/profile/me/` не отдаёт `photo` — берём его из кеша прошлого входа.
  Future<Map<String, dynamic>> _withCachedPhoto(
    Map<String, dynamic> json,
  ) async {
    if ((json['photo'] ?? json['photo_url']) != null) return json;
    final cached = await _local.readEmployeeJson();
    final photo = cached?['photo'] ?? cached?['photo_url'];
    return photo == null ? json : {...json, 'photo': photo};
  }

  Future<Employee> _cache(EmployeeDto employee) async {
    await _local.saveEmployeeJson(employee.toJson());
    return employee.toEntity();
  }
}
