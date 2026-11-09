import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../di/auth_providers.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/session_restoration.dart';

/// Состояние сессии (ТЗ 5.1, 19.1): `unknown` — splash, идёт проверка;
/// `failed` — проверка не удалась (повтор); `unauthenticated` — нужен вход;
/// `authenticated` — полный доступ. FaceID выполняется перед каждой отметкой.
enum AuthStatus { unknown, failed, unauthenticated, authenticated }

@immutable
class AuthSession {
  const AuthSession({
    required this.status,
    this.employee,
    this.failure,
    this.logoutReason,
  });

  const AuthSession.unknown() : this(status: AuthStatus.unknown);

  const AuthSession.authenticated(Employee employee)
      : this(status: AuthStatus.authenticated, employee: employee);

  const AuthSession.signedOut([LogoutReason? reason])
      : this(status: AuthStatus.unauthenticated, logoutReason: reason);

  final AuthStatus status;
  final Employee? employee;

  /// Почему не удалось проверить сессию (`failed`).
  final Failure? failure;

  /// Почему сессия завершилась без действия пользователя.
  final LogoutReason? logoutReason;
}

class AuthController extends Notifier<AuthSession> {
  @override
  AuthSession build() {
    final expiry = ref.read(sessionExpiryProvider).events.listen(
          (_) => _onSessionExpired(),
        );
    ref.onDispose(expiry.cancel);
    return const AuthSession.unknown();
  }

  /// Запускается со splash-экрана: проверка токена и активности сотрудника.
  Future<void> bootstrap() async {
    state = const AuthSession.unknown();
    final restoration = await ref.read(restoreSessionProvider).call();
    state = switch (restoration) {
      SessionRestored(:final employee) => AuthSession.authenticated(employee),
      NoStoredSession() => const AuthSession.signedOut(),
      SessionRevoked(:final reason) => AuthSession.signedOut(reason),
      SessionRestoreFailed(:final failure) =>
        AuthSession(status: AuthStatus.failed, failure: failure),
    };
  }

  /// Вход или регистрация завершились — открываем приложение.
  void signedIn(Employee employee) =>
      state = AuthSession.authenticated(employee);

  /// Обновление профиля (pull-to-refresh). Возвращает ошибку для показа;
  /// `null` — профиль обновлён или сотрудник отключён и сессия завершена.
  Future<Failure?> refreshEmployee() async {
    final iin = state.employee?.iin;
    if (iin == null || iin.isEmpty) return null;
    switch (await ref.read(refreshProfileProvider).call()) {
      case Success(:final value):
        // Пока шёл запрос, сессия могла завершиться — не восстанавливаем её.
        if (state.status == AuthStatus.authenticated) {
          state = AuthSession.authenticated(value);
        }
        return null;
      case Failed(failure: EmployeeInactiveFailure()):
        state = const AuthSession.signedOut(LogoutReason.employeeInactive);
        return null;
      case Failed(:final failure):
        return failure;
    }
  }

  /// Выход пользователем или по причине [reason].
  Future<void> logout({LogoutReason? reason}) async {
    await ref.read(signOutProvider).call();
    state = AuthSession.signedOut(reason);
  }

  /// Сессия уже очищена (например, аккаунт удалён) — уводим на вход.
  void signedOut(LogoutReason reason) => state = AuthSession.signedOut(reason);

  /// Причина выхода показана пользователю — повторно её не показываем.
  void acknowledgeLogoutReason() {
    if (state.logoutReason != null) state = const AuthSession.signedOut();
  }

  /// HTTP-клиент сообщил, что refresh-токен отклонён сервером.
  void _onSessionExpired() {
    if (state.status == AuthStatus.authenticated) {
      logout(reason: LogoutReason.sessionExpired);
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthSession>(AuthController.new);
