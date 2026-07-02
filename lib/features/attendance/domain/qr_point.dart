/// Точка отметки `GET /api/qr/{qr_id}/`.
class QrPoint {
  const QrPoint({
    required this.qrId,
    this.id,
    this.parkId,
    this.parkName,
    this.latitude,
    this.longitude,
    this.radiusMeters,
    required this.isActive,
  });

  final int? id;
  final String qrId;
  final int? parkId;
  final String? parkName;
  final double? latitude;
  final double? longitude;
  final int? radiusMeters;
  final bool isActive;

  static double? _double(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('${v ?? ''}');

  static int? _int(dynamic v) =>
      v is num ? v.toInt() : int.tryParse('${v ?? ''}');

  factory QrPoint.fromJson(Map<String, dynamic> json) {
    final active = json['is_active'] ?? json['active'];
    return QrPoint(
      id: _int(json['id']),
      qrId: '${json['qr_id'] ?? json['id'] ?? ''}',
      parkId: _int(json['park_id']),
      parkName: (json['park_name'] ?? json['park'])?.toString(),
      latitude: _double(json['latitude']),
      longitude: _double(json['longitude']),
      radiusMeters: _int(json['radius_meters'] ?? json['allowed_radius']),
      // По умолчанию считаем точку активной, если поле не пришло.
      isActive: active is bool ? active : '$active'.toLowerCase() != 'false',
    );
  }
}
