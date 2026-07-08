import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/i18n/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n_ext.dart';
import '../../auth/presentation/widgets/lang_country_bar.dart';

/// Раздел «О приложении»: версия, язык, Политика, удаление, поддержка.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  void _showSupport(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 18, 12, 0),
        title: Row(
          children: [
            Expanded(child: Text(dialogContext.l10n.support)),
            IconButton(
              tooltip: dialogContext.l10n.actionClose,
              onPressed: () => Navigator.of(dialogContext).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText.rich(
              TextSpan(
                text: '${dialogContext.l10n.supportBody}\n',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
                children: const [
                  TextSpan(
                    text: AppConfig.supportEmail,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final uri = Uri(
                  scheme: 'mailto',
                  path: AppConfig.supportEmail,
                  queryParameters: const {'subject': 'AvaTracker'},
                );
                final opened = await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
                if (!opened) {
                  await Clipboard.setData(
                    const ClipboardData(text: AppConfig.supportEmail),
                  );
                }
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              icon: const Icon(Icons.mail_outline_rounded),
              label: Text(dialogContext.l10n.writeEmail),
            ),
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
                    trailingText: languageName(context, localeCode),
                    onTap: () => showLanguagePicker(context, ref),
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
