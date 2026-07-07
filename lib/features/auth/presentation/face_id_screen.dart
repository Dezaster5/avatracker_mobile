import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
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
  String? _error;
  int _attemptsLeft = AppConfig.faceIdMaxAttempts;

  /// Пульсация рамки вокруг камеры — «живой» индикатор готовности.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulse.dispose();
    _camera?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      camera.dispose();
      _camera = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    setState(() {
      _initializing = true;
      _cameraError = null;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
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
      final controller =
          CameraController(front, ResolutionPreset.medium, enableAudio: false);
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _initializing = false;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _cameraError = e.code == 'CameraAccessDenied'
            ? _CameraFailure.denied
            : _CameraFailure.start;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _cameraError = _CameraFailure.start;
      });
    }
  }

  Future<void> _verify() async {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized || _checking) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final shot = await camera.takePicture();
      final bytes = await shot.readAsBytes();
      final imageBase64 = base64Encode(bytes);
      if (!mounted) return;
      // Снимок отправится в /api/qr/scan/ — сервер сверит лицо при отметке.
      Navigator.of(context).pop(imageBase64);
    } on CameraException {
      _fail();
    } catch (_) {
      _fail();
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  /// Сырой (нелокализованный) ключ — переводится на показе через
  /// `localizedMessage`, чтобы текст не «замораживался» в языке момента
  /// ошибки при последующей смене языка.
  void _fail() {
    if (!mounted) return;
    setState(() {
      _attemptsLeft -= 1;
      _error = 'Не удалось сделать снимок. Попробуйте ещё раз';
    });
  }

  void _cancel() => Navigator.of(context).pop<String>();

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
          l10n.lookAtCamera,
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
        PrimaryButton(
          label: l10n.confirmAndContinue,
          icon: Icons.face_retouching_natural,
          loading: _checking,
          onPressed: camera == null ? null : _verify,
        ),
        TextButton(
          onPressed: _checking ? null : _cancel,
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
