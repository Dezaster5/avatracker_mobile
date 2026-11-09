import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/country/phone_number.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../../core/widgets/password_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/l10n_ext.dart';
import '../../../preferences/presentation/controllers/preferences_controller.dart';
import '../../../preferences/presentation/widgets/lang_country_bar.dart';
import '../../domain/entities/session_restoration.dart';
import '../controllers/auth_controller.dart';
import '../controllers/login_controller.dart';
import '../logout_reason_l10n.dart';
import '../widgets/country_phone_field.dart';

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
    // Сессия обычно завершается до открытия этого экрана (истекла, доступ
    // отозван, аккаунт удалён) — тогда причину показываем после первого кадра.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _showLogoutReason(ref.read(authControllerProvider).logoutReason),
    );
  }

  void _showLogoutReason(LogoutReason? reason) {
    if (reason == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(context.l10n.logoutReasonMessage(reason))),
      );
    ref.read(authControllerProvider.notifier).acknowledgeLogoutReason();
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
    final ok = await ref.read(loginControllerProvider.notifier).login(
          phone: PhoneNumber.parse(_phoneController.text, country),
          password: _passwordController.text,
        );
    if (ok) TextInput.finishAutofillContext(shouldSave: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final login = ref.watch(loginControllerProvider);

    ref.listen<AuthSession>(authControllerProvider, (prev, next) {
      if (next.status == AuthStatus.unauthenticated &&
          next.logoutReason != prev?.logoutReason) {
        _showLogoutReason(next.logoutReason);
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AutofillGroup(
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
                  autofillHints: const [
                    AutofillHints.username,
                    AutofillHints.telephoneNumber,
                  ],
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
                ErrorBanner(failure: login.failure),
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
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
