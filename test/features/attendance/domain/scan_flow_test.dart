import 'package:avatracker_mobile/core/error/failure.dart';
import 'package:avatracker_mobile/core/error/result.dart';
import 'package:avatracker_mobile/features/attendance/domain/entities/analytics_range.dart';
import 'package:avatracker_mobile/features/attendance/domain/entities/attendance_mark.dart';
import 'package:avatracker_mobile/features/attendance/domain/entities/geo_position.dart';
import 'package:avatracker_mobile/features/attendance/domain/entities/qr_point.dart';
import 'package:avatracker_mobile/features/attendance/domain/entities/scan_result.dart';
import 'package:avatracker_mobile/features/attendance/domain/entities/tardiness.dart';
import 'package:avatracker_mobile/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:avatracker_mobile/features/attendance/domain/services/location_service.dart';
import 'package:avatracker_mobile/features/attendance/domain/usecases/check_qr_point.dart';
import 'package:avatracker_mobile/features/attendance/domain/usecases/get_attendance_overview.dart';
import 'package:avatracker_mobile/features/attendance/domain/usecases/get_verified_position.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAttendanceRepository implements AttendanceRepository {
  _FakeAttendanceRepository({
    this.point = const Success(QrPoint(qrId: 'p1', isActive: true)),
    Result<AttendanceMarksMonth>? marks,
    Result<TardinessAnalytics>? tardiness,
  })  : marksResult = marks ?? Success(AttendanceMarksMonth.fromMarks([])),
        tardinessResult = tardiness ?? Success(_emptyTardiness);

  final Result<QrPoint> point;
  final Result<AttendanceMarksMonth> marksResult;
  final Result<TardinessAnalytics> tardinessResult;

  @override
  Future<Result<QrPoint>> qrPoint(String qrId) async => point;

  @override
  Future<Result<AttendanceMarksMonth>> marks({
    required String iin,
    required AnalyticsRange range,
  }) async =>
      marksResult;

  @override
  Future<Result<TardinessAnalytics>> tardiness({
    required String iin,
    required AnalyticsRange range,
  }) async =>
      tardinessResult;

  @override
  Future<Result<ScanResult>> submitMark({
    required String iin,
    required String qrId,
    required GeoPosition position,
    required String photo,
  }) =>
      throw UnimplementedError();
}

class _FakeLocation implements LocationService {
  _FakeLocation(this.result);

  final Result<GeoPosition> result;

  @override
  Future<Result<GeoPosition>> currentPosition() async => result;
}

final _range = AnalyticsRange.month(DateTime(2026, 8));
final _emptyTardiness = TardinessAnalytics(
  range: _range,
  scheduleStart: null,
  count: 0,
  maxTardiness: 0,
  avgTardiness: 0,
  results: const [],
);

GeoPosition _position({double accuracy = 10, bool mocked = false}) =>
    GeoPosition(
      latitude: 49.8,
      longitude: 73.1,
      accuracyMeters: accuracy,
      isMocked: mocked,
    );

void main() {
  group('QrCode', () {
    test('чистый идентификатор или JSON с qr_id', () {
      expect(QrCode.parse('  park_karaganda_1 ').id, 'park_karaganda_1');
      expect(QrCode.parse('{"qr_id": "park_2"}').id, 'park_2');
      expect(QrCode.parse('{"id": 3}').id, '{"id": 3}');
      expect(QrCode.parse('{не json').id, '{не json');
    });
  });

  group('CheckQrPoint', () {
    Future<QrPointAvailability> check(Result<QrPoint> point) =>
        CheckQrPoint(_FakeAttendanceRepository(point: point)).call('p1');

    test('блокирует только отключённую и незарегистрированную точку', () async {
      expect(
        await check(const Success(QrPoint(qrId: 'p1', isActive: true))),
        QrPointAvailability.available,
      );
      expect(
        await check(const Success(QrPoint(qrId: 'p1', isActive: false))),
        QrPointAvailability.disabled,
      );
      expect(
        await check(const Failed(NotFoundFailure())),
        QrPointAvailability.notRegistered,
      );
      expect(
        await check(const Failed(NetworkFailure())),
        QrPointAvailability.unverified,
      );
    });
  });

  group('GetVerifiedPosition', () {
    Future<Result<GeoPosition>> verify(Result<GeoPosition> raw) =>
        GetVerifiedPosition(_FakeLocation(raw)).call();

    test('подменённые координаты отклоняются', () async {
      final result = await verify(Success(_position(mocked: true)));
      final failure = (result as Failed).failure as LocationFailure;
      expect(failure.code, LocationFailureCode.mocked);
    });

    test('точность хуже 50 м отклоняется с фактической точностью', () async {
      final result = await verify(Success(_position(accuracy: 50.6)));
      final failure = (result as Failed).failure as LocationFailure;
      expect(failure.code, LocationFailureCode.lowAccuracy);
      expect(failure.accuracyMeters, 51);
    });

    test('корректные координаты и ошибки доступа проходят как есть', () async {
      final position = _position(accuracy: 50);
      expect((await verify(Success(position)) as Success).value, position);

      const denied = LocationFailure(
        LocationFailureCode.permissionDenied,
        settings: LocationSettingsAction.appSettings,
      );
      expect((await verify(const Failed(denied)) as Failed).failure, denied);
    });
  });

  group('GetAttendanceOverview', () {
    test('ошибка отметок приоритетнее ошибки опозданий', () async {
      final overview = GetAttendanceOverview(
        _FakeAttendanceRepository(
          marks: const Failed(TimeoutFailure()),
          tardiness: const Failed(ServerFailure()),
        ),
      );
      final result = await overview(iin: '1', range: _range);
      expect((result as Failed).failure, isA<TimeoutFailure>());
    });

    test('ошибка опозданий не теряется', () async {
      final overview = GetAttendanceOverview(
        _FakeAttendanceRepository(tardiness: const Failed(ServerFailure())),
      );
      final result = await overview(iin: '1', range: _range);
      expect((result as Failed).failure, isA<ServerFailure>());
    });

    test('успешная загрузка собирает табель', () async {
      final result = await GetAttendanceOverview(_FakeAttendanceRepository())(
        iin: '1',
        range: _range,
      );
      expect((result as Success).value.lateDates, isEmpty);
    });
  });
}
