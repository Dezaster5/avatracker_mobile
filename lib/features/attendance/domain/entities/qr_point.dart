import 'dart:convert';

import 'package:flutter/foundation.dart' show immutable;

/// Содержимое QR точки отметки: чистый идентификатор или JSON
/// `{"qr_id": "park_karaganda_..."}` (ТЗ 7.1).
@immutable
final class QrCode {
  const QrCode._(this.id);

  factory QrCode.parse(String raw) {
    final trimmed = raw.trim();
    return QrCode._(_idFromJson(trimmed) ?? trimmed);
  }

  final String id;

  static String? _idFromJson(String value) {
    if (!value.startsWith('{')) return null;
    try {
      final json = jsonDecode(value);
      return json is Map && json['qr_id'] != null ? '${json['qr_id']}' : null;
    } on FormatException {
      return null;
    }
  }
}

/// Точка отметки `GET /api/qr/{qr_id}/`.
@immutable
final class QrPoint {
  const QrPoint({
    required this.qrId,
    required this.isActive,
    this.id,
    this.parkId,
    this.parkName,
    this.latitude,
    this.longitude,
    this.radiusMeters,
  });

  final int? id;
  final String qrId;
  final int? parkId;
  final String? parkName;
  final double? latitude;
  final double? longitude;
  final int? radiusMeters;
  final bool isActive;
}

/// Итог пред-проверки точки перед FaceID.
enum QrPointAvailability {
  available,
  disabled,
  notRegistered,

  /// Проверить не удалось (сеть, формат) — решение примет сама отметка.
  unverified,
}
