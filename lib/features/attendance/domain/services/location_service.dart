import '../../../../core/error/result.dart';
import '../entities/geo_position.dart';

/// Источник координат устройства.
abstract interface class LocationService {
  /// Текущие координаты. Если геолокация выключена, нет разрешения или
  /// координаты не получены — `LocationFailure`.
  Future<Result<GeoPosition>> currentPosition();
}
