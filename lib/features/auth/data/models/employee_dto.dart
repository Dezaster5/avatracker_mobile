import '../../../../core/time/clock_time.dart';
import '../../../../core/utils/json_values.dart';
import '../../domain/entities/employee.dart';

/// Сотрудник из `/profile/me/`, `/employees/{iin}/` и ответов входа.
///
/// Парсинг устойчив к разным формам ответа: backend может вернуть название
/// отдельным `*_name`, объектом `{name: ...}` или строкой. UUID как текстовое
/// значение профиля не показываем. [toJson] — формат локального кеша.
final class EmployeeDto {
  const EmployeeDto({
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
    this.scheduleName,
    this.scheduleStartTime,
    this.scheduleEndTime,
  });

  factory EmployeeDto.fromJson(Map<String, dynamic> json) {
    final dynamic photo = json['photo'] ?? json['photo_url'];
    return EmployeeDto(
      id: jsonInt(json['id']),
      iin: '${json['iin'] ?? ''}',
      fullName: _fullName(json['full_name'] ?? json['fullName']),
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
      parkId: jsonInt(json['park_id'] ?? json['park']),
      parkName: _name(json['park_name']) ??
          (json['park'] is Map ? _name(json['park']) : null),
      city: json['city']?.toString(),
      scheduleName: _name(json['schedule_name'] ?? json['schedule_title']),
      scheduleStartTime: ClockTime.tryParse(
        json['schedule_start_time'] ?? json['schedule_start'],
      )?.label,
      scheduleEndTime: ClockTime.tryParse(
        json['schedule_end_time'] ?? json['schedule_end'],
      )?.label,
    );
  }

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
  final String? scheduleName;

  /// Нормализованное `HH:mm`.
  final String? scheduleStartTime;
  final String? scheduleEndTime;

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
        'schedule_name': scheduleName,
        'schedule_start_time': scheduleStartTime,
        'schedule_end_time': scheduleEndTime,
      };

  Employee toEntity() => Employee(
        id: id,
        iin: iin,
        fullName: fullName,
        active: active,
        photoUrl: photoUrl,
        phone: phone,
        position: position,
        division: division,
        organization: organization,
        parkId: parkId,
        parkName: parkName,
        city: city,
        scheduleName: scheduleName,
        scheduleStart: ClockTime.tryParse(scheduleStartTime),
        scheduleEnd: ClockTime.tryParse(scheduleEndTime),
      );

  /// Есть ли в ответе график — иначе его дополняет поиск по `/employees/`.
  static bool hasSchedule(Map<String, dynamic> json) =>
      '${json['schedule_start_time'] ?? ''}'.isNotEmpty &&
      '${json['schedule_end_time'] ?? ''}'.isNotEmpty;

  /// В базе ФИО встречается с лишними пробелами («Иванова  Анна»): на экране
  /// это заметно, поэтому пробелы схлопываются при разборе ответа.
  static String _fullName(dynamic value) =>
      '${value ?? ''}'.trim().replaceAll(_spaces, ' ');

  static final _spaces = RegExp(r'\s+');

  static String? _name(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty || _uuid.hasMatch(text)) return null;
      return text;
    }
    if (value is Map) {
      return _name(value['name'] ?? value['title'] ?? value['full_name']);
    }
    return _name(value.toString());
  }

  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Явный `false` блокирует доступ; отсутствие поля считаем активным —
  /// мобильный API (`/auth/login/`, `/profile/me/`) не присылает `active`, а
  /// сам факт входа уже подтверждает доступ.
  static bool _activeFrom(dynamic value) {
    if (value is bool) return value;
    if (value == null) return true;
    final text = '$value'.trim().toLowerCase();
    return !(text == 'false' ||
        text == '0' ||
        text == 'no' ||
        text == 'inactive');
  }
}
