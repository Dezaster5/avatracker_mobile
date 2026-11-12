import 'package:flutter/foundation.dart' show immutable;

/// Тип засчитанной отметки (ТЗ 8).
enum MarkType {
  checkIn,
  checkOut,
  presence,
  other;

  static MarkType? fromApi(String? value) => switch (value) {
        null => null,
        'check_in' => checkIn,
        'check_out' => checkOut,
        'presence' => presence,
        _ => other,
      };
}

/// Результат отметки `POST /api/qr/scan/` (ТЗ 13.6, 27, 28): засчитана или
/// отклонена по бизнес-правилу (вне радиуса, лицо не совпало и т. п.).
@immutable
final class ScanResult {
  const ScanResult({
    required this.success,
    this.message,
    this.markType,
    this.distanceMeters,
    this.allowedRadius,
    this.park,
    this.scannedAt,
    this.errorCode,
  });

  final bool success;

  /// Текст сервера; без него показывается стандартный текст результата.
  final String? message;
  final MarkType? markType;
  final int? distanceMeters;
  final int? allowedRadius;
  final String? park;
  final DateTime? scannedAt;

  /// Машинный код отказа, например `OUT_OF_RADIUS`.
  final String? errorCode;
}
