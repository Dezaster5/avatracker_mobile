import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/i18n/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n_ext.dart';
import '../../auth/providers.dart';

/// Раздел «О приложении»: версия, язык, Политика, согласие, удаление, поддержка.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  String _languageName(BuildContext context, String code) => switch (code) {
        'kk' => context.l10n.languageKazakh,
        'uz' => context.l10n.languageUzbek,
        _ => context.l10n.languageRussian,
      };

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final current = ref.read(localeProvider).languageCode;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              sheetContext.l10n.chooseLanguage,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            for (final code in const ['ru', 'kk', 'uz'])
              ListTile(
                title: Text(_languageName(sheetContext, code)),
                trailing: code == current
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(code),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (selected != null && selected != current) {
      ref.read(localeProvider.notifier).state = Locale(selected);
      await ref.read(tokenStorageProvider).saveLocale(selected);
    }
  }

  Future<void> _showConsent(BuildContext context, WidgetRef ref) async {
    final consent = await ref.read(tokenStorageProvider).readConsent();
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.consentMenu),
        content: Text(
          consent == null
              ? 'Согласие оформляется при регистрации аккаунта.'
              : 'Вы дали согласие на обработку персональных данных.\n\n'
                  'Версия: ${consent['consent_version'] ?? '—'}\n'
                  'Дата: ${consent['consent_given_at'] ?? '—'}',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.l10n.actionClose),
          ),
        ],
      ),
    );
  }

  void _showSupport(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.support),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'По вопросам работы приложения и обработки данных:',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 10),
            const SelectableText(
              AppConfig.supportEmail,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(
                  const ClipboardData(text: AppConfig.supportEmail));
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Скопировать e-mail'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.l10n.actionClose),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final localeCode = ref.watch(localeProvider).languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.about),
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 12),
            const Center(child: BrandMark(size: 56)),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'AvaTracker',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                l10n.aboutSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13.5),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                l10n.versionLabel(AppConfig.appVersion.replaceFirst('v', '')),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12.5),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Column(
                children: [
                  _AboutTile(
                    icon: Icons.translate_rounded,
                    title: l10n.language,
                    trailingText: _languageName(context, localeCode),
                    onTap: () => _pickLanguage(context, ref),
                    first: true,
                  ),
                  const _AboutDivider(),
                  _AboutTile(
                    icon: Icons.privacy_tip_outlined,
                    title: l10n.privacyPolicy,
                    onTap: () => context.push('/privacy'),
                  ),
                  const _AboutDivider(),
                  _AboutTile(
                    icon: Icons.fact_check_outlined,
                    title: l10n.consentMenu,
                    onTap: () => _showConsent(context, ref),
                  ),
                  const _AboutDivider(),
                  _AboutTile(
                    icon: Icons.support_agent_outlined,
                    title: l10n.support,
                    onTap: () => _showSupport(context),
                  ),
                  const _AboutDivider(),
                  _AboutTile(
                    icon: Icons.delete_outline_rounded,
                    title: l10n.deleteAccountMenu,
                    danger: true,
                    onTap: () => context.push('/delete-account'),
                    last: true,
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

class _AboutDivider extends StatelessWidget {
  const _AboutDivider();
  @override
  Widget build(BuildContext context) => const Divider(
      height: 1, indent: 16, endIndent: 16, color: AppColors.outline);
}

class _AboutTile extends StatelessWidget {
  const _AboutTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingText,
    this.danger = false,
    this.first = false,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? trailingText;
  final bool danger;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.primary;
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(first ? 20 : 0),
          bottom: Radius.circular(last ? 20 : 0),
        ),
      ),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: danger ? AppColors.danger : AppColors.navy,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText!,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13.5),
            ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary),
        ],
      ),
      onTap: onTap,
    );
  }
}
