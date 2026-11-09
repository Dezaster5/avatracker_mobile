import 'package:avatracker_mobile/app.dart';
import 'package:avatracker_mobile/core/error/failure.dart';
import 'package:avatracker_mobile/core/error/result.dart';
import 'package:avatracker_mobile/features/auth/di/auth_providers.dart';
import 'package:avatracker_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:avatracker_mobile/features/auth/presentation/screens/splash_screen.dart';
import 'package:avatracker_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features/auth/domain/fake_auth_repository.dart';

Future<void> _pumpApp(
    WidgetTester tester, FakeAuthRepository repository) async {
  FlutterSecureStorage.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: const AvaTrackerApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('без сохранённой сессии приложение открывает вход',
      (tester) async {
    await _pumpApp(
      tester,
      FakeAuthRepository(storedSession: const Success(false)),
    );
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('отозванная сессия: вход и причина на языке интерфейса',
      (tester) async {
    await _pumpApp(
      tester,
      FakeAuthRepository(currentEmployee: const Failed(UnauthorizedFailure())),
    );
    final l10n = lookupAppLocalizations(const Locale('kk'));
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(l10n.errorSessionExpired), findsOneWidget);
  });

  testWidgets('нет сети при проверке сессии — повтор на splash, не выход',
      (tester) async {
    final repository =
        FakeAuthRepository(currentEmployee: const Failed(NetworkFailure()));
    await _pumpApp(tester, repository);
    final l10n = lookupAppLocalizations(const Locale('kk'));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text(l10n.errorConnection), findsOneWidget);
    expect(repository.clearSessionCalls, 0);
  });
}
