import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/country/country.dart';
import '../../../../core/country/country_providers.dart';
import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/l10n_ext.dart';
import '../../providers.dart';

/// Название языка в его же письменности (для списка выбора).
String languageName(BuildContext context, String code) => switch (code) {
      'kk' => context.l10n.languageKazakh,
      'uz' => context.l10n.languageUzbek,
      _ => context.l10n.languageRussian,
    };

String countryName(BuildContext context, Country country) =>
    switch (country.isoCode) {
      'KZ' => context.l10n.countryKazakhstan,
      'UZ' => context.l10n.countryUzbekistan,
      _ => country.name,
    };

/// Шторка выбора страны (флаг + название + код). Тап — выбор.
Future<void> showCountryPicker(BuildContext context, WidgetRef ref) async {
  final countries =
      ref.read(countriesProvider).asData?.value ?? Country.fallback;
  final current = ref.read(selectedCountryProvider);
  final selected = await showModalBottomSheet<Country>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          _SheetGrabber(),
          const SizedBox(height: 12),
          Text(
            sheetContext.l10n.chooseCountry,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          for (final c in countries)
            ListTile(
              leading: Text(c.flagEmoji, style: const TextStyle(fontSize: 26)),
              title: Text(
                countryName(sheetContext, c),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
              trailing: Text('${c.dialCode}   ',
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
              selected: c.isoCode == current.isoCode,
              onTap: () => Navigator.of(sheetContext).pop(c),
            ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
  if (selected != null) {
    ref.read(selectedCountryProvider.notifier).state = selected;
    await ref.read(tokenStorageProvider).saveCountryIso(selected.isoCode);
  }
}

/// Шторка выбора языка (радио + кнопка «Выбрать»).
Future<void> showLanguagePicker(BuildContext context, WidgetRef ref) async {
  final current = ref.read(localeProvider).languageCode;
  final selected = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _LanguageSheet(current: current),
  );
  if (selected != null && selected != current) {
    ref.read(localeProvider.notifier).state = Locale(selected);
    await ref.read(tokenStorageProvider).saveLocale(selected);
  }
}

/// Панель выбора страны и языка вверху экранов входа/регистрации.
class LangCountryBar extends ConsumerWidget {
  const LangCountryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final country = ref.watch(selectedCountryProvider);
    final localeCode = ref.watch(localeProvider).languageCode;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _BarButton(
          leading:
              Text(country.flagEmoji, style: const TextStyle(fontSize: 16)),
          label: countryName(context, country),
          onTap: () => showCountryPicker(context, ref),
        ),
        const SizedBox(width: 8),
        _BarButton(
          leading: const Icon(Icons.language_rounded,
              size: 16, color: AppColors.textSecondary),
          label: languageName(context, localeCode),
          onTap: () => showLanguagePicker(context, ref),
        ),
      ],
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.leading,
    required this.label,
    required this.onTap,
  });

  final Widget leading;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              leading,
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Icon(Icons.expand_more_rounded,
                  size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSheet extends StatefulWidget {
  const _LanguageSheet({required this.current});
  final String current;

  @override
  State<_LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<_LanguageSheet> {
  late String _selected = widget.current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.chooseLanguage,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final code in localeOrder)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _selected == code
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: _selected == code
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                title: Text(
                  languageName(context, code),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                onTap: () => setState(() => _selected = code),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_selected),
                child: Text(context.l10n.actionSelect),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetGrabber extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(2),
        ),
      );
}
