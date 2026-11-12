import 'package:avatracker_mobile/features/attendance/presentation/screens/timesheet_screen.dart';
import 'package:avatracker_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'attendance_test_doubles.dart';

void main() {
  testWidgets('стрелки месяца — отдельные кнопки с названием для диктора',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final l10n = lookupAppLocalizations(const Locale('ru'));
    await tester.pumpWidget(
      attendanceTestApp(
        repository: FakeAttendanceRepository(),
        home: const TimesheetScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Открыт текущий месяц: назад листать можно, вперёд — нет. Заголовок
    // месяца не приклеивается к стрелке (label пустой, имя — в tooltip).
    expect(
      tester.getSemantics(find.byTooltip(l10n.previousPeriod)),
      isSemantics(
        label: '',
        isButton: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.byTooltip(l10n.nextPeriod)),
      isSemantics(
        label: '',
        isButton: true,
        isEnabled: false,
        hasTapAction: false,
      ),
    );
    semantics.dispose();
  });
}
