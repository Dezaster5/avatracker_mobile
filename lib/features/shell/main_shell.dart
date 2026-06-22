import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// Нижняя навигация: Сканер, Табель, Аналитика, Профиль.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _tabs = [
    (
      path: '/scanner',
      icon: Icons.qr_code_scanner_rounded,
      selectedIcon: Icons.qr_code_scanner_rounded,
      label: 'Сканер',
    ),
    (
      path: '/timesheet',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month_rounded,
      label: 'Табель',
    ),
    (
      path: '/stats',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
      label: 'Аналитика',
    ),
    (
      path: '/profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Профиль',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    var selected = _tabs.indexWhere((t) => location.startsWith(t.path));
    if (selected < 0) selected = 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.outline)),
        ),
        child: NavigationBar(
          selectedIndex: selected,
          onDestinationSelected: (index) => context.go(_tabs[index].path),
          destinations: [
            for (final tab in _tabs)
              NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.selectedIcon),
                label: tab.label,
              ),
          ],
        ),
      ),
    );
  }
}
