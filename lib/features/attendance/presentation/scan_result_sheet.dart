import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../l10n/l10n_ext.dart';
import '../domain/scan_result.dart';

/// Результат отметки (ТЗ 19.4): успех — тип отметки, парк, расстояние;
/// отказ — текст ошибки по ТЗ 7.4.
Future<void> showScanResultSheet(
  BuildContext context,
  ScanResult result, {
  String? settingsLabel,
  VoidCallback? onSettings,
}) {
  final color = result.success ? AppColors.success : AppColors.danger;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      final markLabel = switch (result.markType) {
        'check_in' => l10n.markCheckIn,
        'check_out' => l10n.markCheckOut,
        'presence' => l10n.markPresence,
        _ => '',
      };
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.4, end: 1),
                duration: const Duration(milliseconds: 380),
                curve: Curves.elasticOut,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(
                    result.success ? Icons.check_rounded : Icons.close_rounded,
                    color: color,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                result.success ? l10n.markAccepted : l10n.markNotAccepted,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (result.success && result.markType != null) ...[
                StatusChip(label: markLabel, color: color),
                const SizedBox(height: 10),
              ],
              Text(
                l10n.localizeKnownMessage(result.message),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              if (result.park != null)
                _DetailRow(label: l10n.resultLocation, value: result.park!),
              if (result.distanceMeters != null)
                _DetailRow(
                  label: l10n.resultDistance,
                  value: result.allowedRadius == null
                      ? l10n.distanceMeters(result.distanceMeters!)
                      : l10n.distanceWithLimit(
                          result.distanceMeters!,
                          result.allowedRadius!,
                        ),
                ),
              if (result.scannedAt != null)
                _DetailRow(
                  label: l10n.resultTime,
                  value: formatTime(result.scannedAt!.toLocal()),
                ),
              const SizedBox(height: 20),
              if (onSettings != null && settingsLabel != null) ...[
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    onSettings();
                  },
                  child: Text(settingsLabel),
                ),
                const SizedBox(height: 10),
              ],
              PrimaryButton(
                label: result.success ? l10n.actionDone : l10n.actionUnderstood,
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
