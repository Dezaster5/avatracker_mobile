import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/password_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers.dart';

/// Сброс пароля, шаг 3 (после SMS-кода): новый пароль + подтверждение.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref
        .read(passwordResetControllerProvider.notifier)
        .setNewPassword(_passwordController.text);
    if (ok && mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Пароль изменен. Войдите с новым паролем'),
        ));
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final reset = ref.watch(passwordResetControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Новый пароль'),
        leading: BackButton(onPressed: () => context.go('/login')),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    size: 40,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Придумайте новый пароль',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Код подтвержден для номера\n${formatPhone(reset.phone)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const FieldLabel('Новый пароль'),
              PasswordField(
                controller: _passwordController,
                hint: 'Минимум 6 символов',
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) => isValidPassword(value ?? '')
                    ? null
                    : 'Пароль: минимум 6 символов, без пробелов',
              ),
              const SizedBox(height: 18),
              const FieldLabel('Подтвердите пароль'),
              PasswordField(
                controller: _confirmController,
                hint: 'Повторите пароль',
                validator: (value) => value == _passwordController.text
                    ? null
                    : 'Пароли не совпадают',
                onSubmitted: (_) => _submit(),
              ),
              ErrorBanner(message: reset.error),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Сохранить пароль',
                icon: Icons.check_rounded,
                loading: reset.saving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
