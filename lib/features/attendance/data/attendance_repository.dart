import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../domain/analytics.dart';
import '../domain/attendance_marks.dart';
import '../domain/qr_point.dart';
import '../domain/scan_result.dart';

/// Отметки, табель и аналитика посещаемости.
class AttendanceRepository {
  AttendanceRepository({required ApiClient api}) : _dio = api.dio;

  final Dio _dio;

  /// `GET /api/qr/{qr_id}/` — данные точки отметки (для пред-проверки
  /// перед FaceID: существует ли QR и активен ли он).
  Future<QrPoint> qrPoint(String qrId) async {
    try {
      final res = await _dio.get<dynamic>(
        '${AppConfig.coreApiBaseUrl}/qr/$qrId/',
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Неверный формат ответа сервера');
      }
      return QrPoint.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const ApiException(
          message: 'QR-код не зарегистрирован в системе',
          statusCode: 404,
        );
      }
      throw ApiException.fromDio(e);
    }
  }

  /// `POST /api/qr/scan/` — отметка по QR с фото лица (сервер сверяет лицо
  /// с базовым фото сотрудника прямо при скане; отдельного face-verify нет).
  ///
  /// `photo` — JPEG-снимок фронтальной камеры в base64. Антифрод-поля
  /// (`accuracy_meters`, `is_mock_location`) сервер использует для проверок.
  Future<ScanResult> scan({
    required String iin,
    required String qrId,
    required Position position,
    required String photo,
  }) async {
    final body = {
      'iin': iin,
      'qr_id': qrId,
      'employee_latitude': position.latitude,
      'employee_longitude': position.longitude,
      'accuracy_meters': position.accuracy.round(),
      'is_mock_location': position.isMocked,
      'scanned_at': isoWithOffset(DateTime.now()),
      'photo': photo,
    };
    try {
      final res = await _dio.post<dynamic>(
        '${AppConfig.coreApiBaseUrl}/qr/scan/',
        data: body,
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Неверный формат ответа сервера');
      }
      return ScanResult.fromJson(data);
    } on DioException catch (e) {
      // Бизнес-отказы (вне радиуса, QR неактивен, лицо не совпало) приходят
      // с телом — показываем их как результат, а не как сетевую ошибку.
      final data = e.response?.data;
      if (data is Map<String, dynamic> &&
          (data['message'] != null || data['detail'] != null)) {
        return ScanResult.fromJson({
          'success': false,
          'message': data['message'] ?? data['detail'],
          ...data,
        });
      }
      throw ApiException.fromDio(e);
    }
  }

  /// Реальный production endpoint отметок из Swagger:
  /// `GET /api/v1/employee-identification-list/`.
  ///
  /// В ответе нет типа отметки, поэтому UI считает первую отметку дня
  /// приходом, а последнюю (если отметок минимум две) уходом.
  Future<AttendanceMarksMonth> attendanceMarks({
    required String iin,
    required AnalyticsRange range,
  }) async {
    final marks = <AttendanceMark>[];
    var page = 1;
    var hasNext = true;

    try {
      while (hasNext && page <= 20) {
        final res = await _dio.get<dynamic>(
          '/employee-identification-list/',
          queryParameters: {
            'iin': iin,
            'period_from': range.startParam,
            'period_to': range.endExclusiveParam,
            'ordering': 'auth_time',
            'page_size': 100,
            'page': page,
          },
        );
        final data = res.data;
        final List<dynamic> results;
        if (data is Map<String, dynamic>) {
          results = data['results'] is List
              ? data['results'] as List<dynamic>
              : const [];
          final rawNext = data['next']?.toString();
          hasNext = rawNext != null && rawNext.isNotEmpty;
        } else if (data is List) {
          results = data;
          hasNext = false;
        } else {
          throw const ApiException(message: 'Неверный формат ответа сервера');
        }
        marks.addAll(
          results
              .whereType<Map<String, dynamic>>()
              .map(AttendanceMark.fromJson),
        );
        page++;
      }
      return AttendanceMarksMonth.fromMarks(marks);
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
