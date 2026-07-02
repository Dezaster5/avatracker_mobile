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
import '../features/legal/presentation/about_screen.dart';
import '../features/legal/presentation/delete_account_screen.dart';
import '../features/legal/presentation/intro_screen.dart';
import '../features/legal/presentation/privacy_policy_screen.dart';
import '../features/profile/presentation/change_password_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/shell/main_shell.dart';

/// Страницы auth-флоу (авторизованного пользователя выкидываем отсюда).
const _authFlow = {
  '/login',
  '/register',
  '/sms-register',
  '/forgot',
  '/sms-reset',
  '/reset-password',
  '/intro',
};

/// Страницы, доступные без сессии: auth-флоу + Политика конфиденциальности.
bool _isPublic(String location) =>
    _authFlow.contains(location) || location == '/privacy';

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

      switch (auth.status) {
        case AuthStatus.unknown:
        case AuthStatus.failed:
          return location == '/splash' ? null : '/splash';
        case AuthStatus.unauthenticated:
          if (_isPublic(location)) return null;
          // До входа сначала показываем экран с целью приложения (App Review).
          return ref.read(introSeenProvider) ? '/login' : '/intro';
        case AuthStatus.authenticated:
          final onGuardPages =
              location == '/splash' || _authFlow.contains(location);
          return onGuardPages ? '/scanner' : null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/intro', builder: (_, __) => const IntroScreen()),
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
