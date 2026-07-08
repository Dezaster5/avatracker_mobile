import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../l10n/l10n_ext.dart';
import '../domain/analytics.dart';
import '../providers.dart';

/// Экран «Табель»: календарь месяца с опозданиями.
///
/// Бэкенд отдаёт только опоздания (`/tardiness/`) — приходов вовремя, уходов
/// и отработанных часов в API нет. Поэтому табель строится из опозданий и
/// графика сотрудника: красным отмечены дни опозданий с временем прихода.
class TimesheetScreen extends ConsumerStatefulWidget {
  const TimesheetScreen({super.key});

  @override
  ConsumerState<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends ConsumerState<TimesheetScreen> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = AppConfig.today;
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
  }

  bool get _isCurrentMonth {
    final now = AppConfig.today;
    return _month.year == now.year && _month.month == now.month;
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      final now = AppConfig.today;
      _selected = (_month.year == now.year && _month.month == now.month)
          ? DateTime(now.year, now.month, now.day)
          : DateTime(_month.year, _month.month, 1);
    });
  }

  AnalyticsRange get _range =>
      AnalyticsRange.forPeriod(AnalyticsPeriod.month, _month)
          .clampEnd(AppConfig.today);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final range = _range;
    final tardiness = ref.watch(tardinessAnalyticsProvider(range));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabTimesheet)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tardinessAnalyticsProvider(range));
          await ref.read(tardinessAnalyticsProvider(range).future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _MonthSwitcher(
              title: formatMonthTitle(_month, locale: l10n.localeName),
              onPrev: () => _changeMonth(-1),
              onNext: _isCurrentMonth ? null : () => _changeMonth(1),
            ),
            const SizedBox(height: 12),
            tardiness.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => AppErrorView(
                message: error.toString(),
                onRetry: () =>
                    ref.invalidate(tardinessAnalyticsProvider(range)),
              ),
              data: (data) {
                final lateByDay = {
                  for (final e in data.results)
                    DateTime(e.date.year, e.date.month, e.date.day): e,
                };
                return Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                        child: Column(
                          children: [
                            _CalendarGrid(
                              month: _month,
                              selected: _selected,
                              lateByDay: lateByDay,
                              onSelect: (date) =>
                                  setState(() => _selected = date),
                            ),
                            const Divider(color: AppColors.outline, height: 22),
                            const _Legend(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.04),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: _DayCard(
                        key: ValueKey(_selected),
                        date: _selected,
                        entry: lateByDay[DateTime(
                          _selected.year,
                          _selected.month,
                          _selected.day,
                        )],
                        scheduleLabel: data.scheduleStartLabel,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({required this.title, this.onPrev, this.onNext});

  final String title;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ArrowButton(icon: Icons.chevron_left_rounded, onTap: onPrev),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(
            title,
            key: ValueKey(title),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
              letterSpacing: 0,
            ),
          ),
        ),
        _ArrowButton(icon: Icons.chevron_right_rounded, onTap: onNext),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? AppColors.surface : Colors.white,
      shape: const CircleBorder(side: BorderSide(color: AppColors.outline)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 24,
            color: onTap == null
                ? AppColors.textSecondary.withValues(alpha: 0.4)
                : AppColors.navy,
          ),
        ),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.selected,
    required this.lateByDay,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final Map<DateTime, TardinessEntry> lateByDay;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final weekdays = List.generate(
      7,
      (index) => DateFormat.E(context.l10n.localeName).format(
        DateTime(2024, 1, 1 + index),
      ),
    );
    final today = AppConfig.today;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = DateTime(month.year, month.month, 1).weekday - 1;

    final cells = <Widget>[
      for (final w in weekdays)
        Center(
          child: Text(
            w,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
      for (var d = 1; d <= daysInMonth; d++)
        _buildDay(DateTime(month.year, month.month, d), today),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }

  Widget _buildDay(DateTime date, DateTime today) {
    final isSelected = date.year == selected.year &&
        date.month == selected.month &&
        date.day == selected.day;
    final isToday = date == today;
    final isLate = lateByDay.containsKey(date);

    final Color bg;
    final Color fg;
    if (isSelected) {
      bg = AppColors.primary;
      fg = Colors.white;
    } else if (isLate) {
      bg = AppColors.dayLate.withValues(alpha: 0.14);
      fg = AppColors.dayLate;
    } else {
      bg = Colors.transparent;
      fg = AppColors.navy;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onSelect(date),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: bg,
          border: isToday && !isSelected
              ? Border.all(color: AppColors.primary, width: 1.6)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.32),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${date.day}',
          style: TextStyle(
            fontWeight:
                isSelected || isToday ? FontWeight.w800 : FontWeight.w500,
            fontSize: 14.5,
            color: isToday && !isSelected ? AppColors.primary : fg,
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.dayLate,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          context.l10n.redMarksLate,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Карточка выбранного дня: опоздание с временем прихода либо «без опозданий».
class _DayCard extends StatelessWidget {
  const _DayCard({
    super.key,
    required this.date,
    required this.entry,
    required this.scheduleLabel,
  });

  final DateTime date;
  final TardinessEntry? entry;
  final String scheduleLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isFuture = date.isAfter(AppConfig.today);
    final late = entry;

    final (String label, Color color) = late != null
        ? (l10n.latenessLabel, AppColors.dayLate)
        : isFuture
            ? (l10n.dayNotYet, AppColors.textSecondary)
            : (l10n.dayNoLate, AppColors.success);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatDate(date),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                StatusChip(label: label, color: color),
              ],
            ),
            const SizedBox(height: 12),
            if (late != null) ...[
              _row(l10n.cameAt, late.actualLabel),
              if (scheduleLabel.isNotEmpty)
                _row(l10n.bySchedule, scheduleLabel),
              _row(
                l10n.latenessLabel,
                l10n.formatDuration(late.tardinessMinutes),
              ),
            ] else
              Text(
                isFuture ? l10n.dayNotArrivedYet : l10n.noLatenessThisDay,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}
