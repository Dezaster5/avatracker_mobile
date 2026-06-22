import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_error_view.dart';
import '../domain/analytics.dart';
import '../providers.dart';

/// Клиентская аналитика по табелю: отработанное время и опоздания.
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  AnalyticsPeriod _period = AnalyticsPeriod.month;
  late DateTime _anchor;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _anchor = DateTime(now.year, now.month, now.day);
  }

  AnalyticsRange get _range => AnalyticsRange.forPeriod(_period, _anchor);

  DateTime _shiftedAnchor(int direction) {
    if (_period == AnalyticsPeriod.week) {
      return _anchor.add(Duration(days: 7 * direction));
    }
    return DateTime(_anchor.year, _anchor.month + direction, 1);
  }

  bool get _canGoNext {
    final next = AnalyticsRange.forPeriod(_period, _shiftedAnchor(1));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !next.start.isAfter(today);
  }

  Future<void> _refresh(AnalyticsRange range) async {
    for (final month in range.monthKeys) {
      ref.invalidate(timesheetProvider(month));
    }
    ref.invalidate(attendanceAnalyticsProvider(range));
    await ref.read(attendanceAnalyticsProvider(range).future);
  }

  @override
  Widget build(BuildContext context) {
    final range = _range;
    final analytics = ref.watch(attendanceAnalyticsProvider(range));

    return Scaffold(
      appBar: AppBar(title: const Text('Аналитика')),
      body: RefreshIndicator(
        onRefresh: () => _refresh(range),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<AnalyticsPeriod>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: AnalyticsPeriod.week,
                    label: Text('Неделя'),
                    icon: Icon(Icons.date_range_rounded),
                  ),
                  ButtonSegment(
                    value: AnalyticsPeriod.month,
                    label: Text('Месяц'),
                    icon: Icon(Icons.calendar_month_rounded),
                  ),
                ],
                selected: {_period},
                onSelectionChanged: (selection) {
                  setState(() => _period = selection.first);
                },
              ),
            ),
            const SizedBox(height: 14),
            _RangeSwitcher(
              title: _rangeTitle(range, _period),
              onPrevious: () => setState(() => _anchor = _shiftedAnchor(-1)),
              onNext: _canGoNext
                  ? () => setState(() => _anchor = _shiftedAnchor(1))
                  : null,
            ),
            const SizedBox(height: 14),
            analytics.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 96),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => AppErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(
                  attendanceAnalyticsProvider(range),
                ),
              ),
              data: (data) => _AnalyticsContent(
                analytics: data,
                period: _period,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeSwitcher extends StatelessWidget {
  const _RangeSwitcher({
    required this.title,
    required this.onPrevious,
    required this.onNext,
  });

  final String title;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Предыдущий период',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Следующий период',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded, size: 28),
        ),
      ],
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({
    required this.analytics,
    required this.period,
  });

  final AttendanceAnalytics analytics;
  final AnalyticsPeriod period;

  @override
  Widget build(BuildContext context) {
    final periodLabel = period == AnalyticsPeriod.week ? 'неделю' : 'месяц';
    final averageWorked = analytics.workedDays == 0
        ? 0
        : (analytics.workedMinutes / analytics.workedDays).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: AppColors.navyGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    color: Colors.white60,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Отработано за $periodLabel',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                formatMinutes(analytics.workedMinutes),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                analytics.workedDays == 0
                    ? 'За выбранный период отработанных смен нет'
                    : '${analytics.workedDays} ${_shiftLabel(analytics.workedDays)} · '
                        'в среднем ${formatMinutes(averageWorked)} за смену',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Опоздания',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Расчет по индивидуальному времени начала смены и первой отметке прихода',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12.5,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        if (analytics.lateDays == 0)
          const _NoLateArrivals()
        else ...[
          Row(
            children: [
              Expanded(
                child: _LateMetric(
                  value: '${analytics.lateDays}',
                  label: 'случаев',
                  icon: Icons.event_busy_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LateMetric(
                  value: formatMinutes(analytics.totalLateMinutes),
                  label: 'суммарно',
                  icon: Icons.timer_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LateMetric(
                  value: formatMinutes(analytics.averageLateMinutes),
                  label: 'в среднем',
                  icon: Icons.functions_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Максимальное опоздание: '
                    '${formatMinutes(analytics.maxLateMinutes)}',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'История опозданий',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (final arrival in analytics.lateArrivals) ...[
            _LateArrivalRow(arrival: arrival),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _LateMetric extends StatelessWidget {
  const _LateMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.warning, size: 21),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LateArrivalRow extends StatelessWidget {
  const _LateArrivalRow({required this.arrival});

  final LateArrival arrival;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: AppColors.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('d MMMM, EEEE', 'ru').format(arrival.date),
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'План ${arrival.scheduledLabel} · '
                  'приход ${arrival.actualLabel}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+${arrival.lateMinutes} мин',
            style: const TextStyle(
              color: AppColors.warning,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoLateArrivals extends StatelessWidget {
  const _NoLateArrivals();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outline),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'За выбранный период опозданий нет',
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _rangeTitle(AnalyticsRange range, AnalyticsPeriod period) {
  if (period == AnalyticsPeriod.month) {
    return formatMonthTitle(range.start);
  }
  final start = DateFormat('d MMM', 'ru').format(range.start);
  final end = DateFormat('d MMM yyyy', 'ru').format(range.end);
  return '$start – $end';
}

String _shiftLabel(int count) {
  final mod10 = count % 10;
  final mod100 = count % 100;
  if (mod10 == 1 && mod100 != 11) return 'смена';
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return 'смены';
  }
  return 'смен';
}
