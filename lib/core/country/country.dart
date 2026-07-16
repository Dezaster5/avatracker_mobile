import 'package:flutter/foundation.dart';

/// Страна для выбора кода телефона (`GET /api/v1/countries/`).
@immutable
class Country {
  const Country({
    required this.id,
    required this.name,
    required this.isoCode,
    required this.dialCode,
    required this.flagEmoji,
  });

  final int id;
  final String name;
  final String isoCode;
  final String dialCode;
  final String flagEmoji;

  /// Длина национального номера (без кода страны): KZ — 10, UZ — 9.
  int get nationalLength => isoCode == 'UZ' ? 9 : 10;

  /// Группировка цифр национального номера при форматировании.
  List<int> get groups =>
      isoCode == 'UZ' ? const [2, 3, 2, 2] : const [3, 3, 2, 2];

  factory Country.fromJson(Map<String, dynamic> json) {
    final rawDialCode = '${json['dial_code'] ?? '+7'}'.trim();
    return Country(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: '${json['name'] ?? ''}',
      isoCode: '${json['iso_code'] ?? ''}'.toUpperCase(),
      dialCode: rawDialCode.startsWith('+') ? rawDialCode : '+$rawDialCode',
      flagEmoji: '${json['flag_emoji'] ?? ''}',
    );
  }

  /// Резервный список, если `/countries/` недоступен (используется до входа).
  static const List<Country> fallback = [
    Country(
        id: 1,
        name: 'Казахстан',
        isoCode: 'KZ',
        dialCode: '+7',
        flagEmoji: '🇰🇿'),
    Country(
        id: 2,
        name: 'Узбекистан',
        isoCode: 'UZ',
        dialCode: '+998',
        flagEmoji: '🇺🇿'),
  ];

  static Country byIso(String? iso) => fallback.firstWhere(
        (c) => c.isoCode == iso,
        orElse: () => fallback.first,
      );

  @override
  bool operator ==(Object other) =>
      other is Country && other.isoCode == isoCode;

  @override
  int get hashCode => isoCode.hashCode;
}
