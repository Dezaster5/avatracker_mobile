import 'mark_types.dart';

/// Результат отметки `POST /api/v1/mobile/attendance/scan` (ТЗ 13.6, 27, 28).
class ScanResult {
  const ScanResult({
    required this.success,
    required this.message,
    this.markType,
    this.distanceMeters,
    this.allowedRadius,
    this.park,
    this.scannedAt,
    this.errorCode,
  });

  final bool success;
  final String message;
  final String? markType;
  final int? distanceMeters;
  final int? allowedRadius;
  final String? park;
  final DateTime? scannedAt;
  final String? errorCode;

  String get markTypeLabelRu => markTypeLabel(markType);

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    final success = json['success'] == true;
    return ScanResult(
      success: success,
      message: json['message']?.toString() ??
          (success ? 'Отметка успешно засчитана' : 'Отметка не засчитана'),
      markType: json['mark_type']?.toString(),
      distanceMeters: (json['distance_meters'] as num?)?.toInt(),
      allowedRadius: (json['allowed_radius'] as num?)?.toInt(),
      park: json['park']?.toString(),
      scannedAt: DateTime.tryParse('${json['scanned_at'] ?? ''}'),
      errorCode: json['error_code']?.toString(),
    );
  }

  factory ScanResult.failure(String message, {String? errorCode}) =>
      ScanResult(success: false, message: message, errorCode: errorCode);
}
