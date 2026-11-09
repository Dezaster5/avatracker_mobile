import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/country/country.dart';
import '../../../../core/country/phone_number.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/country_phone_input_formatter.dart';
import '../../../../l10n/l10n_ext.dart';
import '../../../preferences/presentation/controllers/preferences_controller.dart';
import '../../../preferences/presentation/widgets/lang_country_bar.dart';

/// Поле ввода телефона с выбором страны (флаг + код). Формат номера и
/// валидация зависят от выбранной страны (KZ 10 цифр, UZ 9 цифр).
class CountryPhoneField extends ConsumerStatefulWidget {
  const CountryPhoneField({
    super.key,
    required this.controller,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints = const [AutofillHints.telephoneNumber],
  });

  final TextEditingController controller;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  ConsumerState<CountryPhoneField> createState() => _CountryPhoneFieldState();
}

class _CountryPhoneFieldState extends ConsumerState<CountryPhoneField> {
  @override
  Widget build(BuildContext context) {
    final country = ref.watch(selectedCountryProvider);

    // Номер одной страны нельзя незаметно использовать с кодом другой.
    ref.listen<Country>(selectedCountryProvider, (prev, next) {
      if (prev?.isoCode != next.isoCode) widget.controller.clear();
    });

    return TextFormField(
      controller: widget.controller,
      autofocus: widget.autofocus,
      keyboardType: TextInputType.phone,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      inputFormatters: [CountryPhoneInputFormatter(country)],
      decoration: InputDecoration(
        hintText: country.phoneHint,
        prefixIcon: InkWell(
          onTap: () => showCountryPicker(context, ref),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(country.flagEmoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(
                  country.dialCode,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded,
                    color: AppColors.textSecondary),
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.only(left: 4),
                  color: AppColors.outline,
                ),
              ],
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
      onFieldSubmitted: widget.onSubmitted,
      validator: (value) => PhoneNumber.parse(value ?? '', country).isValid
          ? null
          : context.l10n.validatorPhone,
    );
  }
}
