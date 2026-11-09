import 'package:flutter/foundation.dart' show immutable;

import '../../../../core/time/clock_time.dart';

/// Сотрудник AvaTracker.
@immutable
final class Employee {
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
    this.scheduleName,
    this.scheduleStart,
    this.scheduleEnd,
  });

  final int? id;

  /// ИИН (Казахстан) или ПИНФЛ (Узбекистан).
  final String iin;
  final String fullName;

  /// Отключённый сотрудник не получает доступ к приложению.
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

  /// Индивидуальный график работы.
  final ClockTime? scheduleStart;
  final ClockTime? scheduleEnd;

  /// Без базового фото подтвердить личность перед отметкой нельзя.
  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  /// «Иванов Иван Иванович» → «Иван».
  String get firstName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.length > 1 ? parts[1] : fullName;
  }

  /// `09:00-18:00`; пустая строка, если график неизвестен.
  String get scheduleRangeLabel {
    final start = scheduleStart;
    final end = scheduleEnd;
    if (start == null || end == null) return '';
    return '${start.label}-${end.label}';
  }
}
