import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/country/country_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/password_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../l10n/l10n_ext.dart';
import '../providers.dart';
import 'widgets/country_phone_field.dart';
import 'widgets/lang_country_bar.dart';

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
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final country = ref.read(selectedCountryProvider);
    final ok = await ref.read(registrationControllerProvider.notifier).sendCode(
          phone: e164For(_phoneController.text, country),
          iin: _iinController.text.trim(),
          password: _passwordController.text,
        );
    if (ok && mounted) context.push('/sms-register');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final registration = ref.watch(registrationControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(l10n.registerTitle),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
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
              const SizedBox(height: 6),
              Text(
                l10n.registerSubtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              FieldLabel(l10n.fieldPhone),
              CountryPhoneField(
                controller: _phoneController,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 18),
              FieldLabel(l10n.fieldIin),
              TextFormField(
                controller: _iinController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                decoration: InputDecoration(
                  hintText: l10n.iinHint,
                  prefixIcon: const Icon(Icons.badge_outlined, size: 22),
                ),
                validator: (value) =>
                    isValidIin((value ?? '').trim()) ? null : l10n.validatorIin,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.iinExplanation,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              FieldLabel(l10n.fieldPassword),
              PasswordField(
                controller: _passwordController,
                hint: l10n.passwordMinHint,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) => isValidPassword(value ?? '')
                    ? null
                    : l10n.validatorPassword,
              ),
              const SizedBox(height: 18),
              FieldLabel(l10n.confirmPassword),
              PasswordField(
                controller: _confirmController,
                hint: l10n.repeatPassword,
                validator: (value) => value == _passwordController.text
                    ? null
                    : l10n.validatorPasswordsMatch,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 18),
              _ConsentCheckbox(
                value: _consent,
                onChanged: (v) => setState(() => _consent = v),
                onPolicyTap: () => context.push('/privacy'),
              ),
              ErrorBanner(message: registration.error),
              const SizedBox(height: 20),
              PrimaryButton(
                label: l10n.getSmsCode,
                icon: Icons.sms_outlined,
                loading: registration.sending,
                onPressed: _consent ? _submit : null,
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text(l10n.haveAccount),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Чекбокс согласия на обработку ПДн со ссылкой на Политику.
class _ConsentCheckbox extends StatelessWidget {
  const _ConsentCheckbox({
    required this.value,
    required this.onChanged,
    required this.onPolicyTap,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onPolicyTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => onChanged(!value),
                child: Text(
                  l10n.consentCheckbox,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onPolicyTap,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 2),
                  child: Text(
                    l10n.privacyPolicy,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
