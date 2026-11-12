import 'package:avatracker_mobile/core/error/failure.dart';
import 'package:avatracker_mobile/core/error/result.dart';
import 'package:avatracker_mobile/features/attendance/di/attendance_providers.dart';
import 'package:avatracker_mobile/features/attendance/domain/entities/analytics_range.dart';
import 'package:avatracker_mobile/features/attendance/domain/entities/attendance_mark.dart';
import 'package:avatracker_mobile/features/attendance/domain/entities/geo_position.dart';
import 'package:avatracker_mobile/features/attendance/domain/entities/qr_point.dart';
import 'package:avatracker_mobile/features/attendance/domain/entities/scan_result.dart';
import 'package:avatracker_mobile/features/attendance/domain/entities/tardiness.dart';
import 'package:avatracker_mobile/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:avatracker_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:avatracker_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/fake_auth_repository.dart' show activeEmployee;

/// Отметки для экранов табеля и аналитики: первые [failingMarksCalls]
/// загрузок падают без сети, остальные возвращают пустой месяц.
class FakeAttendanceRepository implements AttendanceRepository {
  FakeAttendanceRepository({this.failingMarksCalls = 0});

  final int failingMarksCalls;
  int marksCalls = 0;

  @override
  Future<Result<AttendanceMarksMonth>> marks({
    required String iin,
    required AnalyticsRange range,
  }) async {
    marksCalls++;
    if (marksCalls <= failingMarksCalls) return const Failed(NetworkFailure());
    return Success(AttendanceMarksMonth.fromMarks(const []));
  }

  @override
  Future<Result<TardinessAnalytics>> tardiness({
    required String iin,
    required AnalyticsRange range,
  }) async =>
      Success(
        TardinessAnalytics(
          range: range,
          scheduleStart: null,
          count: 0,
          maxTardiness: 0,
          avgTardiness: 0,
          results: const [],
        ),
      );

  @override
  Future<Result<QrPoint>> qrPoint(String qrId) => throw UnimplementedError();

  @override
  Future<Result<ScanResult>> submitMark({
    required String iin,
    required String qrId,
    required GeoPosition position,
    required String photo,
  }) =>
      throw UnimplementedError();
}

class _SignedInAuthController extends AuthController {
  @override
  AuthSession build() => const AuthSession.authenticated(activeEmployee);
}

/// Экран вкладки с вошедшим сотрудником, русской локалью и [repository].
Widget attendanceTestApp({
  required AttendanceRepository repository,
  required Widget home,
}) =>
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_SignedInAuthController.new),
        attendanceRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );
