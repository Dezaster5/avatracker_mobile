import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/location_service.dart';
import '../../core/storage/token_storage.dart';
import 'data/auth_repository.dart';
import 'domain/employee.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Показан ли экран-интро с целью приложения (загружается на splash).
final introSeenProvider = StateProvider<bool>((ref) => false);

final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    storage: ref.watch(tokenStorageProvider),
    onSessionExpired: () async =>
        ref.read(authControllerProvider.notifier).handleSessionExpired(),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(apiClientProvider),
    storage: ref.watch(tokenStorageProvider),
  );
});

/// Состояние сессии (ТЗ 5.1, 19.1):
/// `unknown` — splash, идет проверка; `failed` — bootstrap не удался (ретрай);
/// `unauthenticated` — нужен вход; `authenticated` — полный доступ.
/// FaceID выполняется отдельно перед каждой QR-отметкой.
enum AuthStatus { unknown, failed, unauthenticated, authenticated }

class AuthSession {
  const AuthSession({required this.status, this.employee, this.message});

  final AuthStatus status;
  final Employee? employee;

  /// Сообщение для пользователя (причина выхода/ошибки).
  final String? message;

  AuthSession copyWith({AuthStatus? status, Employee? employee}) => AuthSession(
        status: status ?? this.status,
        employee: employee ?? this.employee,
        message: message,
      );
}

class AuthController extends Notifier<AuthSession> {
  @override
  AuthSession build() => const AuthSession(status: AuthStatus.unknown);

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// Профиль текущего сотрудника: в тест-режиме — из `/api/v1/employees/{iin}/`,
  /// иначе — из мобильного `/profile/me/` по JWT.
  Future<Employee> _loadEmployee([String? iin]) {
    if (AppConfig.testAuthEnabled) {
      return _repo.fetchEmployee(iin ?? AppConfig.testIin);
    }
    return _repo.fetchProfile();
  }

  /// Запускается со splash-экрана: проверка токена и активности сотрудника.
  Future<void> bootstrap() async {
    state = const AuthSession(status: AuthStatus.unknown);
    final storage = ref.read(tokenStorageProvider);
    ref.read(introSeenProvider.notifier).state = await storage.introSeen;
    if (AppConfig.testAuthEnabled) {
      await storage.saveSession(
        accessToken: AppConfig.testBearerToken,
        refreshToken: AppConfig.testRefreshToken,
        iin: AppConfig.testIin,
        phone: AppConfig.testPhone,
      );
    }
    final access = await storage.accessToken;
    final iin = await storage.iin;
    if (access == null || access.isEmpty || iin == null || iin.isEmpty) {
      state = const AuthSession(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final employee = await _loadEmployee(iin);
      if (!employee.active) {
        await logout(message: 'Доступ запрещен. Сотрудник неактивен');
        return;
      }
      state = AuthSession(status: AuthStatus.authenticated, employee: employee);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await logout(message: e.message);
      } else if (e.statusCode == 404) {
        await logout(message: 'Сотрудник не найден в системе');
      } else {
        state = AuthSession(status: AuthStatus.failed, message: e.message);
      }
    } catch (_) {
      state = const AuthSession(
        status: AuthStatus.failed,
        message: 'Ошибка соединения. Попробуйте позже',
      );
    }
  }

  /// После входа или регистрации проверяем активность и открываем приложение.
  Future<void> completeAuth({Employee? employee, String? iin}) async {
    var resolved = employee;
    if (resolved == null) {
      final storedIin = iin ?? await ref.read(tokenStorageProvider).iin;
      resolved = await _loadEmployee(storedIin);
    }
    if (!resolved.active) {
      await logout(message: 'Доступ запрещен. Сотрудник неактивен');
      throw const ApiException(message: 'Доступ запрещен. Сотрудник неактивен');
    }
    state = AuthSession(status: AuthStatus.authenticated, employee: resolved);
  }

  /// Обновление профиля (pull-to-refresh на экране «Мои данные»).
  Future<void> refreshEmployee() async {
    final iin = state.employee?.iin;
    if (iin == null || iin.isEmpty) return;
    final employee = await _loadEmployee(iin);
    if (!employee.active) {
      await logout(message: 'Доступ запрещен. Сотрудник неактивен');
      return;
    }
    state = state.copyWith(employee: employee);
  }

  Future<void> logout({String? message}) async {
    await _repo.logout();
    state = AuthSession(status: AuthStatus.unauthenticated, message: message);
  }

