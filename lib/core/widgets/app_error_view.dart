import 'package:flutter/material.dart';

import '../../l10n/failure_l10n.dart';
import '../../l10n/l10n_ext.dart';
import '../theme/app_theme.dart';

/// Ошибка загрузки экрана с кнопкой повтора.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  /// Ошибка из `AsyncValue.error` — обычно `Failure`.
  final Object error;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              context.l10n.errorMessage(error),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(context.l10n.actionRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
