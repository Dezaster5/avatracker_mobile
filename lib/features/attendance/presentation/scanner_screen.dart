import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_theme.dart';
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
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  /// Бегущая линия сканирования внутри рамки.
  late final AnimationController _scanLine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  bool _busy = false;
  String _stage = '';

  @override
  void dispose() {
    _scanLine.dispose();
    _controller.dispose();
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

  Future<void> _processScan(String qrId) async {
    setState(() {
      _busy = true;
      _stage = 'Подготовка FaceID…';
    });
    await _controller.stop();
    if (!mounted) return;

    final faceToken = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FaceIdScreen(qrId: qrId),
      ),
    );
    if (!mounted) return;
    if (faceToken == null || faceToken.isEmpty) {
      setState(() => _busy = false);
      await _controller.start();
      return;
    }

    setState(() => _stage = 'Проверка геолокации…');

    String? settingsLabel;
    VoidCallback? onSettings;
    ScanResult result;
    var success = false;
    try {
      // Без геолокации сканирование запрещено (ТЗ 7.3).
      final position =
          await ref.read(locationServiceProvider).getValidatedPosition();

      if (!mounted) return;
      setState(() => _stage = 'Отправка отметки…');

      final auth = ref.read(authControllerProvider);
      final iin = auth.employee?.iin ?? '';
      result = await ref.read(attendanceRepositoryProvider).scan(
            iin: iin,
            qrId: qrId,
            position: position,
            faceVerificationToken: faceToken,
          );
      success = result.success;
    } on LocationFailure catch (e) {
      result = ScanResult.failure(e.message);
      if (e.settings != LocationSettingsAction.none) {
        settingsLabel = e.settings == LocationSettingsAction.appSettings
            ? 'Открыть настройки'
            : 'Включить геолокацию';
        onSettings =
            () => ref.read(locationServiceProvider).openSettings(e.settings);
      }
    } on ApiException catch (e) {
      result = ScanResult.failure(e.message, errorCode: e.code);
    } catch (_) {
      result = ScanResult.failure('Нет соединения с сервером');
    }

    if (!mounted) return;
    if (success) {
      // Аналитика зависит от табеля и обновится вместе с ним.
      ref.invalidate(timesheetProvider);
    }
    await showScanResultSheet(
      context,
      result,
      settingsLabel: settingsLabel,
      onSettings: onSettings,
    );

    if (!mounted) return;
    setState(() => _busy = false);
    await _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) => _CameraError(error: error),
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
                const Text(
                  'Отметка по QR-коду',
                  style: TextStyle(
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
                  child: const Column(
                    children: [
                      Text(
                        'Наведите камеру на QR-код',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Вы должны находиться не далее 50 м от точки отметки',
                        style: TextStyle(color: Colors.white70, fontSize: 12.5),
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
                        onPressed: () => _controller.toggleTorch(),
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
  const _CameraError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
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
                denied ? 'Нет доступа к камере' : 'Не удалось запустить камеру',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Разрешите доступ к камере в настройках приложения, '
                'чтобы сканировать QR-коды',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
