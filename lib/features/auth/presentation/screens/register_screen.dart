import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/country/phone_number.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_text_form_field.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../../core/widgets/password_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/l10n_ext.dart';
import '../../../preferences/presentation/controllers/preferences_controller.dart';
import '../../../preferences/presentation/widgets/lang_country_bar.dart';
import '../../domain/policies/password_policy.dart';
import '../controllers/registration_controller.dart';
import '../widgets/country_phone_field.dart';
import '../widgets/password_requirements.dart';

/// Регистрация: телефон + ИИН + пароль, подтверждение SMS-кодом.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _iinController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _consent = false;

  @override
  void initState() {
    super.initState();
    // Сбрасываем ошибку прошлой попытки регистрации (registrationControllerProvider
    // не autoDispose и переживает возврат на этот экран/новую сессию).
    Future.microtask(
      () => ref.read(registrationControllerProvider.notifier).clearError(),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _iinController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final registration = ref.read(registrationControllerProvider);
    if (!_consent ||
        registration.sending ||
        registration.failure is RegistrationConflictFailure) {
      return;
    }
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final country = ref.read(selectedCountryProvider);
    final ok = await ref.read(registrationControllerProvider.notifier).sendCode(
          phone: PhoneNumber.parse(_phoneController.text, country),
          iin: _iinController.text.trim(),
          password: _passwordController.text,
        );
    if (ok && mounted && ModalRoute.of(context)?.isCurrent == true) {
      context.push('/sms-register');
    }
  }

  /// Ошибка сервера относится к прошлой отправке: правка полей её убирает,
  /// как и на экране SMS-кода.
  void _clearError() {
    if (ref.read(registrationControllerProvider).failure != null) {
      ref.read(registrationControllerProvider.notifier).clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final registration = ref.watch(registrationControllerProvider);
    final alreadyRegistered =
        registration.failure is RegistrationConflictFailure;
    final country = ref.watch(selectedCountryProvider);
    final isUzbekistan = country.isUzbekistan;

    ref.listen(selectedCountryProvider, (previous, next) {
      if (previous?.isoCode != next.isoCode) _iinController.clear();
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(l10n.registerTitle),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: AutofillGroup(
          onDisposeAction: AutofillContextAction.cancel,
          child: Form(
            key: _formKey,
            onChanged: _clearError,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              children: [
                const SizedBox(height: 4),
                const LangCountryBar(),
                const SizedBox(height: 12),
                Text(
                  l10n.createAccount,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 18),
                FieldLabel(l10n.fieldPhone),
                CountryPhoneField(
                  controller: _phoneController,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [
                    AutofillHints.username,
                    AutofillHints.telephoneNumber,
                  ],
                ),
                const SizedBox(height: 14),
                FieldLabel(
                  isUzbekistan ? l10n.fieldPinfl : l10n.fieldIin,
                ),
                AppTextFormField(
                  controller: _iinController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(country.personalIdLength),
                  ],
                  decoration: InputDecoration(
                    hintText: isUzbekistan ? l10n.pinflHint : l10n.iinHint,
                    prefixIcon: const Icon(Icons.badge_outlined, size: 22),
                  ),
                  validator: (value) =>
                      country.isValidPersonalId((value ?? '').trim())
                          ? null
                          : isUzbekistan
                              ? l10n.validatorPinfl
                              : l10n.validatorIin,
                ),
                const SizedBox(height: 14),
                FieldLabel(l10n.fieldPassword),
                PasswordField(
                  controller: _passwordController,
                  hint: l10n.passwordHint,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (value) => PasswordPolicy.isValid(value ?? '')
                      ? null
                      : l10n.validatorPassword,
                ),
                PasswordRequirements(
                  password: _passwordController,
                  confirmation: _confirmController,
                  compact: true,
                ),
                const SizedBox(height: 18),
                FieldLabel(l10n.confirmPassword),
                PasswordField(
                  controller: _confirmController,
                  hint: l10n.repeatPassword,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (value) => value == _passwordController.text
                      ? null
                      : l10n.validatorPasswordsMatch,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 20),
                _ConsentCheckbox(
                  value: _consent,
                  onChanged: (v) => setState(() => _consent = v),
                  onPolicyTap: () => context.push('/privacy'),
                ),
                ErrorBanner(failure: registration.failure),
                if (!alreadyRegistered) ...[
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: l10n.continueRegistration,
                    loading: registration.sending,
                    onPressed: _consent ? _submit : null,
                  ),
                ],
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/login');
                      }
                    },
                    child: Text(
                      alreadyRegistered ? l10n.login : l10n.haveAccount,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Чекбокс согласия на обработку ПДн со ссылкой на Политику.
class _ConsentCheckbox extends StatefulWidget {
  const _ConsentCheckbox({
    required this.value,
    required this.onChanged,
    required this.onPolicyTap,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onPolicyTap;

  @override
  State<_ConsentCheckbox> createState() => _ConsentCheckboxState();
}

class _ConsentCheckboxState extends State<_ConsentCheckbox> {
  late final _policyTap = TapGestureRecognizer()
    ..onTap = () => widget.onPolicyTap();

  @override
  void dispose() {
    _policyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const linkPlaceholder = '\uFFFC';
    final parts = l10n.consentCheckbox(linkPlaceholder).split(linkPlaceholder);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: widget.value,
            onChanged: (v) => widget.onChanged(v ?? false),
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => widget.onChanged(!widget.value),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: parts.first),
                  TextSpan(
                    text: l10n.consentPolicy,
                    recognizer: _policyTap,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: parts.last),
                ],
              ),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
