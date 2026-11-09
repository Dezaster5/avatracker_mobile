import '../../../../core/utils/date_formatters.dart';
import '../../domain/entities/geo_position.dart';

/// Тело `POST /api/qr/scan/`. `photo` — JPEG фронтальной камеры в base64;
/// антифрод-поля (`accuracy_meters`, `is_mock_location`) сервер использует
/// для проверок.
final class ScanRequest {
  const ScanRequest({
    required this.iin,
    required this.qrId,
    required this.position,
    required this.photo,
    required this.scannedAt,
  });

  final String iin;
  final String qrId;
  final GeoPosition position;
  final String photo;
  final DateTime scannedAt;

  Map<String, dynamic> toJson() => {
        'iin': iin,
        'qr_id': qrId,
        'employee_latitude': position.latitude,
        'employee_longitude': position.longitude,
        'accuracy_meters': position.accuracyMeters.round(),
        'is_mock_location': position.isMocked,
        'scanned_at': isoWithOffset(scannedAt),
        'photo': photo,
      };
}
