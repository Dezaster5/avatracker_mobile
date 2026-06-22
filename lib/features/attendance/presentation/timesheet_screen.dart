import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/timesheet.dart';
import '../providers.dart';

/// Экран «Табель» (ТЗ 9): календарь месяца со статусами дней
/// и карточка выбранного дня с историей сканирований.
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
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selected = DateTime(_month.year, _month.month, 1);
      final now = DateTime.now();
      if (_month.year == now.year && _month.month == now.month) {
        _selected = DateTime(now.year, now.month, now.day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthKey = monthParam(_month);
    final timesheet = ref.watch(timesheetProvider(monthKey));

    return Scaffold(
      appBar: AppBar(title: const Text('Табель')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(timesheetProvider(monthKey));
          await ref.read(timesheetProvider(monthKey).future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _MonthSwitcher(
              title: formatMonthTitle(_month),
              onPrev: () => _changeMonth(-1),
              onNext: _isCurrentMonth ? null : () => _changeMonth(1),
            ),
            const SizedBox(height: 12),
            timesheet.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => AppErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(timesheetProvider(monthKey)),
              ),
              data: (data) => Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                      child: Column(
                        children: [
                          _CalendarGrid(
                            month: _month,
                            selected: _selected,
                            timesheet: data,
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
                      day: data.dayFor(_selected),
                    ),
                  ),
                ],
              ),
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
    required this.timesheet,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final TimesheetMonth timesheet;
  final ValueChanged<DateTime> onSelect;

  static const _weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  Color? _statusColor(DateTime date, TimesheetDay? day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date.isAfter(today)) return null;

    if (day == null) {
      return date.weekday >= DateTime.saturday ? AppColors.dayWeekend : null;
    }
    switch (day.status) {
      case DayStatus.onTime:
        return AppColors.dayOnTime;
      case DayStatus.late:
        return AppColors.dayLate;
      case DayStatus.absent:
        return AppColors.dayAbsent;
      case DayStatus.weekend:
        return AppColors.dayWeekend;
      case DayStatus.weekendWork:
        return AppColors.dayWeekendWork;
      case DayStatus.noScan:
      case DayStatus.unknown:
        return day.isWeekend ? AppColors.dayWeekend : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = DateTime(month.year, month.month, 1).weekday - 1;

    final cells = <Widget>[
      for (final w in _weekdays)
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
    final day = timesheet.dayFor(date);
    final isSelected = date.year == selected.year &&
        date.month == selected.month &&
        date.day == selected.day;
    final isToday = date == today;
    final status = _statusColor(date, day);

    final Color bg;
    final Color fg;
    if (isSelected) {
      bg = AppColors.primary;
      fg = Colors.white;
    } else if (status != null && status != AppColors.dayWeekend) {
      bg = status.withValues(alpha: 0.14);
      fg = status;
    } else if (status == AppColors.dayWeekend) {
      bg = AppColors.surface;
      fg = AppColors.textSecondary;
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

  static const _items = [
    (color: AppColors.dayOnTime, label: 'Вовремя'),
    (color: AppColors.dayLate, label: 'Опоздание'),
    (color: AppColors.dayAbsent, label: 'Пропуск'),
    (color: AppColors.dayWeekendWork, label: 'В выходной'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (final item in _items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.color,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Карточка дня (ТЗ 9.2).
class _DayCard extends StatelessWidget {
  const _DayCard({super.key, required this.date, required this.day});

  final DateTime date;
  final TimesheetDay? day;

  (String, Color) _badge() {
    final d = day;
    if (d == null) return ('Нет данных', AppColors.textSecondary);
    switch (d.status) {
      case DayStatus.onTime:
        return ('Вовремя', AppColors.success);
      case DayStatus.late:
        return ('Опоздал', AppColors.warning);
      case DayStatus.absent:
        return ('Пропуск', AppColors.danger);
      case DayStatus.weekend:
        return ('Выходной', AppColors.textSecondary);
      case DayStatus.weekendWork:
        return ('Работа в выходной', AppColors.dayWeekendWork);
      case DayStatus.noScan:
        return ('Нет отметок', AppColors.textSecondary);
      case DayStatus.unknown:
        return (d.statusRaw ?? 'Нет данных', AppColors.textSecondary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = day;
    final (label, color) = _badge();

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
            if (d == null)
              const Text(
                'Нет данных о сканированиях',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else ...[
              _row('Тип дня', d.isWeekend ? 'Выходной' : 'Рабочий день'),
              if (d.workStart != null && d.workEnd != null)
                _row('Рабочее время', '${d.workStart}–${d.workEnd}'),
              if (d.lunchStart != null && d.lunchEnd != null)
                _row(
                  'Обед (не учитывается)',
                  '${d.lunchStart}–${d.lunchEnd}',
                ),
              _row('Отработано', formatMinutes(d.workedMinutes)),
              if (!d.isWeekend && d.remainingMinutes > 0)
                _row('Осталось', formatMinutes(d.remainingMinutes)),
              if (d.place != null) _row('Место работы', d.place!),
              if (d.scans.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Сканирования',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 6),
                for (var i = 0; i < d.scans.length; i++)
                  _ScanRow(
                    scan: d.scans[i],
                    isLast: i == d.scans.length - 1,
                  ),
              ] else ...[
                const SizedBox(height: 8),
                const Text(
                  'Нет данных о сканированиях',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ],
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

/// Строка сканирования в виде таймлайна: точка, тип, время.
class _ScanRow extends StatelessWidget {
  const _ScanRow({required this.scan, required this.isLast});

  final ScanEntry scan;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isIn = scan.type == 'check_in';
    final color = isIn ? AppColors.success : AppColors.primary;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIn ? Icons.login_rounded : Icons.logout_rounded,
                  size: 16,
                  color: color,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: AppColors.outline,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 5, bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scan.typeLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                  if (scan.point != null)
                    Text(
                      scan.point!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              scan.time != null ? formatTime(scan.time!.toLocal()) : '—',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
