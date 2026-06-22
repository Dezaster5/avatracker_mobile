import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/attendance/presentation/scanner_screen.dart';
import '../features/attendance/presentation/analytics_screen.dart';
import '../features/attendance/presentation/timesheet_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/auth/presentation/sms_code_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/providers.dart';
import '../features/profile/presentation/change_password_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/shell/main_shell.dart';

/// Страницы, доступные без сессии (вход/регистрация/сброс пароля).
const _authLocations = {
  '/login',
  '/register',
  '/sms-register',
  '/forgot',
  '/sms-reset',
  '/reset-password',
};

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen<AuthSession>(authControllerProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final onAuthPages = _authLocations.contains(location);

      switch (auth.status) {
        case AuthStatus.unknown:
        case AuthStatus.failed:
          return location == '/splash' ? null : '/splash';
        case AuthStatus.unauthenticated:
          return onAuthPages ? null : '/login';
        case AuthStatus.authenticated:
          final onGuardPages = location == '/splash' || onAuthPages;
          return onGuardPages ? '/scanner' : null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/sms-register',
        builder: (_, __) => const SmsCodeScreen(flow: SmsFlow.register),
      ),
      GoRoute(
        path: '/forgot',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/sms-reset',
        builder: (_, __) => const SmsCodeScreen(flow: SmsFlow.reset),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, __) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (_, __) => const ChangePasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            MainShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/scanner', builder: (_, __) => const ScannerScreen()),
          GoRoute(
              path: '/timesheet', builder: (_, __) => const TimesheetScreen()),
          GoRoute(path: '/stats', builder: (_, __) => const AnalyticsScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
});
