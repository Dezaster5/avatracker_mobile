import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../l10n/l10n_ext.dart';
import '../../auth/providers.dart';
import '../domain/analytics.dart';
import '../providers.dart';

/// Аналитика опозданий по данным backend.
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  late DateTime _anchor;

  @override
  void initState() {
    super.initState();
    final now = AppConfig.today;
    _anchor = DateTime(now.year, now.month, now.day);
  }

  AnalyticsRange get _range =>
      AnalyticsRange.forPeriod(AnalyticsPeriod.month, _anchor)
          .clampEnd(AppConfig.today);

  DateTime _shiftedAnchor(int direction) =>
      DateTime(_anchor.year, _anchor.month + direction, 1);

  bool get _canGoNext {
    final next =
        AnalyticsRange.forPeriod(AnalyticsPeriod.month, _shiftedAnchor(1));
    final today = AppConfig.today;
    return !next.start.isAfter(today);
  }

  Future<void> _refresh(AnalyticsRange range) async {
    ref.invalidate(tardinessAnalyticsProvider(range));
    await ref.read(tardinessAnalyticsProvider(range).future);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final range = _range;
    final analytics = ref.watch(tardinessAnalyticsProvider(range));
    final scheduleLabel = ref.watch(
      authControllerProvider.select(
        (session) => session.employee?.scheduleRangeLabel ?? '',
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabAnalytics)),
      body: RefreshIndicator(
        onRefresh: () => _refresh(range),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _RangeSwitcher(
              title: _rangeTitle(range, l10n.localeName),
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
                  tardinessAnalyticsProvider(range),
                ),
              ),
              data: (data) => _AnalyticsContent(
                analytics: data,
                scheduleLabel: scheduleLabel,
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
          tooltip: context.l10n.previousPeriod,
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
          tooltip: context.l10n.nextPeriod,
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
    required this.scheduleLabel,
  });

  final TardinessAnalytics analytics;
  final String scheduleLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricGrid(analytics: analytics),
        const SizedBox(height: 18),
        Text(
          l10n.latenessLabel,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.analyticsSourceNote,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12.5,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        _WorkScheduleSection(scheduleLabel: scheduleLabel),
        const SizedBox(height: 14),
        if (analytics.count == 0)
          const _NoLateArrivals()
        else ...[
          Text(
            l10n.latenessHistory,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (final entry in analytics.results) ...[
            _LateArrivalRow(entry: entry),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _WorkScheduleSection extends StatelessWidget {
  const _WorkScheduleSection({required this.scheduleLabel});

  final String scheduleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.work_history_outlined,
              color: AppColors.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.workSchedule,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  scheduleLabel.isEmpty ? '—' : scheduleLabel,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.analytics});

  final TardinessAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _LateMetric(
                value: '${analytics.count}',
                label: l10n.metricCases,
                icon: Icons.event_busy_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LateMetric(
                value: l10n.formatDuration(analytics.totalTardinessMinutes),
                label: l10n.metricTotal,
                icon: Icons.timer_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _LateMetric(
                value: l10n.formatDuration(analytics.avgTardiness),
                label: l10n.metricAverage,
                icon: Icons.functions_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LateMetric(
                value: l10n.formatDuration(analytics.maxTardiness),
                label: l10n.metricMax,
                icon: Icons.warning_amber_rounded,
              ),
            ),
          ],
        ),
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
  const _LateArrivalRow({required this.entry});

  final TardinessEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                  DateFormat(
                    'd MMMM, EEEE',
                    l10n.localeName,
                  ).format(entry.date),
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.plannedArrival(
                    entry.scheduledLabel,
                    entry.actualLabel,
                  ),
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
            '+${l10n.formatDuration(entry.tardinessMinutes)}',
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
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.analyticsNoLateness,
              style: const TextStyle(
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

String _rangeTitle(
  AnalyticsRange range,
  String locale,
) {
  return formatMonthTitle(range.start, locale: locale);
}
