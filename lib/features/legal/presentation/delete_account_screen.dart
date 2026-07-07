import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../l10n/l10n_ext.dart';
import '../../auth/providers.dart';
import '../legal_content.dart';

/// Удаление учётной записи приложения (App Store §5.1.1(v)).
/// `DELETE /api/mobile/profile/delete/` — полное удаление; данные сотрудника
/// в системе сохраняются, для входа нужна повторная регистрация.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  bool _deleting = false;
  String? _error;

  Future<void> _submit() async {
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

    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      if (!mounted) return;
      // Аккаунт удалён — очищаем сессию и уводим на вход (нужна регистрация).
      await ref
          .read(authControllerProvider.notifier)
          .logout(message: l10n.accountDeleted);
      // Роутер сам перенаправит на экран входа.
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.errorConnection);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
            const Text(
              LegalContent.deleteAccountBody,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14.5,
                height: 1.5,
              ),
            ),
            ErrorBanner(message: _error),
            const SizedBox(height: 24),
            PrimaryButton(
              label: l10n.deleteAccountAction,
              icon: Icons.delete_outline_rounded,
              loading: _deleting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
