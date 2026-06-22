import 'package:geolocator/geolocator.dart';

import '../config/app_config.dart';

enum LocationSettingsAction { none, appSettings, locationSettings }

/// Ошибка получения/валидации геолокации с текстом по ТЗ (7.4, 17).
class LocationFailure implements Exception {
  const LocationFailure(this.message,
      {this.settings = LocationSettingsAction.none});

  final String message;
  final LocationSettingsAction settings;

  @override
  String toString() => message;
}

/// Получение координат с обязательными проверками из ТЗ, раздел 17:
/// сервис включен, разрешение выдано, координаты не подменены (mock),
/// точность GPS не хуже 50 метров.
class LocationService {
  Future<Position> getValidatedPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationFailure(
        'Включите геолокацию (GPS) на устройстве',
        settings: LocationSettingsAction.locationSettings,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailure('Разрешите доступ к геолокации для отметки');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        'Разрешите доступ к геолокации для отметки',
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
        'Не удалось определить геолокацию. Попробуйте еще раз',
      );
    }

    if (position.isMocked) {
      throw const LocationFailure(
        'Обнаружена поддельная геолокация. Отметка запрещена',
      );
    }
    if (position.accuracy > AppConfig.maxGpsAccuracyMeters) {
      throw LocationFailure(
        'Низкая точность GPS (±${position.accuracy.round()} м). '
        'Выйдите на открытое место и попробуйте снова',
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
