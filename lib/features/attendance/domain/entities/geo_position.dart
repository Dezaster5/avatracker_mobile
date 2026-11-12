import 'package:flutter/foundation.dart' show immutable;

/// Координаты устройства с признаками для антифрод-проверок.
@immutable
final class GeoPosition {
  const GeoPosition({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.isMocked,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;

  /// Координаты подменены (mock location).
  final bool isMocked;
}
