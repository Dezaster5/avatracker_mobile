import '../../../../core/time/clock_time.dart';
import '../../domain/entities/analytics_range.dart';
import '../../domain/entities/tardiness.dart';

/// Ответ `/tardiness/?iin=&period_from=&period_to=`.
final class TardinessAnalyticsDto {
  const TardinessAnalyticsDto({
    required this.scheduleStartTime,
    required this.count,
    required this.maxTardiness,
    required this.avgTardiness,
    required this.results,
  });

  factory TardinessAnalyticsDto.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'];
    final entries = rawResults is List
        ? rawResults
            .whereType<Map<String, dynamic>>()
            .map(TardinessEntryDto.fromJson)
            .toList()
        : <TardinessEntryDto>[];
    final total = entries.fold(0, (sum, entry) => sum + entry.tardinessMinutes);
    final maximum = entries.fold(
      0,
      (value, entry) =>
          entry.tardinessMinutes > value ? entry.tardinessMinutes : value,
    );
    final count = _roundedInt(json['count'], fallback: entries.length);
    return TardinessAnalyticsDto(
      scheduleStartTime: '${json['schedule_start_time'] ?? ''}',
      count: count,
      maxTardiness: _roundedInt(json['max_tardiness'], fallback: maximum),
      avgTardiness: _roundedInt(
        json['avg_tardiness'],
        fallback: count == 0 ? 0 : (total / count).round(),
      ),
      results: entries,
    );
  }

  final String scheduleStartTime;
  final int count;
  final int maxTardiness;
  final int avgTardiness;
  final List<TardinessEntryDto> results;

  TardinessAnalytics toEntity(AnalyticsRange range) => TardinessAnalytics(
        range: range,
        scheduleStart: ClockTime.tryParse(scheduleStartTime),
        count: count,
        maxTardiness: maxTardiness,
        avgTardiness: avgTardiness,
        results: [for (final entry in results) entry.toEntity()]
          ..sort((a, b) => b.date.compareTo(a.date)),
      );
}

final class TardinessEntryDto {
  const TardinessEntryDto({
    required this.date,
    required this.authTime,
    required this.scheduleStartTime,
    required this.tardinessMinutes,
  });

  factory TardinessEntryDto.fromJson(Map<String, dynamic> json) =>
      TardinessEntryDto(
        date: '${json['date']}',
        authTime: '${json['auth_time'] ?? ''}',
        scheduleStartTime: '${json['schedule_start_time'] ?? ''}',
        tardinessMinutes: _roundedInt(json['tardiness_minutes']),
      );

  final String date;
  final String authTime;
  final String scheduleStartTime;
  final int tardinessMinutes;

  TardinessEntry toEntity() {
    final arrival = DateTime.tryParse(authTime)?.toLocal();
    return TardinessEntry(
      date: DateTime.tryParse(date) ?? DateTime(1970),
      authTime: authTime,
      scheduled: ClockTime.tryParse(scheduleStartTime) ??
          const ClockTime.fromMinutes(0),
      tardinessMinutes: tardinessMinutes,
      actual: arrival == null ? null : ClockTime.of(arrival),
    );
  }
}

/// Минуты опозданий: дробные значения округляются.
int _roundedInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse('$value') ?? fallback;
}
