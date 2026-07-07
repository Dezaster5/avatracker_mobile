import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
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

/// Вход: номер телефона + пароль. Регистрация и сброс пароля — по ссылкам.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Экран пересоздаётся при каждом переходе на /login (в т.ч. после
    // логаута) — но loginControllerProvider не autoDispose, поэтому старая
    // ошибка предыдущей попытки/сессии иначе осталась бы висеть на баннере.
    Future.microtask(
      () => ref.read(loginControllerProvider.notifier).clearError(),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final country = ref.read(selectedCountryProvider);
    await ref.read(loginControllerProvider.notifier).login(
          phone: e164For(_phoneController.text, country),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final login = ref.watch(loginControllerProvider);

    ref.listen<AuthSession>(authControllerProvider, (prev, next) {
      final message = next.message;
      if (message != null &&
          message != prev?.message &&
          next.status == AuthStatus.unauthenticated) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(context.localizedMessage(message))),
          );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              const SizedBox(height: 8),
              const LangCountryBar(),
              const SizedBox(height: 20),
              const Center(child: BrandLogo(height: 44)),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  l10n.appTagline,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 44),
              Text(
                l10n.loginWelcome,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.loginSubtitle,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 28),
              FieldLabel(l10n.fieldPhone),
              CountryPhoneField(
                controller: _phoneController,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 18),
              FieldLabel(l10n.fieldPassword),
              PasswordField(
                controller: _passwordController,
                hint: l10n.passwordHint,
                autofillHints: const [AutofillHints.password],
                validator: (value) => (value == null || value.isEmpty)
                    ? l10n.enterPassword
                    : null,
                onSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot'),
                  child: Text(l10n.forgotPassword),
                ),
              ),
              ErrorBanner(message: login.error),
              const SizedBox(height: 16),
              PrimaryButton(
                label: l10n.login,
                loading: login.submitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.outline)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      l10n.firstTimeHere,
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.outline)),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.push('/register'),
                child: Text(l10n.register),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/privacy'),
                  child: Text(l10n.privacyPolicy),
                ),
              ),
              Center(
                child: Text(
                  AppConfig.appVersion,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
