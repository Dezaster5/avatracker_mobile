/// Сотрудник из AvaTracker (`GET /api/v1/employees/{iin}`).
///
/// Парсинг устойчив к разным формам ответа: `position` / `division` /
/// `employee_organization` могут приходить строкой или объектом `{name: ...}`.
class Employee {
  const Employee({
    required this.iin,
    required this.fullName,
    required this.active,
    this.id,
    this.photoUrl,
    this.phone,
    this.position,
    this.division,
    this.organization,
    this.parkId,
    this.parkName,
    this.city,
  });

  final int? id;
  final String iin;
  final String fullName;
  final bool active;
  final String? photoUrl;
  final String? phone;
  final String? position;
  final String? division;
  final String? organization;
  final int? parkId;
  final String? parkName;
  final String? city;

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  /// «Иванов Иван Иванович» -> «Иван».
  String get firstName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.length > 1 ? parts[1] : fullName;
  }

  static String? _name(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    if (value is Map) {
      final name = value['name'] ?? value['title'] ?? value['full_name'];
      return name?.toString();
    }
    return value.toString();
  }

  static int? _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}');
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    final dynamic active = json['active'] ?? json['is_active'];
    final dynamic photo = json['photo'] ?? json['photo_url'];
    return Employee(
      id: _int(json['id']),
      iin: '${json['iin'] ?? ''}',
      fullName: '${json['full_name'] ?? json['fullName'] ?? ''}',
      active: active is bool ? active : '$active'.toLowerCase() == 'true',
      photoUrl: photo?.toString(),
      phone: json['phone']?.toString(),
      position: _name(json['position']),
      division: _name(json['division'] ?? json['department']),
      organization:
          _name(json['employee_organization'] ?? json['organization']),
      parkId: _int(json['park_id'] ?? json['park']),
      parkName: _name(json['park_name']) ??
          (json['park'] is Map ? _name(json['park']) : null),
      city: json['city']?.toString(),
    );
  }

  /// Для локального кеша профиля.
  Map<String, dynamic> toJson() => {
        'id': id,
        'iin': iin,
        'full_name': fullName,
        'active': active,
        'photo': photoUrl,
        'phone': phone,
        'position': position,
        'division': division,
        'employee_organization': organization,
        'park_id': parkId,
        'park_name': parkName,
        'city': city,
      };
}
