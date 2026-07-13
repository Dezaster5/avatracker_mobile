import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n_ext.dart';
import '../../auth/presentation/face_id_screen.dart';
import '../../auth/providers.dart';
import '../domain/scan_result.dart';
import '../providers.dart';
import 'scan_result_sheet.dart';

/// QR-сканер (ТЗ 7, 19.4): скан -> геолокация с проверками -> отметка.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static MobileScannerController _newController() => MobileScannerController(
        autoStart: false,
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: const [BarcodeFormat.qrCode],
      );

  /// Камера — глобальный ресурс процесса. ShellRoute может удалить старый
  /// ScannerScreen и создать новый почти в одном кадре, поэтому stop/dispose
  /// старого и start нового должны выполняться строго последовательно.
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

  bool _busy = false;
  String _stage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  Future<void> _startCamera() {
    final controller = _controller;
    return _enqueueCamera(() async {
      if (_disposed ||
          !mounted ||
          _busy ||
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

  /// QR может содержать как чистый идентификатор, так и JSON
  /// `{"qr_id": "park_karaganda_..."}` (ТЗ 7.1).
  static String _parseQrId(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('{')) {
      try {
        final json = jsonDecode(trimmed);
        if (json is Map && json['qr_id'] != null) {
          return json['qr_id'].toString();
        }
      } catch (_) {/* не JSON — используем как есть */}
    }
    return trimmed;
  }

  void _onDetect(BarcodeCapture capture) {
    if (_busy) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    _processScan(_parseQrId(raw));
  }

  /// Показывает результат отметки и возвращает сканер в рабочее состояние.
  Future<void> _showResultAndResume(
    ScanResult result, {
    String? settingsLabel,
    VoidCallback? onSettings,
  }) async {
    if (!mounted) return;
    await showScanResultSheet(
      context,
      result,
      settingsLabel: settingsLabel,
      onSettings: onSettings,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    await _startCamera();
  }

  Future<void> _processScan(String qrId) async {
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _stage = l10n.stageCheckingPoint;
    });
    await _stopCamera();
    if (!mounted) return;

    // Пред-проверка QR: незарегистрированную/отключённую точку отсекаем до
    // FaceID, чтобы не гонять сотрудника делать селфи зря.
    try {
      final point = await ref.read(attendanceRepositoryProvider).qrPoint(qrId);
      if (!point.isActive) {
        await _showResultAndResume(ScanResult.failure(l10n.pointDisabled));
        return;
      }
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // Показываем сам код из QR — видно расхождение (дефис/подчёркивание).
        await _showResultAndResume(
          ScanResult.failure(
            '${l10n.qrNotRegistered}\n${l10n.qrCodeValue(qrId)}',
            errorCode: 'QR_NOT_FOUND',
          ),
        );
        return;
      }
      // Иная ошибка пред-проверки — не блокируем, решение примет сам scan.
    } catch (_) {/* сеть/формат — пусть решит scan */}

    if (!mounted) return;
    setState(() => _stage = l10n.stageCheckingFace);

    // Экран FaceID возвращает base64-снимок лица; сверку делает сервер при скане.
    final photo = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const FaceIdScreen(),
      ),
    );
    if (!mounted) return;
    if (photo == null || photo.isEmpty) {
      setState(() => _busy = false);
      await _startCamera();
      return;
    }

    setState(() => _stage = l10n.stageCheckingLocation);

    String? settingsLabel;
    VoidCallback? onSettings;
    ScanResult result;
    var success = false;
    try {
      // Без геолокации сканирование запрещено (ТЗ 7.3).
      final position =
          await ref.read(locationServiceProvider).getValidatedPosition();

      if (!mounted) return;
      setState(() => _stage = l10n.stageSendingMark);

      final auth = ref.read(authControllerProvider);
      final iin = auth.employee?.iin ?? '';
      result = await ref.read(attendanceRepositoryProvider).scan(
            iin: iin,
            qrId: qrId,
            position: position,
            photo: photo,
          );
      success = result.success;
    } on LocationFailure catch (e) {
      final message = switch (e.code) {
        LocationFailureCode.serviceDisabled => l10n.locationEnableGps,
        LocationFailureCode.permissionDenied => l10n.locationPermissionRequired,
        LocationFailureCode.unavailable => l10n.locationUnavailable,
        LocationFailureCode.mocked => l10n.locationMocked,
        LocationFailureCode.lowAccuracy =>
          l10n.locationLowAccuracy(e.accuracyMeters ?? 0),
      };
      result = ScanResult.failure(message);
      if (e.settings != LocationSettingsAction.none) {
        settingsLabel = e.settings == LocationSettingsAction.appSettings
            ? l10n.actionOpenSettings
            : l10n.actionEnableLocation;
        onSettings =
            () => ref.read(locationServiceProvider).openSettings(e.settings);
      }
    } on ApiException catch (e) {
      result = ScanResult.failure(e.message, errorCode: e.code);
    } catch (_) {
      result = ScanResult.failure(l10n.noServerConnection);
    }

    if (!mounted) return;
    if (success) {
      // Обновляем оба источника данных учета рабочего времени.
      ref.invalidate(tardinessAnalyticsProvider);
      ref.invalidate(timesheetProvider);
    }
    await _showResultAndResume(
      result,
      settingsLabel: settingsLabel,
      onSettings: onSettings,
    );
  }

  @override
  Widget build(BuildContext context) {
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
              onOpenSettings: () => ref
                  .read(locationServiceProvider)
                  .openSettings(LocationSettingsAction.appSettings),
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
          if (_busy)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      _stage,
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
