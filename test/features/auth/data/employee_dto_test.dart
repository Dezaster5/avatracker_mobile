import 'package:avatracker_mobile/features/auth/data/models/employee_dto.dart';
import 'package:avatracker_mobile/features/auth/domain/entities/employee.dart';
import 'package:flutter_test/flutter_test.dart';

Employee _parse(Map<String, dynamic> json) =>
    EmployeeDto.fromJson(json).toEntity();

void main() {
  group('EmployeeDto', () {
    test('вложенные объекты position/division/organization', () {
      final employee = _parse({
        'id': 1,
        'iin': '642918307154',
        'full_name': 'Иванов Иван Иванович',
        'photo': 'https://example.com/photo.jpg',
        'active': true,
        'phone': '+77001234567',
        'position': {'name': 'Инженер'},
        'division': {'name': 'IT отдел'},
        'employee_organization': {'name': 'ТОО Аватария'},
        'park_id': 5000011,
        'schedule_name': '5/2',
        'schedule_start_time': '09:00:00',
        'schedule_end_time': '18:00:00',
      });
      expect(employee.iin, '642918307154');
      expect(employee.position, 'Инженер');
      expect(employee.division, 'IT отдел');
      expect(employee.organization, 'ТОО Аватария');
      expect(employee.parkId, 5000011);
      expect(employee.hasPhoto, isTrue);
      expect(employee.firstName, 'Иван');
      expect(employee.scheduleName, '5/2');
      expect(employee.scheduleStart?.label, '09:00');
      expect(employee.scheduleRangeLabel, '09:00-18:00');
    });

    test('плоские строковые поля и active-строка', () {
      final employee = _parse({
        'iin': '642918307154',
        'full_name': 'Иванов Иван',
        'active': 'true',
        'position': 'Инженер',
        'division': 'IT',
      });
      expect(employee.active, isTrue);
      expect(employee.position, 'Инженер');
      expect(employee.hasPhoto, isFalse);
    });

    test('без поля active сотрудник активен (mobile login/profile)', () {
      // Ответ /api/mobile/auth/login/ и /profile/me/ не содержит active.
      final employee = _parse({
        'iin': '990101300123',
        'full_name': 'Тестовый Сотрудник',
        'phone': '77001234567',
        'position': 'Проектный менеджер IT',
      });
      expect(employee.active, isTrue);
      expect(employee.position, 'Проектный менеджер IT');
    });

    test('явный active=false блокирует доступ', () {
      expect(_parse({'iin': '1', 'full_name': 'Тест', 'active': false}).active,
          isFalse);
      expect(
          _parse({'iin': '1', 'full_name': 'Тест', 'active': 'inactive'})
              .active,
          isFalse);
    });

    test('названия должности и отдела берутся из *_name вместо UUID', () {
      final employee = _parse({
        'iin': '990101300123',
        'full_name': 'Тестовый Сотрудник',
        'active': true,
        'position': '11111111-1111-4111-8111-111111111111',
        'position_name': 'Проектный менеджер IT',
        'division': '22222222-2222-4222-8222-222222222222',
        'division_name': 'IT отдел',
        'organization_guid': '33333333-3333-4333-8333-333333333333',
      });
      expect(employee.position, 'Проектный менеджер IT');
      expect(employee.division, 'IT отдел');
      expect(employee.organization, isNull);
    });

    test('кеш toJson → fromJson сохраняет данные и график', () {
      final original = EmployeeDto.fromJson({
        'iin': '642918307154',
        'full_name': 'Иванов Иван',
        'active': true,
        'position': {'name': 'Инженер'},
        'schedule_name': '2/2',
        'schedule_start_time': '10:00:00',
        'schedule_end_time': '19:00:00',
      });
      final restored = EmployeeDto.fromJson(original.toJson()).toEntity();
      expect(restored.iin, '642918307154');
      expect(restored.position, 'Инженер');
      expect(restored.active, isTrue);
      expect(restored.scheduleName, '2/2');
      expect(restored.scheduleRangeLabel, '10:00-19:00');
    });

    test('лишние пробелы в ФИО из базы не попадают на экран', () {
      final employee = _parse({
        'iin': '642918307154',
        'full_name': ' Иванова  Анна\tСергеевна ',
      });
      expect(employee.fullName, 'Иванова Анна Сергеевна');
      expect(employee.firstName, 'Анна');
    });
  });
}
