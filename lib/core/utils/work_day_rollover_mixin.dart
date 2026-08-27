import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_config.dart';

/// Уведомляет экран о смене рабочего дня в 03:00 и после возврата из фона.
mixin WorkDayRolloverMixin<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  Timer? _workDayTimer;
  late DateTime _knownWorkDate;

  @override
  void initState() {
    super.initState();
    _knownWorkDate = AppConfig.workDate;
    WidgetsBinding.instance.addObserver(this);
    _scheduleWorkDayRollover();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _workDayTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkWorkDay();
    }
  }

  void _scheduleWorkDayRollover() {
    _workDayTimer?.cancel();
    final now = DateTime.now();
    var next = DateTime(
      now.year,
      now.month,
      now.day,
      AppConfig.workDayResetHour,
    );
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    _workDayTimer = Timer(next.difference(now), _checkWorkDay);
  }

  void _checkWorkDay() {
    if (!mounted) return;
    final current = AppConfig.workDate;
    if (current != _knownWorkDate) {
      final previous = _knownWorkDate;
      _knownWorkDate = current;
      onWorkDayChanged(previous, current);
    }
    _scheduleWorkDayRollover();
  }

  void onWorkDayChanged(DateTime previous, DateTime current);
}
