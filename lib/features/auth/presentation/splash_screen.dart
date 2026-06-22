import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../providers.dart';

/// Splash: проверяет токен и активность сотрудника.
/// FaceID выполняется только перед QR-отметкой.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(authControllerProvider.notifier).bootstrap(),
    );
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final fade = CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.navyGradient),
        child: SafeArea(
          child: SizedBox.expand(
            child: Column(
              children: [
                const Spacer(flex: 2),
                FadeTransition(
                  opacity: fade,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.85, end: 1.0).animate(fade),
                    child: const BrandLogo(onDark: true, height: 52),
                  ),
                ),
                const SizedBox(height: 14),
                FadeTransition(
                  opacity: fade,
                  child: const Text(
                    'Учет рабочего времени',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                SizedBox(
                  height: 160,
                  child: auth.status == AuthStatus.failed
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: [
                              const Icon(Icons.wifi_off_rounded,
                                  color: Colors.white38, size: 32),
                              const SizedBox(height: 10),
                              Text(
                                auth.message ??
                                    'Ошибка соединения. Попробуйте позже',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white38),
                                  minimumSize: const Size(160, 44),
                                ),
                                onPressed: () => ref
                                    .read(authControllerProvider.notifier)
                                    .bootstrap(),
                                child: const Text('Повторить'),
                              ),
                            ],
                          ),
                        )
                      : const Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              color: Colors.white70,
                              strokeWidth: 2.6,
                            ),
                          ),
                        ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 18),
                  child: Text(
                    'AVATARIYA • AvaTracker',
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 12,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
