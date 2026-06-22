import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avatracker_mobile/core/widgets/password_field.dart';
import 'package:avatracker_mobile/core/widgets/pin_code_field.dart';
import 'package:avatracker_mobile/core/widgets/primary_button.dart';
import 'package:avatracker_mobile/core/widgets/status_chip.dart';

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

  testWidgets('PasswordField скрывает и показывает пароль', (tester) async {
    final controller = TextEditingController(text: 'secret1');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PasswordField(controller: controller)),
      ),
    );
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    controller.dispose();
  });
}
