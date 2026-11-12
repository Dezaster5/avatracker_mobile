import 'package:avatracker_mobile/core/error/failure.dart';
import 'package:avatracker_mobile/core/error/result.dart';
import 'package:avatracker_mobile/features/auth/di/auth_providers.dart';
import 'package:avatracker_mobile/features/auth/domain/policies/password_policy.dart';
import 'package:avatracker_mobile/features/profile/presentation/screens/change_password_screen.dart';
import 'package:avatracker_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../auth/domain/fake_auth_repository.dart';

final _l10n = lookupAppLocalizations(const Locale('ru'));

Future<void> _pumpScreen(
  WidgetTester tester, {
  Result<void> changeResult = const Success(null),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(changePasswordResult: changeResult),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ChangePasswordScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ошибка сервера уходит, как только пользователь правит поле',
      (tester) async {
    const serverMessage = 'Неверный текущий пароль';
    await _pumpScreen(
      tester,
      changeResult: const Failed(
        ValidationFailure(serverMessage: serverMessage),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'wrong-1');
    await tester.enterText(fields.at(1), 'secret1');
    await tester.enterText(fields.at(2), 'secret1');
    await tester.tap(find.text(_l10n.actionSave));
    await tester.pumpAndSettle();
    expect(find.text(serverMessage), findsOneWidget);

    await tester.enterText(fields.at(0), 'wrong-12');
    await tester.pumpAndSettle();
    expect(find.text(serverMessage), findsNothing);
  });

  testWidgets('подсказки следят за новым паролем и подтверждением',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpScreen(tester);
    Matcher met(bool value) =>
        isSemantics(hasCheckedState: true, isChecked: value);
    final minLength = find.text(
      _l10n.passwordRuleMinLength(PasswordPolicy.minLength),
    );
    final match = find.text(_l10n.passwordsMatch);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'current-password');
    await tester.pump();
    expect(tester.getSemantics(minLength), met(false),
        reason: 'текущий пароль к подсказкам не относится');

    await tester.enterText(fields.at(1), 'secret1');
    await tester.enterText(fields.at(2), 'secret1');
    await tester.pump();
    expect(tester.getSemantics(minLength), met(true));
    expect(tester.getSemantics(match), met(true));
    semantics.dispose();
  });
}
