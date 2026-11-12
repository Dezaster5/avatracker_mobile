import 'package:avatracker_mobile/features/auth/domain/policies/password_policy.dart';
import 'package:avatracker_mobile/features/auth/presentation/widgets/password_requirements.dart';
import 'package:avatracker_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher _met(bool value) =>
    isSemantics(hasCheckedState: true, isChecked: value);

void main() {
  final l10n = lookupAppLocalizations(const Locale('ru'));
  final minLength = l10n.passwordRuleMinLength(PasswordPolicy.minLength);
  final noSpaces = l10n.passwordRuleNoSpaces;
  final match = l10n.passwordsMatch;

  testWidgets('пункты загораются по мере ввода пароля и подтверждения',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final password = TextEditingController();
    final confirmation = TextEditingController();
    addTearDown(password.dispose);
    addTearDown(confirmation.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PasswordRequirements(
            password: password,
            confirmation: confirmation,
          ),
        ),
      ),
    );
    void expectItems({
      required bool length,
      required bool spaces,
      required bool same,
    }) {
      expect(tester.getSemantics(find.text(minLength)), _met(length));
      expect(tester.getSemantics(find.text(noSpaces)), _met(spaces));
      expect(tester.getSemantics(find.text(match)), _met(same));
    }

    // Пустое поле ничего не выполняет заранее, даже «без пробелов».
    expectItems(length: false, spaces: false, same: false);

    password.text = 'abc';
    await tester.pump();
    expectItems(length: false, spaces: true, same: false);

    password.text = 'abc def';
    await tester.pump();
    expectItems(length: true, spaces: false, same: false);

    password.text = 'secret1';
    confirmation.text = 'secret';
    await tester.pump();
    expectItems(length: true, spaces: true, same: false);

    confirmation.text = 'secret1';
    await tester.pump();
    expectItems(length: true, spaces: true, same: true);

    semantics.dispose();
  });
}
