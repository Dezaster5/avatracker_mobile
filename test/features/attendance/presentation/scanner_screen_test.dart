import 'dart:async';

import 'package:avatracker_mobile/features/attendance/presentation/screens/scanner_screen.dart';
import 'package:avatracker_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Камера без нативного плагина: считает запуски и остановки.
class _FakeScannerPlatform extends MobileScannerPlatform {
  int startCalls = 0;
  int stopCalls = 0;

  final _barcodes = StreamController<BarcodeCapture?>.broadcast();
  final _torch = StreamController<TorchState>.broadcast();
  final _zoom = StreamController<double>.broadcast();

  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodes.stream;

  @override
  Stream<TorchState> get torchStateStream => _torch.stream;

  @override
  Stream<double> get zoomScaleStateStream => _zoom.stream;

  @override
  Widget buildCameraView() => const SizedBox.expand();

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    startCalls++;
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.off,
      size: Size(640, 480),
    );
  }

  @override
  Future<void> stop() async => stopCalls++;

  @override
  Future<void> updateScanWindow(Rect? window) async {}

  @override
  Future<void> dispose() async {}
}

/// Бегущая линия сканера анимируется бесконечно, поэтому вместо
/// `pumpAndSettle` прокручиваем несколько кадров: этого хватает, чтобы
/// очередь операций камеры дошла до платформы.
Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  testWidgets('камера сканера не работает, пока открыта другая вкладка',
      (tester) async {
    final platform = _FakeScannerPlatform();
    final previousPlatform = MobileScannerPlatform.instance;
    MobileScannerPlatform.instance = platform;
    addTearDown(() => MobileScannerPlatform.instance = previousPlatform);

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
                GoRoute(
                  path: '/scanner',
                  builder: (_, __) => const ScannerScreen(),
                ),
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

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await _pumpFrames(tester);
    expect(platform.startCalls, 1);

    shell.goBranch(1);
    await _pumpFrames(tester);
    expect(platform.stopCalls, 1, reason: 'вкладка скрыта — камера стоит');

    shell.goBranch(0);
    await _pumpFrames(tester);
    expect(platform.startCalls, 2, reason: 'вернулись — камера снова идёт');
  });
}
