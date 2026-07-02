import 'package:geolocator/geolocator.dart';

import '../config/app_config.dart';

enum LocationSettingsAction { none, appSettings, locationSettings }

enum LocationFailureCode {
  serviceDisabled,
  permissionDenied,
  unavailable,
  mocked,
  lowAccuracy,
}

/// Ошибка получения/валидации геолокации с машинным кодом для локализации UI.
class LocationFailure implements Exception {
  const LocationFailure(
    this.code, {
    this.settings = LocationSettingsAction.none,
    this.accuracyMeters,
  });

  final LocationFailureCode code;
  final LocationSettingsAction settings;
  final int? accuracyMeters;

  @override
  String toString() => code.name;
}

/// Получение координат с обязательными проверками из ТЗ, раздел 17:
/// сервис включен, разрешение выдано, координаты не подменены (mock),
/// точность GPS не хуже 50 метров.
class LocationService {
  Future<Position> getValidatedPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationFailure(
        LocationFailureCode.serviceDisabled,
        settings: LocationSettingsAction.locationSettings,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailure(LocationFailureCode.permissionDenied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        LocationFailureCode.permissionDenied,
        settings: LocationSettingsAction.appSettings,
      );
    }

    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: AppConfig.locationTimeout,
        ),
      );
    } on Exception {
      throw const LocationFailure(
        LocationFailureCode.unavailable,
      );
    }

    if (position.isMocked) {
      throw const LocationFailure(
        LocationFailureCode.mocked,
      );
    }
    if (position.accuracy > AppConfig.maxGpsAccuracyMeters) {
      throw LocationFailure(
        LocationFailureCode.lowAccuracy,
        accuracyMeters: position.accuracy.round(),
      );
    }
    return position;
  }

  Future<void> openSettings(LocationSettingsAction action) async {
    switch (action) {
      case LocationSettingsAction.appSettings:
        await Geolocator.openAppSettings();
      case LocationSettingsAction.locationSettings:
        await Geolocator.openLocationSettings();
      case LocationSettingsAction.none:
        break;
    }
  }
}
