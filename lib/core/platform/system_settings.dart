import 'package:geolocator/geolocator.dart';

/// Переход в системные настройки, когда не выдано разрешение на камеру
/// или выключена геолокация.
class SystemSettings {
  const SystemSettings();

  Future<void> openAppSettings() => Geolocator.openAppSettings();

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
