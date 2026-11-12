import '../../../../core/utils/json_values.dart';
import '../../domain/entities/scan_result.dart';

/// Ответ `POST /api/qr/scan/` — и успешный, и бизнес-отказ.
final class ScanResultDto {
  const ScanResultDto({
    required this.success,
    this.message,
    this.markType,
    this.distanceMeters,
    this.allowedRadius,
    this.park,
    this.scannedAt,
    this.errorCode,
  });

  factory ScanResultDto.fromJson(Map<String, dynamic> json) => ScanResultDto(
        success: json['success'] == true,
        message: json['message']?.toString(),
        markType: json['mark_type']?.toString(),
        distanceMeters: jsonInt(json['distance_meters']),
        allowedRadius: jsonInt(json['allowed_radius']),
        park: json['park']?.toString(),
        scannedAt: DateTime.tryParse('${json['scanned_at'] ?? ''}'),
        errorCode: json['error_code']?.toString(),
      );

  final bool success;
  final String? message;
  final String? markType;
  final int? distanceMeters;
  final int? allowedRadius;
  final String? park;
  final DateTime? scannedAt;
  final String? errorCode;

  ScanResult toEntity() => ScanResult(
        success: success,
        message: message,
        markType: MarkType.fromApi(markType),
        distanceMeters: distanceMeters,
        allowedRadius: allowedRadius,
        park: park,
        scannedAt: scannedAt,
        errorCode: errorCode,
      );
}
