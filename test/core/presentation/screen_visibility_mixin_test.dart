import 'package:avatracker_mobile/core/presentation/screen_visibility_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _Probe extends StatefulWidget {
  const _Probe(this.events);

  final List<bool> events;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> with ScreenVisibilityMixin<_Probe> {
  @override
  void onScreenVisibilityChanged(bool visible) => widget.events.add(visible);

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  testWidgets('экран, перекрытый непрозрачным маршрутом, скрыт',
      (tester) async {
    final events = <bool>[];
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: _Probe(events)),
    );
    expect(events, isEmpty, reason: 'начальное состояние не сообщается');

    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const SizedBox()),
    );
    await tester.pumpAndSettle();
    expect(events, [false]);

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(events, [false, true]);
  });

  // Сканер держит камеру в постоянной ветке нижней навигации: тест фиксирует,
  // что go_router по-прежнему выключает TickerMode у неактивных веток.
  testWidgets('неактивная вкладка StatefulShellRoute скрыта', (tester) async {
    final events = <bool>[];
    late StatefulNavigationShell shell;
    final router = GoRouter(
      initialLocation: '/scanner',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            shell = navigationShell;
            return navigationShell;
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/scanner', builder: (_, __) => _Probe(events)),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/profile', builder: (_, __) => const SizedBox()),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    shell.goBranch(1);
    await tester.pumpAndSettle();
    expect(events, [false]);

    shell.goBranch(0);
    await tester.pumpAndSettle();
    expect(events, [false, true]);
  });
}
