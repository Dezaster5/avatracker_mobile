import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/l10n_ext.dart';

/// Нижняя навигация: Сканер, Табель, Аналитика, Профиль.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    (
      path: '/scanner',
      icon: Icons.qr_code_scanner_rounded,
      selectedIcon: Icons.qr_code_scanner_rounded,
    ),
    (
      path: '/timesheet',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month_rounded,
    ),
    (
      path: '/stats',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
    ),
    (
      path: '/profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = [
      l10n.tabScanner,
      l10n.tabTimesheet,
      l10n.tabAnalytics,
      l10n.tabProfile,
    ];
    final selected = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.outline)),
        ),
        child: NavigationBar(
          selectedIndex: selected,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == selected,
          ),
          destinations: [
            for (var i = 0; i < _tabs.length; i++)
              NavigationDestination(
                icon: Icon(_tabs[i].icon),
                selectedIcon: Icon(_tabs[i].selectedIcon),
                label: labels[i],
              ),
          ],
        ),
      ),
    );
  }
}
