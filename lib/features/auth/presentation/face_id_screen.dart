import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/frame_quality.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_ext.dart';
import '../providers.dart';

enum _CameraFailure { denied, start }

/// FaceID перед QR-отметкой: live-снимок фронтальной камеры. Экран возвращает
/// base64-фото лица; сверку с базовым фото сотрудника сервер делает при скане
/// (`POST /api/qr/scan/`), отдельного запроса сверки нет.
class FaceIdScreen extends ConsumerStatefulWidget {
  const FaceIdScreen({super.key});

  @override
  ConsumerState<FaceIdScreen> createState() => _FaceIdScreenState();
}

class _FaceIdScreenState extends ConsumerState<FaceIdScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _camera;
  bool _initializing = true;
  _CameraFailure? _cameraError;
  bool _checking = false;
  bool _selectingFrame = false;
  String? _error;
  int _attemptsLeft = AppConfig.faceIdMaxAttempts;
  int _cameraGeneration = 0;
  int _goodFrameCount = 0;
  bool _captureStarted = false;
  DateTime? _lastFrameAnalysis;
  Timer? _warmupTimer;
  Timer? _selectionDeadline;

  /// Пульсация рамки вокруг камеры — «живой» индикатор готовности.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final hasEmployeePhoto =
        ref.read(authControllerProvider).employee?.hasPhoto ?? false;
    if (hasEmployeePhoto) {
      unawaited(_initCamera());
    } else {
      _initializing = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelAutomaticCapture();
    _pulse.dispose();
    final camera = _camera;
    _camera = null;
    if (camera != null) unawaited(_disposeCamera(camera));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cancelAutomaticCapture();
      final camera = _camera;
      _camera = null;
      if (camera != null) unawaited(_disposeCamera(camera));
    } else if (state == AppLifecycleState.resumed && _camera == null) {
      unawaited(_initCamera());
    }
  }

  Future<void> _initCamera() async {
    final generation = ++_cameraGeneration;
    _cancelCaptureTimers();
    if (!mounted) return;
    setState(() {
      _initializing = true;
      _cameraError = null;
      _checking = false;
      _selectingFrame = false;
      _captureStarted = false;
    });
    try {
      final previous = _camera;
      _camera = null;
      if (previous != null) await _disposeCamera(previous);
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted || generation != _cameraGeneration) return;
        setState(() {
          _initializing = false;
          _cameraError = _CameraFailure.denied;
        });
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      if (!mounted || generation != _cameraGeneration) {
        await _disposeCamera(controller);
        return;
      }
      setState(() {
        _camera = controller;
        _initializing = false;
      });
      _scheduleAutomaticCapture(controller, generation);
    } on CameraException catch (e) {
      if (!mounted || generation != _cameraGeneration) return;
      setState(() {
        _initializing = false;
        _cameraError = e.code == 'CameraAccessDenied'
            ? _CameraFailure.denied
            : _CameraFailure.start;
      });
    } catch (_) {
      if (!mounted || generation != _cameraGeneration) return;
      setState(() {
        _initializing = false;
        _cameraError = _CameraFailure.start;
      });
    }
  }

  void _scheduleAutomaticCapture(
    CameraController camera,
    int generation, {
    Duration delay = AppConfig.faceCaptureWarmup,
  }) {
    _cancelCaptureTimers();
    _goodFrameCount = 0;
    _lastFrameAnalysis = null;
    _captureStarted = false;
    _warmupTimer = Timer(
      delay,
      () => unawaited(_startFrameSelection(camera, generation)),
    );
  }

  Future<void> _startFrameSelection(
    CameraController camera,
    int generation,
  ) async {
    if (!_isCurrent(camera, generation) || _captureStarted) return;
    setState(() {
      _selectingFrame = true;
      _error = null;
    });
    try {
      await camera.startImageStream(_onCameraImage);
      if (!_isCurrent(camera, generation)) return;
      _selectionDeadline = Timer(
        AppConfig.faceCaptureSelectionWindow,
        () => unawaited(_capturePhoto(camera, generation)),
      );
    } on CameraException {
      // Некоторые устройства не поддерживают стабильный image stream.
      // В этом случае сохраняем быстрый автоматический снимок без анализа.
      await _capturePhoto(camera, generation);
    }
  }

  void _onCameraImage(CameraImage image) {
    if (!_selectingFrame || _captureStarted) return;
    final now = DateTime.now();
    final previous = _lastFrameAnalysis;
    if (previous != null &&
        now.difference(previous) < AppConfig.faceFrameAnalysisInterval) {
      return;
    }
    _lastFrameAnalysis = now;

    final quality = _qualityScore(image);
    if (quality >= AppConfig.faceMinimumFrameQuality) {
      _goodFrameCount++;
    } else {
      _goodFrameCount = 0;
    }
    if (_goodFrameCount >= AppConfig.faceRequiredQualityFrames) {
      final camera = _camera;
      if (camera != null) {
        unawaited(_capturePhoto(camera, _cameraGeneration));
      }
    }
  }

  double _qualityScore(CameraImage image) {
    if (image.planes.isEmpty) return 0;
    final plane = image.planes.first;
    if (image.format.group == ImageFormatGroup.bgra8888) {
      return FrameQuality.scoreBgraPlane(
        plane.bytes,
        width: image.width,
        height: image.height,
        bytesPerRow: plane.bytesPerRow,
        bytesPerPixel: plane.bytesPerPixel ?? 4,
      );
    }
    return FrameQuality.scoreLuminancePlane(
      plane.bytes,
      width: image.width,
      height: image.height,
      bytesPerRow: plane.bytesPerRow,
      bytesPerPixel: plane.bytesPerPixel ?? 1,
    );
  }

  Future<void> _capturePhoto(
    CameraController camera,
    int generation,
  ) async {
    if (!_isCurrent(camera, generation) || _captureStarted) return;
    _captureStarted = true;
    _selectionDeadline?.cancel();
    setState(() {
      _selectingFrame = false;
      _checking = true;
    });
    try {
      if (camera.value.isStreamingImages) {
        await camera.stopImageStream();
      }
      await Future<void>.delayed(AppConfig.faceCaptureSettleDelay);
      if (!_isCurrent(camera, generation)) return;
      final shot = await camera.takePicture();
      final bytes = await shot.readAsBytes();
      final imageBase64 = base64Encode(bytes);
      if (!mounted) return;
      // Снимок отправится в /api/qr/scan/ — сервер сверит лицо при отметке.
      Navigator.of(context).pop(imageBase64);
    } on CameraException {
      await _failAndRetry(camera, generation);
    } catch (_) {
      await _failAndRetry(camera, generation);
    }
  }

  /// Сырой (нелокализованный) ключ — переводится на показе через
  /// `localizedMessage`, чтобы текст не «замораживался» в языке момента
  /// ошибки при последующей смене языка.
  Future<void> _failAndRetry(
    CameraController camera,
    int generation,
  ) async {
    if (camera.value.isStreamingImages) {
      try {
        await camera.stopImageStream();
      } on CameraException {
        // Повторная попытка сама покажет, пригодна ли камера дальше.
      }
    }
    if (!_isCurrent(camera, generation)) return;
    setState(() {
      _attemptsLeft -= 1;
      _error = 'Не удалось сделать снимок. Попробуйте ещё раз';
      _checking = false;
      _selectingFrame = false;
      _captureStarted = false;
    });
    if (_attemptsLeft > 0) {
      _scheduleAutomaticCapture(
        camera,
        generation,
        delay: AppConfig.faceCaptureRetryDelay,
      );
    }
  }

  bool _isCurrent(CameraController camera, int generation) =>
      mounted && generation == _cameraGeneration && identical(_camera, camera);

  void _cancelCaptureTimers() {
    _warmupTimer?.cancel();
    _selectionDeadline?.cancel();
    _warmupTimer = null;
    _selectionDeadline = null;
  }

  void _cancelAutomaticCapture() {
    _cameraGeneration++;
    _cancelCaptureTimers();
  }

  Future<void> _disposeCamera(CameraController camera) async {
    try {
      if (camera.value.isStreamingImages) await camera.stopImageStream();
    } on CameraException {
      // dispose всё равно должен освободить нативную камеру.
    }
    await camera.dispose();
  }

  void _cancel() {
    _cancelAutomaticCapture();
    Navigator.of(context).pop<String>();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final employee = ref.watch(authControllerProvider).employee;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.navyGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SizedBox.expand(
              child: _buildBody(
                  l10n, employee?.hasPhoto ?? false, employee?.firstName),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, bool hasPhoto, String? firstName) {
    // Без фото в базе подтвердить личность перед отметкой нельзя.
    if (!hasPhoto) {
      return _MessageView(
        icon: Icons.no_photography_outlined,
        title: l10n.noEmployeePhoto,
        subtitle: l10n.noEmployeePhotoNote,
        actionLabel: l10n.backToScanner,
        onAction: _cancel,
      );
    }

    if (_attemptsLeft <= 0) {
      return _MessageView(
        icon: Icons.lock_outline,
        title: l10n.faceAttemptsExceeded,
        subtitle: _error == null
            ? l10n.scanQrTryAgain
            : context.localizedMessage(_error),
        actionLabel: l10n.backToScanner,
        onAction: _cancel,
      );
    }

    if (_cameraError != null) {
      return _MessageView(
        icon: Icons.videocam_off_outlined,
        title: _cameraError == _CameraFailure.denied
            ? l10n.cameraNoAccess
            : l10n.cameraStartFailed,
        subtitle: l10n.cameraGrantAccess,
        actionLabel: l10n.actionOpenSettings,
        onAction: () => Geolocator.openAppSettings(),
        secondaryLabel: l10n.actionRetry,
        onSecondary: _initCamera,
        tertiaryLabel: l10n.actionCancel,
        onTertiary: _cancel,
      );
    }

    final camera = _camera;
    return Column(
      children: [
        const SizedBox(height: 4),
        const BrandLogo(onDark: true, height: 26),
        const SizedBox(height: 22),
        Text(
          firstName == null || firstName.isEmpty
              ? l10n.identityCheck
              : l10n.identityCheckName(firstName),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.photoVerifyBeforeScan,
          style: const TextStyle(color: Colors.white60),
        ),
        const Spacer(),
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_pulse.value);
            return Container(
              width: 304,
              height: 304,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      AppColors.primaryLight.withValues(alpha: 0.25 + 0.35 * t),
                  width: 2 + 6 * t,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25 * t),
                    blurRadius: 36 * t,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
            ),
            padding: const EdgeInsets.all(6),
            child: ClipOval(
              child: _initializing || camera == null
                  ? const ColoredBox(
                      color: Colors.black26,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    )
                  : _CameraCircle(camera: camera),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _selectingFrame || _checking
              ? l10n.stageCheckingFace
              : l10n.lookAtCamera,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.photoComparedNote,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            context.localizedMessage(_error),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.danger),
          ),
        ],
        if (_attemptsLeft < AppConfig.faceIdMaxAttempts) ...[
          const SizedBox(height: 6),
          Text(
            l10n.attemptsLeft(_attemptsLeft),
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
        const Spacer(),
        SizedBox(
          height: 28,
          child: AnimatedOpacity(
            opacity: _selectingFrame || _checking ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: const Center(
              child: SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: _cancel,
          child: Text(
            l10n.actionCancel,
            style: const TextStyle(color: Colors.white54),
          ),
        ),
      ],
    );
  }
}

class _CameraCircle extends StatelessWidget {
  const _CameraCircle({required this.camera});

  final CameraController camera;

  @override
  Widget build(BuildContext context) {
    final previewSize = camera.value.previewSize;
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        // Превью приходит в альбомной ориентации — меняем стороны местами.
        width: previewSize?.height ?? 292,
        height: previewSize?.width ?? 292,
        child: CameraPreview(camera),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.tertiaryLabel,
    this.onTertiary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final String? tertiaryLabel;
  final VoidCallback? onTertiary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white38, size: 64),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54),
        ),
        const SizedBox(height: 28),
        PrimaryButton(label: actionLabel, onPressed: onAction),
        if (secondaryLabel != null)
          TextButton(
            onPressed: onSecondary,
            child: Text(
              secondaryLabel!,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        if (tertiaryLabel != null)
          TextButton(
            onPressed: onTertiary,
            child: Text(
              tertiaryLabel!,
              style: const TextStyle(color: Colors.white38),
            ),
          ),
      ],
    );
  }
}
