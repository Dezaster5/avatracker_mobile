import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../domain/analytics.dart';
import '../domain/scan_result.dart';
import '../domain/timesheet.dart';

/// Отметки, табель и аналитика посещаемости.
class AttendanceRepository {
  AttendanceRepository({required ApiClient api}) : _dio = api.dio;

  final Dio _dio;

  /// `POST /mobile/attendance/scan` (ТЗ 13.6).
  ///
  /// Дополнительно к ТЗ передаём точность GPS и флаг mock-локации —
  /// сервер использует их для антифрод-логики (ТЗ 17).
  Future<ScanResult> scan({
    required String iin,
    required String qrId,
    required Position position,
    required String faceVerificationToken,
  }) async {
    final body = {
      'iin': iin,
      'qr_id': qrId,
      'employee_latitude': position.latitude,
      'employee_longitude': position.longitude,
      'accuracy_meters': position.accuracy.round(),
      'is_mock_location': position.isMocked,
      'face_verification_token': faceVerificationToken,
      'scanned_at': isoWithOffset(DateTime.now()),
    };
    try {
      final res =
          await _dio.post<dynamic>('/mobile/attendance/scan', data: body);
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Неверный формат ответа сервера');
      }
      return ScanResult.fromJson(data);
    } on DioException catch (e) {
      // Бизнес-отказы (вне радиуса, QR неактивен и т.п.) приходят с телом
      // по ТЗ 28 — показываем их как результат, а не как сетевую ошибку.
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['message'] != null) {
        return ScanResult.fromJson(data);
      }
      throw ApiException.fromDio(e);
    }
  }

  /// `GET /mobile/attendance/timesheet` (ТЗ 13.7).
  Future<TimesheetMonth> timesheet({
    required String iin,
    required String month,
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        '/mobile/attendance/timesheet',
        queryParameters: {'iin': iin, 'month': month},
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Неверный формат ответа сервера');
      }
      return TimesheetMonth.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// `GET /tardiness/?iin={iin}&period_from={yyyy-MM-dd}&period_to={yyyy-MM-dd}`.
  Future<TardinessAnalytics> tardiness({
    required String iin,
    required AnalyticsRange range,
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        '/tardiness/',
        queryParameters: {
          'iin': iin,
          'period_from': range.startParam,
          'period_to': range.endParam,
        },
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Неверный формат ответа сервера');
      }
      return TardinessAnalytics.fromJson(range, data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
