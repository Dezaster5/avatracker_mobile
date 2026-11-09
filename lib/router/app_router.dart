import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/navigation/root_navigator_key.dart';
import '../features/attendance/presentation/screens/analytics_screen.dart';
import '../features/attendance/presentation/screens/scanner_screen.dart';
import '../features/attendance/presentation/screens/timesheet_screen.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';
import '../features/auth/presentation/screens/sms_code_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/legal/presentation/screens/about_screen.dart';
import '../features/legal/presentation/screens/delete_account_screen.dart';
import '../features/legal/presentation/screens/privacy_policy_screen.dart';
import '../features/profile/presentation/screens/change_password_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/shell/presentation/main_shell.dart';

/// Страницы auth-флоу (авторизованного пользователя выкидываем отсюда).
const _authFlow = {
  '/login',
  '/register',
  '/sms-register',
  '/forgot',
  '/sms-reset',
  '/reset-password',
};

/// Страницы, доступные без сессии: auth-флоу + Политика конфиденциальности.
bool _isPublic(String location) =>
    _authFlow.contains(location) || location == '/privacy';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen<AuthSession>(authControllerProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;

      switch (auth.status) {
        case AuthStatus.unknown:
        case AuthStatus.failed:
          return location == '/splash' ? null : '/splash';
        case AuthStatus.unauthenticated:
          if (_isPublic(location)) return null;
          return '/login';
        case AuthStatus.authenticated:
          final onGuardPages =
              location == '/splash' || _authFlow.contains(location);
          return onGuardPages ? '/scanner' : null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: '/privacy', builder: (_, __) => const PrivacyPolicyScreen()),
      GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),
      GoRoute(
        path: '/delete-account',
        builder: (_, __) => const DeleteAccountScreen(),
      ),
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/scanner',
                builder: (_, __) => const ScannerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/timesheet',
                builder: (_, __) => const TimesheetScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                builder: (_, __) => const AnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
