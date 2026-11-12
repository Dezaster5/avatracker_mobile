import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/failure_l10n.dart';
import '../../../../l10n/l10n_ext.dart';
import '../../domain/entities/scan_result.dart';
import '../controllers/scanner_controller.dart';

/// Результат отметки (ТЗ 19.4): успех — тип отметки, парк, расстояние;
/// отказ — текст ошибки по ТЗ 7.4 и, если поможет, переход в настройки.
Future<void> showScanResultSheet(
  BuildContext context,
  ScanOutcome outcome, {
  required ValueChanged<LocationSettingsAction> onOpenSettings,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ScanResultSheet(
      outcome: outcome,
      onOpenSettings: onOpenSettings,
    ),
  );
}

class _ScanResultSheet extends StatelessWidget {
  const _ScanResultSheet({
    required this.outcome,
    required this.onOpenSettings,
  });

  final ScanOutcome outcome;
  final ValueChanged<LocationSettingsAction> onOpenSettings;

  ScanResult? get _result => switch (outcome) {
        ScanCompleted(:final result) => result,
        ScanFailed() => null,
      };

  /// Ошибку геолокации можно исправить в системных настройках.
  LocationSettingsAction? get _settingsAction => switch (outcome) {
        ScanFailed(failure: LocationFailure(:final settings))
            when settings != LocationSettingsAction.none =>
          settings,
        _ => null,
      };

  String _message(AppLocalizations l10n) => switch (outcome) {
        ScanCompleted(:final result) => result.message ??
            (result.success ? l10n.markAccepted : l10n.markNotAccepted),
        ScanFailed(:final failure) => l10n.failureMessage(failure),
      };

  static String _markLabel(AppLocalizations l10n, MarkType type) =>
      switch (type) {
        MarkType.checkIn => l10n.markCheckIn,
        MarkType.checkOut => l10n.markCheckOut,
        MarkType.presence => l10n.markPresence,
        MarkType.other => '',
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = _result;
    final success = result?.success ?? false;
    final color = success ? AppColors.success : AppColors.danger;
    final markType = result?.markType;
    final settingsAction = _settingsAction;

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
                  success ? Icons.check_rounded : Icons.close_rounded,
                  color: color,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              success ? l10n.markAccepted : l10n.markNotAccepted,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (success && markType != null) ...[
              StatusChip(label: _markLabel(l10n, markType), color: color),
              const SizedBox(height: 10),
            ],
            Text(
              _message(l10n),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            if (result != null) _ResultDetails(result: result),
            const SizedBox(height: 20),
            if (settingsAction != null) ...[
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onOpenSettings(settingsAction);
                },
                child: Text(
                  settingsAction == LocationSettingsAction.appSettings
                      ? l10n.actionOpenSettings
                      : l10n.actionEnableLocation,
                ),
              ),
              const SizedBox(height: 10),
            ],
            PrimaryButton(
              label: success ? l10n.actionDone : l10n.actionUnderstood,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultDetails extends StatelessWidget {
  const _ResultDetails({required this.result});

  final ScanResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final park = result.park;
    final distance = result.distanceMeters;
    final allowedRadius = result.allowedRadius;
    final scannedAt = result.scannedAt;
    return Column(
      children: [
        if (park != null) _DetailRow(label: l10n.resultLocation, value: park),
        if (distance != null)
          _DetailRow(
            label: l10n.resultDistance,
            value: allowedRadius == null
                ? l10n.distanceMeters(distance)
                : l10n.distanceWithLimit(distance, allowedRadius),
          ),
        if (scannedAt != null)
          _DetailRow(
            label: l10n.resultTime,
            value: formatTime(scannedAt.toLocal()),
          ),
      ],
    );
  }
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
          Text(
            label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
