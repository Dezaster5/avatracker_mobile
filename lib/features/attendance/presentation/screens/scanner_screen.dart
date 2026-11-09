import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/presentation/screen_visibility_mixin.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n_ext.dart';
import '../../domain/entities/qr_point.dart';
import '../controllers/scanner_controller.dart';
import '../widgets/scan_result_sheet.dart';
import 'face_id_screen.dart';

/// QR-сканер (ТЗ 7, 19.4): скан -> геолокация с проверками -> отметка.
///
/// Экран живёт в постоянной вкладке, но камера работает, только пока он
/// виден: на другой вкладке или под другим экраном она остановлена.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        ScreenVisibilityMixin<ScannerScreen> {
  static MobileScannerController _newController() => MobileScannerController(
        autoStart: false,
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: const [BarcodeFormat.qrCode],
      );

  /// Камера — глобальный ресурс процесса. Операции lifecycle и ручного
  /// перезапуска выполняются последовательно, чтобы start не пересекался
  /// со stop/dispose того же контроллера.
  static Future<void> _cameraQueue = Future<void>.value();

  static Future<void> _enqueueCamera(
    Future<void> Function() operation,
  ) {
    final previous = _cameraQueue;
    final next = () async {
      try {
        await previous;
      } catch (_) {
        // Ошибка предыдущего контроллера не должна блокировать новый запуск.
      }
      await operation();
    }();
    _cameraQueue = () async {
      try {
        await next;
      } catch (_) {
        // Очередь всегда остаётся пригодной для следующей операции.
      }
    }();
    return next;
  }

  MobileScannerController _controller = _newController();

  /// Эпоха камеры: смена ключа полностью пересоздаёт превью при перезапуске.
  int _cameraEpoch = 0;

  /// Было ли приложение свёрнуто — чтобы пересоздавать камеру только после
  /// реального возврата из фона (например, из настроек с выдачей разрешения).
  bool _wasPaused = false;
  bool _disposed = false;
  bool _restarting = false;

  /// Бегущая линия сканирования внутри рамки.
  late final AnimationController _scanLine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  /// Идёт отметка: камеру и новые распознавания не трогаем.
  bool get _busy => ref.read(scannerControllerProvider).isBusy;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Отметка могла оборваться вместе с прошлой сессией.
      ref.read(scannerControllerProvider.notifier).finish();
      unawaited(_startCamera());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_busy) return; // во время FaceID/обработки камеру не трогаем
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _wasPaused = true;
      unawaited(_stopCamera());
    } else if (state == AppLifecycleState.resumed && _wasPaused) {
      _wasPaused = false;
      unawaited(_startCamera());
    }
  }

  /// Скрытая вкладка не держит камеру: иначе горит индикатор камеры,
  /// расходуется батарея, а QR в кадре запустил бы отметку незаметно.
  @override
  void onScreenVisibilityChanged(bool visible) {
    if (_busy) return; // во время отметки камерой управляет сам сценарий
    unawaited(visible ? _startCamera() : _stopCamera());
  }

  Future<void> _startCamera() {
    final controller = _controller;
    return _enqueueCamera(() async {
      if (_disposed ||
          !mounted ||
          _busy ||
          !isScreenVisible ||
          !identical(controller, _controller)) {
        return;
      }
      final state = controller.value;
      if (state.isRunning || state.isStarting) return;
      try {
        await controller.start();
      } on MobileScannerException catch (error) {
        debugPrint('MobileScanner start failed: $error');
      }
    });
  }

  Future<void> _stopCamera([MobileScannerController? target]) {
    final controller = target ?? _controller;
    return _enqueueCamera(() async {
      try {
        await controller.stop();
      } on MobileScannerException catch (error) {
        if (error.errorCode != MobileScannerErrorCode.controllerDisposed) {
          debugPrint('MobileScanner stop failed: $error');
        }
      }
    });
  }

  Future<void> _releaseCamera(MobileScannerController controller) {
    return _enqueueCamera(() async {
      try {
        await controller.stop();
      } catch (_) {
        // Контроллер мог не успеть инициализироваться до смены вкладки.
      }
      await controller.dispose();
    });
  }

  /// Полный последовательный перезапуск после ошибки разрешения/инициализации.
  Future<void> _restartCamera() async {
    if (_disposed || _restarting) return;
    _restarting = true;
    final old = _controller;
    try {
      if (!mounted) return;
      setState(() {
        _controller = _newController();
        _cameraEpoch++;
      });
      await WidgetsBinding.instance.endOfFrame;
      await _releaseCamera(old);
      if (_disposed || !mounted) return;
      await _startCamera();
    } finally {
      _restarting = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _scanLine.dispose();
    unawaited(_releaseCamera(_controller));
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_busy || !isScreenVisible) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    _processScan(QrCode.parse(raw));
  }

  Future<void> _processScan(QrCode code) async {
    final scanner = ref.read(scannerControllerProvider.notifier)..start();
    await _stopCamera();
    if (!mounted) return;

    final blocked = await scanner.checkPoint(code);
    if (!mounted) return;
    if (blocked != null) return _showResultAndResume(blocked);

    // Экран FaceID возвращает base64-снимок лица; сверку делает сервер при скане.
    final photo = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const FaceIdScreen(),
      ),
    );
    if (!mounted) return;
    if (photo == null || photo.isEmpty) {
      scanner.finish();
      await _startCamera();
      return;
    }

    final outcome = await scanner.submit(code: code, photo: photo);
    if (!mounted) return;
    await _showResultAndResume(outcome);
  }

  /// Показывает результат отметки и возвращает сканер в рабочее состояние.
  Future<void> _showResultAndResume(ScanOutcome outcome) async {
    await showScanResultSheet(context, outcome, onOpenSettings: _openSettings);
    if (!mounted) return;
    ref.read(scannerControllerProvider.notifier).finish();
    await _startCamera();
  }

  void _openSettings(LocationSettingsAction action) {
    final settings = ref.read(systemSettingsProvider);
    switch (action) {
      case LocationSettingsAction.appSettings:
        unawaited(settings.openAppSettings());
      case LocationSettingsAction.locationSettings:
        unawaited(settings.openLocationSettings());
      case LocationSettingsAction.none:
        break;
    }
  }

  static String _stageLabel(AppLocalizations l10n, ScanStage stage) =>
      switch (stage) {
        ScanStage.checkingPoint => l10n.stageCheckingPoint,
        ScanStage.checkingFace => l10n.stageCheckingFace,
        ScanStage.checkingLocation => l10n.stageCheckingLocation,
        ScanStage.sendingMark => l10n.stageSendingMark,
      };

  @override
  Widget build(BuildContext context) {
    final stage = ref.watch(scannerControllerProvider).stage;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            key: ValueKey(_cameraEpoch),
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _CameraError(
              error: error,
              onRetry: () => unawaited(_restartCamera()),
              onOpenSettings: () =>
                  ref.read(systemSettingsProvider).openAppSettings(),
            ),
          ),
          // Затемнение с вырезом, уголки рамки и бегущая линия.
          AnimatedBuilder(
            animation: _scanLine,
            builder: (context, _) => CustomPaint(
              painter: _ScannerOverlayPainter(
                progress: Curves.easeInOut.transform(_scanLine.value),
              ),
              size: Size.infinite,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 14),
                const BrandLogo(onDark: true, height: 24),
                const SizedBox(height: 10),
                Text(
                  context.l10n.scanQrTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        context.l10n.pointCameraAtQr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.within50m,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ValueListenableBuilder(
                  valueListenable: _controller,
                  builder: (context, state, _) {
                    final torchOn = state.torchState == TorchState.on;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: torchOn
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.14),
                      ),
                      child: IconButton(
                        onPressed: state.isRunning
                            ? () => _controller.toggleTorch()
                            : null,
                        padding: const EdgeInsets.all(14),
                        icon: Icon(
                          torchOn
                              ? Icons.flashlight_off_outlined
                              : Icons.flashlight_on_outlined,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (stage != null)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      _stageLabel(context.l10n, stage),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter({required this.progress});

  /// 0..1 — позиция бегущей линии внутри рамки.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const frameSize = 264.0;
    final center = Offset(size.width / 2, size.height / 2 - 30);
    final rect =
        Rect.fromCenter(center: center, width: frameSize, height: frameSize);
    final frame = RRect.fromRectAndRadius(rect, const Radius.circular(28));

    final overlay = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(frame),
    );
    canvas.drawPath(
        overlay, Paint()..color = Colors.black.withValues(alpha: 0.55));

    // Уголки рамки.
    const len = 34.0;
    const radius = 28.0;
    final corner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primaryLight;
    final path = Path()
      // верхний левый
      ..moveTo(rect.left, rect.top + len)
      ..lineTo(rect.left, rect.top + radius)
      ..quadraticBezierTo(rect.left, rect.top, rect.left + radius, rect.top)
      ..lineTo(rect.left + len, rect.top)
      // верхний правый
      ..moveTo(rect.right - len, rect.top)
      ..lineTo(rect.right - radius, rect.top)
      ..quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + radius)
      ..lineTo(rect.right, rect.top + len)
      // нижний правый
      ..moveTo(rect.right, rect.bottom - len)
      ..lineTo(rect.right, rect.bottom - radius)
      ..quadraticBezierTo(
          rect.right, rect.bottom, rect.right - radius, rect.bottom)
      ..lineTo(rect.right - len, rect.bottom)
      // нижний левый
      ..moveTo(rect.left + len, rect.bottom)
      ..lineTo(rect.left + radius, rect.bottom)
      ..quadraticBezierTo(
          rect.left, rect.bottom, rect.left, rect.bottom - radius)
      ..lineTo(rect.left, rect.bottom - len);
    canvas.drawPath(path, corner);

    // Бегущая линия с градиентным свечением.
    final y = rect.top + 18 + (rect.height - 36) * progress;
    final lineRect =
        Rect.fromLTRB(rect.left + 22, y - 1.5, rect.right - 22, y + 1.5);
    canvas.drawRect(
      Rect.fromLTRB(rect.left + 22, y - 14, rect.right - 22, y + 14),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0),
            AppColors.primary.withValues(alpha: 0.28),
            AppColors.primary.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTRB(0, y - 14, 0, y + 14)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lineRect, const Radius.circular(2)),
      Paint()..color = AppColors.primaryLight,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _CameraError extends StatelessWidget {
  const _CameraError({
    required this.error,
    this.onRetry,
    this.onOpenSettings,
  });

  final MobileScannerException error;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    final details = error.errorDetails?.message;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_outlined,
                  color: Colors.white38, size: 56),
              const SizedBox(height: 16),
              Text(
                denied ? l10n.cameraNoAccess : l10n.cameraStartFailed,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                denied ? l10n.cameraGrantAccess : l10n.cameraCloseOthers,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              if (details != null && details.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${error.errorCode.name}: $details',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white30, fontSize: 11),
                ),
              ],
              const SizedBox(height: 24),
              if (onRetry != null)
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(l10n.actionRetry),
                ),
              if (onOpenSettings != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onOpenSettings,
                  child: Text(
                    l10n.actionOpenSettings,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
