import '../../../../core/country/country.dart';

/// Страна из `GET /api/v1/countries/`.
final class CountryDto {
  const CountryDto({
    required this.id,
    required this.name,
    required this.isoCode,
    required this.dialCode,
    required this.flagEmoji,
  });

  factory CountryDto.fromJson(Map<String, dynamic> json) {
    final rawDialCode = '${json['dial_code'] ?? '+7'}'.trim();
    return CountryDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: '${json['name'] ?? ''}',
      isoCode: '${json['iso_code'] ?? ''}'.toUpperCase(),
      dialCode: rawDialCode.startsWith('+') ? rawDialCode : '+$rawDialCode',
      flagEmoji: '${json['flag_emoji'] ?? ''}',
    );
  }

  final int id;
  final String name;
  final String isoCode;
  final String dialCode;
  final String flagEmoji;

  Country toEntity() => Country(
        id: id,
        name: name,
        isoCode: isoCode,
        dialCode: dialCode,
        flagEmoji: flagEmoji,
      );
}
