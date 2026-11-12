import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avatracker_mobile/core/widgets/app_text_form_field.dart';
import 'package:avatracker_mobile/core/widgets/password_field.dart';
import 'package:avatracker_mobile/core/widgets/pin_code_field.dart';
import 'package:avatracker_mobile/core/widgets/primary_button.dart';
import 'package:avatracker_mobile/core/widgets/requirement_list.dart';
import 'package:avatracker_mobile/core/widgets/status_chip.dart';
import 'package:avatracker_mobile/l10n/app_localizations.dart';

void main() {
  testWidgets('PrimaryButton показывает лоадер и блокируется', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(label: 'Войти', onPressed: () => pressed = true),
        ),
      ),
    );
    expect(find.text('Войти'), findsOneWidget);
    await tester.tap(find.byType(PrimaryButton));
    expect(pressed, true);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PrimaryButton(label: 'Войти', loading: true)),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Войти'), findsNothing);
  });

  testWidgets('StatusChip отображает подпись', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusChip(label: 'Вовремя', color: Colors.green)),
      ),
    );
    expect(find.text('Вовремя'), findsOneWidget);
  });

  testWidgets('PinCodeField показывает цифры и зовет onCompleted',
      (tester) async {
    String? completed;
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PinCodeField(
            length: 4,
            controller: controller,
            onCompleted: (code) => completed = code,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '1234');
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(completed, '1234');
    controller.dispose();
  });

  testWidgets('PinCodeField предлагает код из SMS и не шлёт его повторно',
      (tester) async {
    var completedCalls = 0;
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PinCodeField(
            length: 4,
            controller: controller,
            onCompleted: (_) => completedCalls++,
          ),
        ),
      ),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.autofillHints, contains(AutofillHints.oneTimeCode));

    await tester.enterText(find.byType(TextField), '1234');
    // Смена выделения в заполненном поле — не новый ввод кода.
    controller.selection = const TextSelection.collapsed(offset: 1);
    await tester.pump();
    expect(completedCalls, 1);
  });

  testWidgets('PasswordField скрывает и показывает пароль', (tester) async {
    final controller = TextEditingController(text: 'secret1');
    final l10n = lookupAppLocalizations(const Locale('ru'));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PasswordField(controller: controller)),
      ),
    );
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    // Кнопка названа для экранного диктора и меняет название вместе с иконкой.
    await tester.tap(find.byTooltip(l10n.showPassword));
    await tester.pump();
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    expect(find.byTooltip(l10n.hidePassword), findsOneWidget);
    controller.dispose();
  });

  testWidgets('ошибка поля уходит при исправлении, а не до следующей отправки',
      (tester) async {
    final formKey = GlobalKey<FormState>();
    final first = TextEditingController();
    final second = TextEditingController();
    String? notEmpty(String? value) =>
        (value == null || value.isEmpty) ? 'Заполните поле' : null;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Form(
            key: formKey,
            child: Column(
              children: [
                PasswordField(controller: first, validator: notEmpty),
                PasswordField(controller: second, validator: notEmpty),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('Заполните поле'), findsNothing,
        reason: 'до отправки ошибок нет');

    formKey.currentState!.validate(); // «Сохранить» с пустыми полями
    await tester.pump();
    expect(find.text('Заполните поле'), findsNWidgets(2));

    await tester.enterText(find.byType(TextFormField).first, 'x');
    await tester.pump();
    expect(find.text('Заполните поле'), findsOneWidget,
        reason: 'исправленное поле не ругается, второе ещё не трогали');

    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.pump();
    expect(find.text('Заполните поле'), findsOneWidget,
        reason: 'поле без ошибки не проверяется до следующей отправки');

    first.dispose();
    second.dispose();
  });
  testWidgets('поле проверяется, когда с него уходят, а нетронутое — нет',
      (tester) async {
    final first = TextEditingController();
    final second = TextEditingController();
    String? sixOrMore(String? value) =>
        (value ?? '').length >= 6 ? null : 'Слишком коротко';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: Column(
              children: [
                AppTextFormField(controller: first, validator: sixOrMore),
                AppTextFormField(controller: second, validator: sixOrMore),
              ],
            ),
          ),
        ),
      ),
    );
    final fields = find.byType(TextFormField);

    await tester.enterText(fields.at(0), 'abc');
    await tester.pump();
    expect(find.text('Слишком коротко'), findsNothing,
        reason: 'пока человек печатает, ошибку не показываем');

    await tester.showKeyboard(fields.at(1));
    await tester.pump();
    expect(find.text('Слишком коротко'), findsOneWidget,
        reason: 'ушли с поля, в котором что-то вводили, — проверили');

    await tester.showKeyboard(fields.at(0));
    await tester.pump();
    expect(find.text('Слишком коротко'), findsOneWidget,
        reason: 'пустое нетронутое поле при уходе не ругается');

    await tester.enterText(fields.at(0), 'abcdef');
    await tester.pump();
    expect(find.text('Слишком коротко'), findsNothing,
        reason: 'поле с ошибкой перепроверяется на каждый символ');

    first.dispose();
    second.dispose();
  });

  testWidgets('RequirementList отмечает выполненные пункты для диктора',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RequirementList(
            requirements: [
              Requirement('Выполнено', met: true),
              Requirement('Ещё нет', met: false),
            ],
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.text('Выполнено')),
      isSemantics(hasCheckedState: true, isChecked: true),
    );
    expect(
      tester.getSemantics(find.text('Ещё нет')),
      isSemantics(hasCheckedState: true, isChecked: false),
    );
    semantics.dispose();
  });
}
