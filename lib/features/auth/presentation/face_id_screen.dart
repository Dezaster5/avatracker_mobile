import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers.dart';

/// FaceID-сверка перед QR-отметкой: live-снимок отправляется на сервер вместе
/// с QR ID. При успехе экран возвращает одноразовый verification token.
class FaceIdScreen extends ConsumerStatefulWidget {
  const FaceIdScreen({super.key, required this.qrId});

  final String qrId;

  @override
  ConsumerState<FaceIdScreen> createState() => _FaceIdScreenState();
}

class _FaceIdScreenState extends ConsumerState<FaceIdScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _camera;
  bool _initializing = true;
  String? _cameraError;
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
          _cameraError = 'Нет доступа к камере';
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
            ? 'Нет доступа к камере'
            : 'Не удалось запустить камеру';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _cameraError = 'Не удалось запустить камеру';
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

      final iin = ref.read(authControllerProvider).employee?.iin ?? '';
      final result = await ref.read(authRepositoryProvider).faceVerify(
            iin: iin,
            imageBase64: imageBase64,
            qrId: widget.qrId,
          );
      if (!mounted) return;
      if (result.accessGranted) {
        final token = result.verificationToken;
        if (token == null || token.isEmpty) {
          _fail('Сервер не вернул подтверждение FaceID');
          return;
        }
        Navigator.of(context).pop(token);
        return;
      }
      _fail(result.message ?? 'Лицо не совпадает с профилем сотрудника');
    } on ApiException catch (e) {
      _fail(e.message);
    } on CameraException {
      _fail('Не удалось распознать лицо. Попробуйте еще раз');
    } catch (_) {
      _fail('Не удалось распознать лицо. Попробуйте еще раз');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _attemptsLeft -= 1;
      _error = message;
    });
  }

  void _cancel() => Navigator.of(context).pop<String>();

  @override
  Widget build(BuildContext context) {
    final employee = ref.watch(authControllerProvider).employee;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.navyGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SizedBox.expand(
              child:
                  _buildBody(employee?.hasPhoto ?? false, employee?.firstName),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool hasPhoto, String? firstName) {
    // Без фото в базе подтвердить личность перед отметкой нельзя.
    if (!hasPhoto) {
      return _MessageView(
        icon: Icons.no_photography_outlined,
        title: 'В системе отсутствует фото сотрудника',
        subtitle:
            'Отметка невозможна. Обратитесь к администратору, чтобы добавить фото в AvaTracker.',
        actionLabel: 'Вернуться к сканеру',
        onAction: _cancel,
      );
    }

    if (_attemptsLeft <= 0) {
      return _MessageView(
        icon: Icons.lock_outline,
        title: 'Превышено количество попыток FaceID',
        subtitle: _error ?? 'Отсканируйте QR-код и попробуйте снова',
        actionLabel: 'Вернуться к сканеру',
        onAction: _cancel,
      );
    }

    if (_cameraError != null) {
      return _MessageView(
        icon: Icons.videocam_off_outlined,
        title: _cameraError!,
        subtitle: 'Разрешите доступ к камере в настройках приложения',
        actionLabel: 'Открыть настройки',
        onAction: () => Geolocator.openAppSettings(),
        secondaryLabel: 'Повторить',
        onSecondary: _initCamera,
        tertiaryLabel: 'Отмена',
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
              ? 'Подтверждение личности'
              : '$firstName, подтвердите личность',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Проверка обязательна перед каждой QR-отметкой',
          style: TextStyle(color: Colors.white60),
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
        const Text(
          'Посмотрите в камеру',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Лицо будет сверено с вашей фотографией в системе AvaTracker',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.danger),
          ),
        ],
        if (_attemptsLeft < AppConfig.faceIdMaxAttempts) ...[
          const SizedBox(height: 6),
          Text(
            'Осталось попыток: $_attemptsLeft',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
        const Spacer(),
        PrimaryButton(
          label: 'Подтвердить и продолжить',
          icon: Icons.face_retouching_natural,
          loading: _checking,
          onPressed: camera == null ? null : _verify,
        ),
        TextButton(
          onPressed: _checking ? null : _cancel,
          child: const Text('Отмена', style: TextStyle(color: Colors.white54)),
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
