import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/analytics_range.dart';
import '../models/analytics_range_query.dart';
import '../models/attendance_mark_dto.dart';
import '../models/qr_point_dto.dart';
import '../models/scan_request.dart';
import '../models/scan_result_dto.dart';
import '../models/tardiness_dto.dart';

/// HTTP-вызовы посещаемости: data-API `/api/v1` и QR-API `/api`.
class AttendanceRemoteDataSource {
  const AttendanceRemoteDataSource(this._dio);

  final Dio _dio;

  static const _pageSize = 100;
  static const _maxPages = 20;

  /// `GET /employee-identification-list/` — отметки периода по страницам.
  Future<List<AttendanceMarkDto>> fetchMarks({
    required String iin,
    required AnalyticsRange range,
  }) async {
    final marks = <AttendanceMarkDto>[];
    var page = 1;
    var hasNext = true;
    while (hasNext && page <= _maxPages) {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.attendanceMarks,
        queryParameters: {
          'iin': iin,
          'period_from': range.attendanceStartParam,
          'period_to': range.attendanceEndParam,
          'ordering': 'auth_time',
          'page_size': _pageSize,
          'page': page,
        },
      );
      final data = response.data;
      final List<dynamic> results;
      if (data is Map<String, dynamic>) {
        results = data['results'] is List ? data['results'] as List : const [];
        final next = data['next']?.toString();
        hasNext = next != null && next.isNotEmpty;
      } else if (data is List) {
        results = data;
        hasNext = false;
      } else {
        throw const InvalidResponseFailure();
      }
      marks.addAll(
        results
            .whereType<Map<String, dynamic>>()
            .map(AttendanceMarkDto.fromJson),
      );
      page++;
    }
    return marks;
  }

  /// `GET /tardiness/?iin=&period_from=&period_to=`.
  Future<TardinessAnalyticsDto> fetchTardiness({
    required String iin,
    required AnalyticsRange range,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.tardiness,
      queryParameters: {
        'iin': iin,
        'period_from': range.startParam,
        'period_to': range.endParam,
      },
    );
    return TardinessAnalyticsDto.fromJson(_map(response.data));
  }

  /// `GET /api/qr/{qr_id}/` — существует ли точка и активна ли она.
  Future<QrPointDto> fetchQrPoint(String qrId) async {
    final response = await _dio.get<dynamic>(ApiEndpoints.qrPoint(qrId));
    return QrPointDto.fromJson(_map(response.data));
  }

  /// `POST /api/qr/scan/`. Бизнес-отказы (вне радиуса, QR неактивен, лицо не
  /// совпало) приходят ошибкой с телом — это результат отметки, а не сбой.
  Future<ScanResultDto> submitMark(ScanRequest request) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.qrScan,
        data: request.toJson(),
      );
      return ScanResultDto.fromJson(_map(response.data));
    } on DioException catch (error) {
      final rejection = _businessRejection(error.response?.data);
      if (rejection == null) rethrow;
      return ScanResultDto.fromJson(rejection);
    }
  }

  static Map<String, dynamic>? _businessRejection(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    // Отклонённый токен — это не отказ в отметке; сессией займётся ApiClient.
    if (data['code'] == 'token_not_valid') return null;
    final message = data['message'] ?? data['detail'];
    if (message == null) return null;
    return {'success': false, 'message': message, ...data};
  }

  static Map<String, dynamic> _map(dynamic data) {
    if (data is! Map<String, dynamic>) throw const InvalidResponseFailure();
    return data;
  }
}
