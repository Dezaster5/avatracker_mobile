import '../../../../core/time/clock_time.dart';
import '../../../../core/time/work_day.dart';
import '../../domain/entities/attendance_mark.dart';

/// Отметка из `/employee-identification-list/`.
final class AttendanceMarkDto {
  const AttendanceMarkDto({required this.authTime});

  factory AttendanceMarkDto.fromJson(Map<String, dynamic> json) =>
      AttendanceMarkDto(authTime: '${json['auth_time'] ?? ''}'.trim());

  final String authTime;

  /// Время переводится в часовой пояс устройства и относится к рабочему дню.
  AttendanceMark toEntity() {
    final parsed = DateTime.tryParse(authTime);
    if (parsed == null) throw const FormatException('Invalid auth_time');
    final local = parsed.toLocal();
    return AttendanceMark(
      authTime: authTime,
      occurredAt: local,
      date: WorkDay.dateOf(local),
      time: ClockTime.of(local),
    );
  }
}
