import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../l10n/l10n_ext.dart';
import '../../auth/providers.dart';
import '../legal_content.dart';

/// Информационный экран перед вводом ИИН/телефона: цель приложения и какие
/// данные обрабатываются (App Store Review — прозрачность).
class IntroScreen extends ConsumerWidget {
  const IntroScreen({super.key});

  Future<void> _continue(BuildContext context, WidgetRef ref) async {
    await ref.read(tokenStorageProvider).setIntroSeen();
    ref.read(introSeenProvider.notifier).state = true;
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                children: [
                  const SizedBox(height: 8),
                  const Center(child: BrandLogo(height: 40)),
                  const SizedBox(height: 28),
                  const Text(
                    LegalContent.introTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    LegalContent.introBody,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                children: [
                  PrimaryButton(
                    label: context.l10n.actionContinue,
                    onPressed: () => _continue(context, ref),
                  ),
                  TextButton(
                    onPressed: () => context.push('/privacy'),
                    child: Text(context.l10n.privacyPolicy),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
