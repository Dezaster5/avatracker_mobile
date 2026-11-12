import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/geo_position.dart';
import '../services/location_service.dart';

/// Координаты для отметки с проверками ТЗ 17: без геолокации отметка
/// запрещена, подменённые координаты и точность хуже 50 м отклоняются.
final class GetVerifiedPosition {
  const GetVerifiedPosition(this._location);

  static const maxAccuracyMeters = 50.0;

  final LocationService _location;

  Future<Result<GeoPosition>> call() async {
    final result = await _location.currentPosition();
    if (result case Success(value: final position)) {
      if (position.isMocked) {
        return Failed(const LocationFailure(LocationFailureCode.mocked));
      }
      if (position.accuracyMeters > maxAccuracyMeters) {
        return Failed(
          LocationFailure(
            LocationFailureCode.lowAccuracy,
            accuracyMeters: position.accuracyMeters.round(),
          ),
        );
      }
    }
    return result;
  }
}
