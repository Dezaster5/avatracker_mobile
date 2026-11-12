import '../../../../core/utils/json_values.dart';
import '../../domain/entities/qr_point.dart';

/// Точка отметки `GET /api/qr/{qr_id}/`.
final class QrPointDto {
  const QrPointDto({
    required this.qrId,
    required this.isActive,
    this.id,
    this.parkId,
    this.parkName,
    this.latitude,
    this.longitude,
    this.radiusMeters,
  });

  factory QrPointDto.fromJson(Map<String, dynamic> json) {
    final active = json['is_active'] ?? json['active'];
    return QrPointDto(
      id: jsonInt(json['id']),
      qrId: '${json['qr_id'] ?? json['id'] ?? ''}',
      parkId: jsonInt(json['park_id']),
      parkName: (json['park_name'] ?? json['park'])?.toString(),
      latitude: jsonDouble(json['latitude']),
      longitude: jsonDouble(json['longitude']),
      radiusMeters: jsonInt(json['radius_meters'] ?? json['allowed_radius']),
      // Если поле не пришло, точка считается активной.
      isActive: active is bool ? active : '$active'.toLowerCase() != 'false',
    );
  }

  final int? id;
  final String qrId;
  final int? parkId;
  final String? parkName;
  final double? latitude;
  final double? longitude;
  final int? radiusMeters;
  final bool isActive;

  QrPoint toEntity() => QrPoint(
        id: id,
        qrId: qrId,
        parkId: parkId,
        parkName: parkName,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        isActive: isActive,
      );
}
