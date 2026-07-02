/// Сотрудник из AvaTracker (`GET /api/v1/employees/{iin}`).
///
/// Парсинг устойчив к разным формам ответа: backend может вернуть название
/// отдельным `*_name`, объектом `{name: ...}` или строкой. UUID не показываем
/// как текстовое значение профиля.
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
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty || _looksLikeUuid(text)) return null;
      return text;
    }
    if (value is Map) {
      final name = value['name'] ?? value['title'] ?? value['full_name'];
      return _name(name);
    }
    return _name(value.toString());
  }

  static bool _looksLikeUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  static int? _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}');
  }

  /// Активность сотрудника. Явный `false` блокирует доступ; отсутствие поля
  /// считаем активным — мобильный API (`/auth/login/`, `/profile/me/`) не
  /// присылает `active`, а сам факт входа уже подтверждает доступ.
  static bool _activeFrom(dynamic value) {
    if (value is bool) return value;
    if (value == null) return true;
    final s = '$value'.trim().toLowerCase();
    return !(s == 'false' || s == '0' || s == 'no' || s == 'inactive');
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    final dynamic photo = json['photo'] ?? json['photo_url'];
    return Employee(
      id: _int(json['id']),
      iin: '${json['iin'] ?? ''}',
      fullName: '${json['full_name'] ?? json['fullName'] ?? ''}',
      active: _activeFrom(json['active'] ?? json['is_active']),
      photoUrl: photo?.toString(),
      phone: json['phone']?.toString(),
      position: _name(
        json['position_name'] ?? json['job_title'] ?? json['position'],
      ),
      division: _name(
        json['division_name'] ??
            json['department_name'] ??
            json['division'] ??
            json['department'],
      ),
      organization: _name(
        json['organization_name'] ??
            json['employee_organization_name'] ??
            json['employee_organization'] ??
            json['organization'],
      ),
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