  /// Вызывается api-клиентом, когда refresh-токен мертв.
  void handleSessionExpired() {
    if (state.status == AuthStatus.authenticated) {
      logout(message: 'Сессия истекла. Войдите заново');
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthSession>(AuthController.new);

/// Общее состояние шага «отправили SMS и ждем код».
class SmsFlowState {
  const SmsFlowState({
    this.phone = '',
    this.sending = false,
    this.verifying = false,
    this.error,
    this.codeSentAt,
    this.attemptsLeft = 5,
  });

  final String phone;
  final bool sending;
  final bool verifying;
  final String? error;
  final DateTime? codeSentAt;
  final int attemptsLeft;
}

/// Вход по телефону и паролю.
class LoginState {
  const LoginState({this.submitting = false, this.error});

  final bool submitting;
  final String? error;
}

class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  Future<bool> login({required String phone, required String password}) async {
    state = const LoginState(submitting: true);
    try {
      final employee = await ref
          .read(authRepositoryProvider)
          .login(phone: phone, password: password);
      await ref
          .read(authControllerProvider.notifier)
          .completeAuth(employee: employee);
      state = const LoginState();
      return true;
    } on ApiException catch (e) {
      state = LoginState(error: e.message);
      return false;
    } catch (_) {
      state = const LoginState(error: 'Ошибка соединения. Попробуйте позже');
      return false;
    }
  }

  void clearError() => state = const LoginState();
}

final loginControllerProvider =
    NotifierProvider<LoginController, LoginState>(LoginController.new);

/// Регистрация: телефон + ИИН + пароль -> SMS-код -> аккаунт создан (ТЗ 3, 4).
class RegistrationState extends SmsFlowState {
  const RegistrationState({
    super.phone,
    this.iin = '',
    this.password = '',
    super.sending,
    super.verifying,
    super.error,
    super.codeSentAt,
    super.attemptsLeft,
  });

  final String iin;
  final String password;

  static const _unset = Object();

  RegistrationState copyWith({
    String? phone,
    String? iin,
    String? password,
    bool? sending,
    bool? verifying,
    Object? error = _unset,
    DateTime? codeSentAt,
    int? attemptsLeft,
  }) {
    return RegistrationState(
      phone: phone ?? this.phone,
      iin: iin ?? this.iin,
      password: password ?? this.password,
      sending: sending ?? this.sending,
      verifying: verifying ?? this.verifying,
      error: identical(error, _unset) ? this.error : error as String?,
      codeSentAt: codeSentAt ?? this.codeSentAt,
      attemptsLeft: attemptsLeft ?? this.attemptsLeft,
    );
  }
}

class RegistrationController extends Notifier<RegistrationState> {
  @override
  RegistrationState build() => const RegistrationState();

  Future<bool> sendCode({
    required String phone,
    required String iin,
    required String password,
  }) async {
    state = state.copyWith(
      phone: phone,
      iin: iin,
      password: password,
      sending: true,
      error: null,
    );
    try {
      await ref
          .read(authRepositoryProvider)
          .register(phone: phone, iin: iin, password: password);
      // Фиксируем согласие на обработку ПДн (App Store §5.1.1).
      await ref.read(tokenStorageProvider).saveConsent(
            iin: iin,
            version: AppConfig.privacyPolicyVersion,
          );
      state = state.copyWith(
        sending: false,
        codeSentAt: DateTime.now(),
        attemptsLeft: 5,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(sending: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        sending: false,
        error: 'Ошибка соединения. Попробуйте позже',
      );
      return false;
    }
  }

  Future<bool> resend() async {
    state = state.copyWith(sending: true, error: null);
    try {
      await ref.read(authRepositoryProvider).resendRegisterCode(state.phone);
      state = state.copyWith(
        sending: false,
        codeSentAt: DateTime.now(),
        attemptsLeft: 5,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(sending: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        sending: false,
        error: 'Ошибка соединения. Попробуйте позже',
      );
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);

  Future<bool> verify(String code) async {
    if (state.attemptsLeft <= 0) {
      state = state.copyWith(
        error: 'Превышено количество попыток. Запросите новый код',
      );
      return false;
    }
    state = state.copyWith(verifying: true, error: null);
    try {
      final employee = await ref.read(authRepositoryProvider).verifyRegister(
            phone: state.phone,
            code: code,
            password: state.password,
          );
      await ref
          .read(authControllerProvider.notifier)
          .completeAuth(employee: employee, iin: state.iin);
      state = state.copyWith(verifying: false);
      return true;
    } on ApiException catch (e) {
      final left = state.attemptsLeft - 1;
      state = state.copyWith(
        verifying: false,
        attemptsLeft: left,
        error: left <= 0
            ? 'Превышено количество попыток. Запросите новый код'
            : e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        verifying: false,
        error: 'Ошибка соединения. Попробуйте позже',
      );
      return false;
    }
  }
}

final registrationControllerProvider =
    NotifierProvider<RegistrationController, RegistrationState>(
  RegistrationController.new,
);

/// Сброс пароля: телефон -> SMS-код -> новый пароль.
class PasswordResetState extends SmsFlowState {
  const PasswordResetState({
    super.phone,
    super.sending,
    super.verifying,
    super.error,
    super.codeSentAt,
    super.attemptsLeft,
    this.resetToken,
    this.saving = false,
  });

  /// Токен, выданный после проверки кода, — нужен для финального сброса.
  final String? resetToken;
  final bool saving;

  static const _unset = Object();

  PasswordResetState copyWith({
    String? phone,
    bool? sending,
    bool? verifying,
    Object? error = _unset,
    DateTime? codeSentAt,
    int? attemptsLeft,
    Object? resetToken = _unset,
    bool? saving,
  }) {
    return PasswordResetState(
      phone: phone ?? this.phone,
      sending: sending ?? this.sending,
      verifying: verifying ?? this.verifying,
      error: identical(error, _unset) ? this.error : error as String?,
      codeSentAt: codeSentAt ?? this.codeSentAt,
      attemptsLeft: attemptsLeft ?? this.attemptsLeft,
      resetToken: identical(resetToken, _unset)
          ? this.resetToken
          : resetToken as String?,
      saving: saving ?? this.saving,
    );
  }
}

class PasswordResetController extends Notifier<PasswordResetState> {
  @override
  PasswordResetState build() => const PasswordResetState();

  Future<bool> sendCode(String phone) async {
    state = PasswordResetState(phone: phone, sending: true);
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(phone);
      state = state.copyWith(
        sending: false,
        codeSentAt: DateTime.now(),
        attemptsLeft: 5,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(sending: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        sending: false,
        error: 'Ошибка соединения. Попробуйте позже',
      );
      return false;
    }
  }

  Future<bool> resend() => sendCode(state.phone);

  void clearError() => state = state.copyWith(error: null);

  Future<bool> verify(String code) async {
    if (state.attemptsLeft <= 0) {
      state = state.copyWith(
        error: 'Превышено количество попыток. Запросите новый код',
      );
      return false;
    }
    state = state.copyWith(verifying: true, error: null);
    try {
      final token = await ref
          .read(authRepositoryProvider)
          .verifyPasswordResetCode(phone: state.phone, code: code);
      state = state.copyWith(verifying: false, resetToken: token);
      return true;
    } on ApiException catch (e) {
      final left = state.attemptsLeft - 1;
      state = state.copyWith(
        verifying: false,
        attemptsLeft: left,
        error: left <= 0
            ? 'Превышено количество попыток. Запросите новый код'
            : e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        verifying: false,
        error: 'Ошибка соединения. Попробуйте позже',
      );
      return false;
    }
  }

  /// Финальный шаг: установка нового пароля по выданному reset_token.
  Future<bool> setNewPassword(String newPassword) async {
    final token = state.resetToken;
    if (token == null) {
      state = state.copyWith(error: 'Сначала подтвердите SMS-код');
      return false;
    }
    state = state.copyWith(saving: true, error: null);
    try {
      await ref.read(authRepositoryProvider).confirmPasswordReset(
            resetToken: token,
            newPassword: newPassword,
          );
      state = const PasswordResetState();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(saving: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        saving: false,
        error: 'Ошибка соединения. Попробуйте позже',
      );
      return false;
    }
  }
}

final passwordResetControllerProvider =
    NotifierProvider<PasswordResetController, PasswordResetState>(
  PasswordResetController.new,
);

/// Смена пароля внутри приложения (Профиль -> Сменить пароль).
class ChangePasswordState {
  const ChangePasswordState({this.saving = false, this.error});

  final bool saving;
  final String? error;
}

class ChangePasswordController extends Notifier<ChangePasswordState> {
  @override
  ChangePasswordState build() => const ChangePasswordState();

  Future<bool> change({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const ChangePasswordState(saving: true);
    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
      state = const ChangePasswordState();
      return true;
    } on ApiException catch (e) {
      state = ChangePasswordState(error: e.message);
      return false;
    } catch (_) {
      state = const ChangePasswordState(
        error: 'Ошибка соединения. Попробуйте позже',
      );
      return false;
    }
  }

  void clearError() => state = const ChangePasswordState();
}

final changePasswordControllerProvider =
    NotifierProvider<ChangePasswordController, ChangePasswordState>(
  ChangePasswordController.new,
);
