import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/l10n_ext.dart';
import '../../../auth/presentation/controllers/delete_account_controller.dart';

/// Удаление учётной записи приложения (App Store §5.1.1(v)).
/// `DELETE /api/mobile/profile/delete/` — полное удаление; данные сотрудника
/// в системе сохраняются, для входа нужна повторная регистрация.
class DeleteAccountScreen extends ConsumerWidget {
  const DeleteAccountScreen({super.key});

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteConfirmTitle),
        content: Text(l10n.deleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.actionDelete,
                style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // При успехе роутер сам уведёт на экран входа.
    await ref.read(deleteAccountControllerProvider.notifier).delete();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(deleteAccountControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deleteAccountTitle),
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.deleteAccountBody,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14.5,
                height: 1.5,
              ),
            ),
            ErrorBanner(failure: state.failure),
            const SizedBox(height: 24),
            PrimaryButton(
              label: l10n.deleteAccountAction,
              icon: Icons.delete_outline_rounded,
              loading: state.deleting,
              onPressed: () => _submit(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
