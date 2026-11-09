import 'package:geolocator/geolocator.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/geo_position.dart';
import '../../domain/services/location_service.dart';

/// Координаты через `geolocator`: сервис включён, разрешение выдано.
/// Проверки подмены и точности — в domain (`GetVerifiedPosition`).
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<Result<GeoPosition>> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return Failed(
        const LocationFailure(
          LocationFailureCode.serviceDisabled,
          settings: LocationSettingsAction.locationSettings,
        ),
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return Failed(
        const LocationFailure(LocationFailureCode.permissionDenied),
      );
    }
    if (permission == LocationPermission.deniedForever) {
      return Failed(
        const LocationFailure(
          LocationFailureCode.permissionDenied,
          settings: LocationSettingsAction.appSettings,
        ),
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: AppConfig.locationTimeout,
        ),
      );
      return Success(
        GeoPosition(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyMeters: position.accuracy,
          isMocked: position.isMocked,
        ),
      );
    } on Exception {
      return Failed(const LocationFailure(LocationFailureCode.unavailable));
    }
  }
}
