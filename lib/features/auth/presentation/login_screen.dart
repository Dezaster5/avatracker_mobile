import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/password_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers.dart';

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
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(loginControllerProvider.notifier).login(
          phone: normalizePhone(_phoneController.text),
          password: _passwordController.text,
        );
    // При успехе роутер сам откроет сканер (статус сессии изменится).
  }

  @override
  Widget build(BuildContext context) {
    final login = ref.watch(loginControllerProvider);

    // Причина выхода (сотрудник неактивен, сессия истекла и т.п.).
    ref.listen<AuthSession>(authControllerProvider, (prev, next) {
      final message = next.message;
      if (message != null &&
          message != prev?.message &&
          next.status == AuthStatus.unauthenticated) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(message)));
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
              const SizedBox(height: 36),
              const Center(child: BrandLogo(height: 44)),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Учет рабочего времени',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 44),
              const Text(
                'С возвращением!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Войдите по номеру телефона и паролю',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 28),
              const FieldLabel('Номер телефона'),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneInputFormatter()],
                autofillHints: const [AutofillHints.telephoneNumber],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: '+7 700 000 00 00',
                  prefixIcon: Icon(Icons.phone_iphone_rounded, size: 22),
                ),
                validator: (value) => isValidKzPhone(value ?? '')
                    ? null
                    : 'Введите номер в формате +7 XXX XXX XX XX',
                onChanged: (_) =>
                    ref.read(loginControllerProvider.notifier).clearError(),
              ),
              const SizedBox(height: 18),
              const FieldLabel('Пароль'),
              PasswordField(
                controller: _passwordController,
                hint: 'Введите пароль',
                autofillHints: const [AutofillHints.password],
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Введите пароль' : null,
                onSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot'),
                  child: const Text('Забыли пароль?'),
                ),
              ),
              ErrorBanner(message: login.error),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Войти',
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
                      'Впервые здесь?',
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
                child: const Text('Зарегистрироваться'),
              ),
              if (AppConfig.mockApi) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Text(
                    'Демо-режим: вход +7 700 123 45 67, пароль 123456.\n'
                    'SMS-код всегда 1234.',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
