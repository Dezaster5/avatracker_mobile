import 'package:avatracker_mobile/features/attendance/presentation/screens/analytics_screen.dart';
import 'package:avatracker_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'attendance_test_doubles.dart';

void main() {
  testWidgets('«Повторить» в аналитике заново загружает данные с сервера',
      (tester) async {
    final repository = FakeAttendanceRepository(failingMarksCalls: 1);
    final l10n = lookupAppLocalizations(const Locale('ru'));
    await tester.pumpWidget(
      attendanceTestApp(
        repository: repository,
        home: const AnalyticsScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.errorConnection), findsOneWidget);

    await tester.tap(find.text(l10n.actionRetry));
    await tester.pumpAndSettle();

    expect(repository.marksCalls, 2);
    expect(find.text(l10n.actionRetry), findsNothing);
  });
}
